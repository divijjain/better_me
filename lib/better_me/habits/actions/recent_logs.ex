defmodule BetterMe.Habits.Actions.RecentLogs do
  alias BetterMe.Habits.Repository

  def run(habit_id, user_id, days \\ 30) do
    with {:ok, habit} <- Repository.get_habit(habit_id, user_id) do
      since = Date.add(Date.utc_today(), -days)
      {:ok, Repository.list_recent_logs(habit.id, since)}
    end
  end
end
