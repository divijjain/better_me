defmodule BetterMe.Habits do
  alias BetterMe.Habits.Repository

  alias BetterMe.Habits.Actions.{
    CurrentStreak,
    HabitStats,
    ListWithMeta,
    LoggedToday,
    LogHabit,
    RecentLogs
  }

  defdelegate list_habits(user_id, opts \\ []), to: Repository
  defdelegate list_habits_with_meta(user_id), to: ListWithMeta, as: :run
  defdelegate get_habit(id, user_id), to: Repository
  defdelegate get_habit!(id, user_id), to: Repository
  defdelegate new_habit(), to: Repository
  defdelegate create_habit(user_id, attrs), to: Repository
  defdelegate update_habit(habit, attrs), to: Repository
  defdelegate delete_habit(habit), to: Repository
  defdelegate change_habit(habit, attrs \\ %{}), to: Repository
  defdelegate log_habit(habit_id, attrs), to: LogHabit, as: :run
  defdelegate current_streak(habit_id, user_id), to: CurrentStreak, as: :run
  defdelegate recent_logs(habit_id, user_id, days \\ 30), to: RecentLogs, as: :run
  defdelegate logged_today?(habit_id, user_id), to: LoggedToday, as: :run
  defdelegate habit_stats(habit_id, user_id), to: HabitStats, as: :run
  defdelegate habit_completion_rates(user_id, days \\ 30), to: Repository, as: :completion_rates
end
