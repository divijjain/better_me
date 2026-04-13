defmodule BetterMe.Health.Actions.LogMetric do
  @moduledoc """
  Logs a body metric entry for a user and broadcasts a PubSub event so that
  Phoenix Channels (and future LiveViews) can push real-time updates.
  """

  alias BetterMe.Health.Repository

  def run(user_id, attrs) do
    case Repository.log_metric(user_id, attrs) do
      {:ok, metric} = ok ->
        Phoenix.PubSub.broadcast(
          BetterMe.PubSub,
          "user:#{user_id}:health",
          {:metric_logged, metric}
        )

        ok

      error ->
        error
    end
  end
end
