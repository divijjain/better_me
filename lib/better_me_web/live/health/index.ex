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
    <div class="max-w-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Body Metrics</h1>
        <.link
          navigate={~p"/health/new"}
          class="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> Log
        </.link>
      </div>

      <div :if={@metrics == []} class="text-center py-16 text-gray-400">
        No entries yet. Log your first measurement!
      </div>

      <ul class="space-y-2">
        <li
          :for={metric <- @metrics}
          class="flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm"
        >
          <div>
            <p class="text-sm font-semibold text-gray-900">
              {Calendar.strftime(metric.date, "%b %-d, %Y")}
            </p>
            <p class="text-xs text-gray-400 mt-0.5">
              <%= if metric.weight, do: "#{metric.weight} kg" %>
              <%= if metric.weight && metric.body_fat_pct, do: " · " %>
              <%= if metric.body_fat_pct, do: "#{metric.body_fat_pct}% body fat" %>
            </p>
          </div>
          <.link
            navigate={~p"/health/#{metric.id}/edit"}
            class="text-gray-400 hover:text-gray-600"
          >
            <.icon name="hero-pencil-square" class="h-4 w-4" />
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
