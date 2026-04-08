defmodule BetterMe.Embeddings.Jobs.EmbedJob do
  @moduledoc """
  Oban worker that embeds a single source record into pgvector.

  Args:
    - user_id:     integer
    - source_type: "journal_entry" | "meal_log" | "workout"
    - source_id:   integer

  On success: upserts into the embeddings table.
  On failure: retried up to 3 times with exponential backoff.
  If the source record no longer exists (deleted): job is discarded cleanly.
  """

  use Oban.Worker, queue: :embeddings, max_attempts: 3

  alias BetterMe.{Embeddings, Journals, Nutrition, Workouts}
  alias BetterMe.OpenAI.Embeddings, as: EmbeddingsAPI

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"user_id" => user_id, "source_type" => source_type, "source_id" => source_id}
      }) do
    case fetch_content(source_type, source_id, user_id) do
      {:ok, content} ->
        case EmbeddingsAPI.embed(content) do
          {:ok, vector} ->
            Embeddings.upsert(user_id, source_type, source_id, content, vector)
            :ok

          {:error, :missing_api_key} ->
            # Don't retry if key isn't configured — discard cleanly
            {:discard, "OPENAI_API_KEY not set"}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        # Source was deleted — no point retrying
        {:discard, "#{source_type} #{source_id} not found"}
    end
  end

  @doc """
  Enqueue an embed job for a source record.
  """
  def enqueue(user_id, source_type, source_id) do
    %{user_id: user_id, source_type: source_type, source_id: source_id}
    |> new()
    |> Oban.insert()
  end

  # --- Content builders ---

  defp fetch_content("journal_entry", source_id, user_id) do
    case Journals.get_entry(source_id, user_id) do
      {:ok, entry} ->
        parts = ["Date: #{entry.date}", "Mood: #{entry.mood || "not set"}", entry.body]

        parts =
          if entry.tags != [], do: parts ++ ["Tags: #{Enum.join(entry.tags, ", ")}"], else: parts

        {:ok, Enum.join(parts, "\n")}

      error ->
        error
    end
  end

  defp fetch_content("meal_log", source_id, user_id) do
    case Nutrition.get_meal_log_with_recipe(source_id, user_id) do
      {:ok, log} ->
        content =
          "Date: #{log.date}\nMeal: #{log.meal_type}\nRecipe: #{log.recipe.title}\nServings: #{log.servings}"

        {:ok, content}

      error ->
        error
    end
  end

  defp fetch_content("workout", source_id, user_id) do
    case Workouts.get_workout(source_id, user_id) do
      {:ok, workout} ->
        parts = [
          "Date: #{workout.date}",
          "Type: #{workout.workout_type}",
          "Duration: #{workout.duration_minutes} min"
        ]

        parts = if workout.notes, do: parts ++ ["Notes: #{workout.notes}"], else: parts
        {:ok, Enum.join(parts, "\n")}

      error ->
        error
    end
  end
end
