defmodule BetterMeWeb.Api.WorkoutsController do
  @moduledoc "JSON API for workouts, exercises, and exercise sets."

  use BetterMeWeb, :controller
  alias BetterMe.Workouts

  def index(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    limit = params |> Map.get("limit", "50") |> String.to_integer()
    workouts = Workouts.list_workouts(user_id, limit: limit)
    json(conn, %{data: Enum.map(workouts, &serialize_workout/1)})
  end

  def create(conn, %{"workout" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    case Workouts.create_workout(user_id, attrs) do
      {:ok, workout} ->
        conn |> put_status(:created) |> json(%{data: serialize_workout(workout)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def add_exercise(conn, %{"workout_id" => workout_id} = params) do
    user_id = conn.assigns.current_scope.user.id
    attrs = Map.drop(params, ["workout_id"])

    case Workouts.add_exercise(user_id, workout_id, attrs) do
      {:ok, exercise, _pr_flag} ->
        conn |> put_status(:created) |> json(%{data: serialize_exercise(exercise)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def log_set(conn, %{"workout_id" => workout_id, "exercise_id" => exercise_id} = params) do
    user_id = conn.assigns.current_scope.user.id
    attrs = Map.drop(params, ["workout_id", "exercise_id"])

    with {:ok, exercise} <- Workouts.get_exercise(exercise_id, workout_id),
         {:ok, set, pr_flag} <- Workouts.log_set(user_id, exercise, attrs) do
      conn |> put_status(:created) |> json(%{data: %{id: set.id, pr: pr_flag == :pr}})
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{errors: %{detail: "Exercise not found"}})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  defp serialize_workout(workout) do
    %{
      id: workout.id,
      date: workout.date,
      type: workout.type,
      duration: workout.duration,
      notes: workout.notes
    }
  end

  defp serialize_exercise(exercise) do
    %{
      id: exercise.id,
      name: exercise.name,
      sets: exercise.sets,
      reps: exercise.reps,
      weight: exercise.weight,
      rpe: exercise.rpe,
      is_pr: exercise.is_pr,
      workout_id: exercise.workout_id
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
