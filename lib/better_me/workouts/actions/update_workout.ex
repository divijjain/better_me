defmodule BetterMe.Workouts.Actions.UpdateWorkout do
  alias BetterMe.Embeddings.Jobs.EmbedJob
  alias BetterMe.Workouts.Repository

  def run(workout, attrs) do
    case Repository.update_workout(workout, attrs) do
      {:ok, updated} = result ->
        EmbedJob.enqueue(updated.user_id, "workout", updated.id)
        result

      error ->
        error
    end
  end
end
