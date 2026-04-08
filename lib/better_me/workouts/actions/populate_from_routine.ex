defmodule BetterMe.Workouts.Actions.PopulateFromRoutine do
  alias BetterMe.Workouts.Repository

  # Given a workout and a routine_day_id, inserts one Exercise row per
  # routine_exercise in that day (no sets — those are logged during the session).
  # Returns :ok | {:error, reason}
  def run(workout, day_id) do
    case Repository.get_routine_day_with_exercises(day_id) do
      {:ok, day} ->
        day.routine_exercises
        |> Enum.with_index(1)
        |> Enum.each(fn {re, _idx} ->
          Repository.add_exercise(workout.id, %{
            "name" => re.name,
            "sets" => re.working_sets,
            "reps" => nil,
            "weight" => nil
          })
        end)

        {:ok, :populated}

      {:error, _} ->
        {:error, :routine_day_not_found}
    end
  end
end
