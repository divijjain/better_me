defmodule BetterMeWeb.HealthLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Health

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    today = Date.utc_today()

    {:ok,
     assign(socket,
       metrics: Health.list_metrics(user_id),
       today_activity: Health.activity_for_date(user_id, today),
       user_id: user_id
     )}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  defp format_steps(n) when n >= 1000 do
    thousands = div(n, 1000)
    hundreds = rem(n, 1000)
    "#{thousands},#{String.pad_leading(to_string(hundreds), 3, "0")}"
  end

  defp format_steps(n), do: to_string(n)

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Body Metrics" new_path={~p"/health/new"} new_label="Log" />

      <%!-- Today's activity summary --%>
      <div :if={@today_activity} class="mb-6 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-semibold uppercase tracking-wide text-gray-400 mb-3">
          Today's Activity
        </p>
        <div class="flex flex-wrap gap-4">
          <div :if={@today_activity.steps} class="flex flex-col items-center gap-0.5">
            <span class="text-lg">👟</span>
            <span class="text-base font-bold text-gray-900">
              {format_steps(@today_activity.steps)}
            </span>
            <span class="text-xs text-gray-400">steps</span>
          </div>
          <div :if={@today_activity.active_kcal} class="flex flex-col items-center gap-0.5">
            <span class="text-lg">🔥</span>
            <span class="text-base font-bold text-gray-900">
              {round(@today_activity.active_kcal)}
            </span>
            <span class="text-xs text-gray-400">kcal</span>
          </div>
          <div :if={@today_activity.resting_hr_bpm} class="flex flex-col items-center gap-0.5">
            <span class="text-lg">❤️</span>
            <span class="text-base font-bold text-gray-900">
              {@today_activity.resting_hr_bpm}
            </span>
            <span class="text-xs text-gray-400">bpm</span>
          </div>
          <div :if={@today_activity.sleep_minutes} class="flex flex-col items-center gap-0.5">
            <span class="text-lg">🌙</span>
            <span class="text-base font-bold text-gray-900">
              {:erlang.float_to_binary(@today_activity.sleep_minutes / 60, decimals: 1)}
            </span>
            <span class="text-xs text-gray-400">hrs sleep</span>
          </div>
        </div>
      </div>

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
