defmodule BetterMe.Habits.Actions.ListWithMeta do
  alias BetterMe.Habits.Repository
  alias BetterMe.Habits.Streak

  def run(user_id) do
    habits = Repository.list_habits(user_id)
    habit_ids = Enum.map(habits, & &1.id)

    streak_map = Repository.streak_map_for(habit_ids)
    logged_set = Repository.logged_today_set_for(habit_ids)

    Enum.map(habits, fn habit ->
      habit
      |> Map.put(:streak, Map.get(streak_map, habit.id, []) |> Streak.calculate())
      |> Map.put(:logged_today, MapSet.member?(logged_set, habit.id))
    end)
  end
end
