defmodule BetterMe.Health.Actions.LogActivity do
  @moduledoc """
  Logs an activity entry for a user and broadcasts a PubSub event so that
  Phoenix Channels can push real-time updates to the mobile client.
  """

  alias BetterMe.Health.Repository

  def run(user_id, attrs) do
    case Repository.log_activity(user_id, attrs) do
      {:ok, log} = ok ->
        Phoenix.PubSub.broadcast(
          BetterMe.PubSub,
          "user:#{user_id}:health",
          {:activity_logged, log}
        )

        ok

      error ->
        error
    end
  end
end
