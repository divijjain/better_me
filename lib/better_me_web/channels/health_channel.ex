defmodule BetterMeWeb.HealthChannel do
  @moduledoc """
  Real-time health metric push for the Expo app.

  Topic: "health:<user_id>"

  This channel is push-only from the server — no client → server events.
  When a body metric is logged via the REST API (e.g. from HealthKit sync),
  Health.Actions.LogMetric broadcasts on the PubSub topic and this channel
  forwards the update to the connected mobile client.

  Server → Client:
    "metric_logged"  %{metric: %{id, date, weight, body_fat_pct}}
  """

  use Phoenix.Channel

  @impl true
  def join("health:" <> user_id_str, _params, socket) do
    if socket.assigns.current_user.id == String.to_integer(user_id_str) do
      :ok = Phoenix.PubSub.subscribe(BetterMe.PubSub, "user:#{user_id_str}:health")
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Receive PubSub broadcast from LogMetric action and push to mobile client
  @impl true
  def handle_info({:metric_logged, metric}, socket) do
    push(socket, "metric_logged", %{
      metric: %{
        id: metric.id,
        date: metric.date,
        weight: metric.weight,
        body_fat_pct: metric.body_fat_pct
      }
    })

    {:noreply, socket}
  end
end
