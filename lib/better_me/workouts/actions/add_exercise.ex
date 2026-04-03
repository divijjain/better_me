defmodule BetterMe.Workouts.Actions.AddExercise do
  alias BetterMe.Workouts.Repository

  # Adds an exercise to a workout. PR detection now happens per-set via LogSet.
  # Returns {:ok, exercise, :no_pr} for backwards-compatible callers.
  def run(_user_id, workout_id, attrs) do
    with {:ok, exercise} <- Repository.add_exercise(workout_id, attrs) do
      {:ok, exercise, :no_pr}
    end
  end
end
