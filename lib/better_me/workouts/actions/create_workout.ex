defmodule BetterMe.Workouts.Actions.CreateWorkout do
  alias BetterMe.Embeddings.Jobs.EmbedJob
  alias BetterMe.Workouts.Repository

  def run(user_id, attrs) do
    case Repository.create_workout(user_id, attrs) do
      {:ok, workout} = result ->
        EmbedJob.enqueue(user_id, "workout", workout.id)
        result

      error ->
        error
    end
  end
end
