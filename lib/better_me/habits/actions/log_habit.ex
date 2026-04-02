defmodule BetterMe.Habits.Actions.LogHabit do
  alias BetterMe.Habits.Repository

  @doc """
  Logs a habit completion for a given date. Enforces one log per habit per day
  via a unique constraint. Defaults date to today if not provided.
  """
  def run(habit_id, attrs) do
    attrs = Map.put_new(attrs, :date, Date.utc_today())
    Repository.insert_log(habit_id, attrs)
  end
end
