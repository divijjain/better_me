defmodule BetterMe.Habits.Actions.HabitStats do
  @moduledoc """
  Loads all stats for a single habit detail page:
  - current streak
  - longest streak ever
  - completed dates for the last 30 days (calendar)
  """

  alias BetterMe.Habits.Repository
  alias BetterMe.Habits.Streak

  def run(habit_id, user_id) do
    with {:ok, habit} <- Repository.get_habit(habit_id, user_id) do
      all_dates = Repository.get_log_dates(habit.id)
      since = Date.add(Date.utc_today(), -29)
      recent_dates = Repository.get_log_dates_since(habit.id, since)

      {:ok,
       %{
         habit: habit,
         current_streak: Streak.calculate(all_dates),
         longest_streak: Streak.longest(all_dates),
         calendar_dates: MapSet.new(recent_dates)
       }}
    end
  end
end
