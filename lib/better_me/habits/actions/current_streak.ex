defmodule BetterMe.Habits.Actions.CurrentStreak do
  alias BetterMe.Habits.Repository
  alias BetterMe.Habits.Streak

  def run(habit_id, user_id) do
    with {:ok, habit} <- Repository.get_habit(habit_id, user_id) do
      {:ok, habit |> then(& &1.id) |> Repository.get_log_dates() |> Streak.calculate()}
    end
  end
end
