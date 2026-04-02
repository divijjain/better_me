defmodule BetterMe.Habits.Actions.LoggedToday do
  alias BetterMe.Habits.Repository

  def run(habit_id, user_id) do
    with {:ok, habit} <- Repository.get_habit(habit_id, user_id) do
      {:ok, Repository.exists_log_today?(habit.id)}
    end
  end
end
