defmodule BetterMeWeb.HealthLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Health

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, assign(socket, metrics: Health.list_metrics(user_id), user_id: user_id)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Body Metrics" new_path={~p"/health/new"} new_label="Log" />

      <.empty_state :if={@metrics == []} message="No entries yet. Log your first measurement!" />

      <ul class="space-y-2">
        <li
          :for={metric <- @metrics}
          :key={metric.id}
          class="flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm"
        >
          <div>
            <p class="text-sm font-semibold text-gray-900">
              {Calendar.strftime(metric.date, "%b %-d, %Y")}
            </p>
            <p class="text-xs text-gray-400 mt-0.5">
              {if metric.weight, do: "#{metric.weight} kg"}
              {if metric.weight && metric.body_fat_pct, do: " · "}
              {if metric.body_fat_pct, do: "#{metric.body_fat_pct}% body fat"}
            </p>
          </div>
          <.edit_link path={~p"/health/#{metric.id}/edit"} />
        </li>
      </ul>
    </.page_container>
    """
  end
end
