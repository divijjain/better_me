defmodule BetterMe.Habits.Actions.LogHabit do
  alias BetterMe.Habits.Repository

  @doc """
  Logs a habit completion for a given date. Enforces one log per habit per day
  via a unique constraint. Defaults date to today if not provided.

  Broadcasts `{:habit_logged, habit_id}` on `"user:{user_id}:habits"` PubSub topic
  so that Phoenix Channels and LiveViews can push real-time updates to subscribed clients.
  """
  def run(user_id, habit_id, attrs) do
    attrs = Map.put_new(attrs, :date, Date.utc_today())

    case Repository.insert_log(habit_id, attrs) do
      {:ok, _log} = ok ->
        Phoenix.PubSub.broadcast(
          BetterMe.PubSub,
          "user:#{user_id}:habits",
          {:habit_logged, habit_id}
        )

        ok

      error ->
        error
    end
  end
end
