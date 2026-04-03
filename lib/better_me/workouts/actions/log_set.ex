defmodule BetterMe.Workouts.Actions.LogSet do
  alias BetterMe.Workouts.Actions.DetectPR
  alias BetterMe.Workouts.Repository

  # Logs a set for an exercise and runs PR detection when weight is present.
  # Returns {:ok, set, :pr | :no_pr}
  def run(user_id, exercise, attrs) do
    set_number = Repository.next_set_number(exercise.id)

    with {:ok, set} <-
           Repository.add_exercise_set(exercise.id, Map.put(attrs, "set_number", set_number)) do
      case DetectPR.run(user_id, exercise, set) do
        {:pr, _exercise, set} -> {:ok, set, :pr}
        {:no_pr, _exercise, set} -> {:ok, set, :no_pr}
      end
    end
  end
end
