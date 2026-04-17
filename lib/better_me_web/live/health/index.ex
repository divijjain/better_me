defmodule BetterMeWeb.HealthLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Health

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:ok,
     assign(socket,
       metrics: Health.list_metrics(user_id),
       activity_logs: Health.list_activity(user_id),
       user_id: user_id,
       tab: :body
     )}
  end

  def handle_params(%{"tab" => "activity"}, _url, socket),
    do: {:noreply, assign(socket, tab: :activity)}

  def handle_params(_params, _url, socket),
    do: {:noreply, assign(socket, tab: :body)}

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Health" new_path={if @tab == :body, do: ~p"/health/new"} new_label="Log" />

      <%!-- Subtabs --%>
      <div class="flex gap-1 mb-6 border-b border-gray-200">
        <.tab_link label="Body Metrics" href={~p"/health"} active={@tab == :body} />
        <.tab_link label="Activity" href={~p"/health?tab=activity"} active={@tab == :activity} />
      </div>

      <%!-- Body Metrics tab --%>
      <div :if={@tab == :body}>
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
      </div>

      <%!-- Activity tab --%>
      <div :if={@tab == :activity}>
        <.empty_state
          :if={@activity_logs == []}
          message="No activity data yet. Sync from the mobile app to populate."
        />
        <ul class="space-y-2">
          <li
            :for={log <- @activity_logs}
            :key={log.id}
            class="rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm"
          >
            <p class="text-sm font-semibold text-gray-900 mb-2">
              {Calendar.strftime(log.date, "%b %-d, %Y")}
            </p>
            <div class="flex flex-wrap gap-4">
              <div :if={log.steps} class="flex items-center gap-1.5">
                <span class="text-base">👟</span>
                <span class="text-sm font-semibold text-gray-800">{format_steps(log.steps)}</span>
                <span class="text-xs text-gray-400">steps</span>
              </div>
              <div :if={log.active_kcal} class="flex items-center gap-1.5">
                <span class="text-base">🔥</span>
                <span class="text-sm font-semibold text-gray-800">{round(log.active_kcal)}</span>
                <span class="text-xs text-gray-400">kcal</span>
              </div>
              <div :if={log.resting_hr_bpm} class="flex items-center gap-1.5">
                <span class="text-base">❤️</span>
                <span class="text-sm font-semibold text-gray-800">{log.resting_hr_bpm}</span>
                <span class="text-xs text-gray-400">bpm</span>
              </div>
              <div :if={log.sleep_minutes} class="flex items-center gap-1.5">
                <span class="text-base">🌙</span>
                <span class="text-sm font-semibold text-gray-800">
                  {:erlang.float_to_binary(log.sleep_minutes / 60, decimals: 1)}
                </span>
                <span class="text-xs text-gray-400">hrs sleep</span>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </.page_container>
    """
  end

  # --- Components ---

  attr :label, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, default: false

  defp tab_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors",
        if(@active,
          do: "border-teal-500 text-teal-600",
          else: "border-transparent text-gray-500 hover:text-gray-700"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end

  # --- Helpers ---

  defp format_steps(n) when n >= 1000 do
    thousands = div(n, 1000)
    hundreds = rem(n, 1000)
    "#{thousands},#{String.pad_leading(to_string(hundreds), 3, "0")}"
  end

  defp format_steps(n), do: to_string(n)
end
