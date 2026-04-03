defmodule BetterMe.Workouts.Actions.DetectPR do
  alias BetterMe.Workouts.Repository

  # Checks if a logged set is a PR for this exercise name scoped to the user.
  # Returns {:pr, set} or {:no_pr, set}.
  def run(user_id, exercise, set) do
    with true <- is_number(set.weight) and set.weight > 0,
         previous <- Repository.previous_best(user_id, exercise.name, exercise.workout_id),
         true <- new_pr?(set.weight, previous),
         {:ok, set} <- Repository.mark_set_as_pr(set),
         {:ok, exercise} <- Repository.mark_as_pr(exercise) do
      {:pr, exercise, set}
    else
      _ -> {:no_pr, exercise, set}
    end
  end

  defp new_pr?(_weight, nil), do: true
  defp new_pr?(weight, previous), do: weight > previous
end
