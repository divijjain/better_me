defmodule BetterMe.Workouts.Actions.LogSet do
  alias BetterMe.Workouts.Actions.DetectPR
  alias BetterMe.Workouts.Repository

  # Logs a set for an exercise and runs PR detection when weight is present.
  # Returns {:ok, set, :pr | :no_pr}
  def run(user_id, exercise, attrs) do
    set_number = Repository.next_set_number(exercise.id)

    with {:ok, set} <-
           Repository.add_exercise_set(exercise.id, Map.put(attrs, "set_number", set_number)) do
      {result, _exercise, set} = DetectPR.run(user_id, exercise, set)
      pr_flag = if result == :pr, do: :pr, else: :no_pr

      Phoenix.PubSub.broadcast(
        BetterMe.PubSub,
        "workout:#{exercise.workout_id}",
        {:set_logged, set, pr_flag}
      )

      {:ok, set, pr_flag}
    end
  end
end
