defmodule BetterMeWeb.HealthLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Health

  @presets %{
    "7" => 7,
    "30" => 30,
    "90" => 90
  }

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:ok,
     assign(socket,
       metrics: Health.list_metrics(user_id),
       activity_logs: Health.list_activity(user_id),
       user_id: user_id,
       tab: :body,
       preset: "30",
       date_from: date_str(Date.add(Date.utc_today(), -30)),
       date_to: date_str(Date.utc_today()),
       expanded_id: nil
     )}
  end

  def handle_params(params, _url, socket) do
    tab = if params["tab"] == "activity", do: :activity, else: :body
    preset = Map.get(params, "preset", "30")
    {date_from, date_to} = resolve_dates(preset, params["from"], params["to"])

    activity_logs =
      Health.list_activity(socket.assigns.user_id,
        date_from: date_from,
        date_to: date_to,
        limit: 365
      )

    {:noreply,
     assign(socket,
       tab: tab,
       preset: preset,
       date_from: date_str(date_from),
       date_to: date_str(date_to),
       activity_logs: activity_logs,
       expanded_id: nil
     )}
  end

  def handle_event("toggle_expand", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded = if socket.assigns.expanded_id == id, do: nil, else: id
    {:noreply, assign(socket, expanded_id: expanded)}
  end

  def handle_event("apply_dates", %{"from" => from, "to" => to}, socket) do
    params = build_params(socket.assigns.tab, "custom", from, to)
    {:noreply, push_patch(socket, to: ~p"/health?#{params}")}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Health" new_path={if @tab == :body, do: ~p"/health/new"} new_label="Log" />

      <%!-- Subtabs --%>
      <div class="flex gap-1 mb-6 border-b border-gray-200">
        <.tab_link label="Body Metrics" href={~p"/health"} active={@tab == :body} />
        <.tab_link label="Activity" href={~p"/health?tab=activity&preset=#{@preset}&from=#{@date_from}&to=#{@date_to}"} active={@tab == :activity} />
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
        <%!-- Preset buttons --%>
        <div class="flex items-center gap-2 mb-4 flex-wrap">
          <span class="text-xs text-gray-500 font-medium">Quick:</span>
          <.preset_btn label="7 days" value="7" active={@preset == "7"} tab={@tab} date_from={@date_from} date_to={@date_to} />
          <.preset_btn label="30 days" value="30" active={@preset == "30"} tab={@tab} date_from={@date_from} date_to={@date_to} />
          <.preset_btn label="90 days" value="90" active={@preset == "90"} tab={@tab} date_from={@date_from} date_to={@date_to} />
        </div>

        <%!-- Custom date range --%>
        <form phx-submit="apply_dates" class="flex items-center gap-2 mb-6 flex-wrap">
          <input
            type="date"
            name="from"
            value={@date_from}
            class="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-teal-400"
          />
          <span class="text-xs text-gray-400">to</span>
          <input
            type="date"
            name="to"
            value={@date_to}
            class="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-teal-400"
          />
          <button
            type="submit"
            class="rounded-lg bg-teal-500 px-3 py-1.5 text-sm font-semibold text-white hover:bg-teal-600"
          >
            Apply
          </button>
        </form>

        <p class="text-xs text-gray-400 mb-3">{length(@activity_logs)} entries</p>

        <.empty_state
          :if={@activity_logs == []}
          message="No activity data for this period. Sync from the mobile app to populate."
        />

        <ul class="space-y-2">
          <li
            :for={log <- @activity_logs}
            :key={log.id}
            class="rounded-lg border border-gray-200 bg-white shadow-sm overflow-hidden"
          >
            <%!-- Collapsed row — always visible, click to expand --%>
            <button
              phx-click="toggle_expand"
              phx-value-id={log.id}
              class="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-50 transition-colors"
            >
              <div>
                <p class="text-sm font-semibold text-gray-900">
                  {Calendar.strftime(log.date, "%b %-d, %Y")}
                </p>
                <p class="text-xs text-gray-400 mt-0.5">
                  {summary_line(log)}
                </p>
              </div>
              <span class="text-gray-400 text-sm">
                {if @expanded_id == log.id, do: "▲", else: "▼"}
              </span>
            </button>

            <%!-- Expanded detail --%>
            <div :if={@expanded_id == log.id} class="border-t border-gray-100 px-4 py-4 bg-gray-50">
              <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
                <.metric_tile :if={log.steps} emoji="👟" label="Steps" value={format_steps(log.steps)} />
                <.metric_tile :if={log.active_kcal} emoji="🔥" label="Active kcal" value={"#{round(log.active_kcal)} kcal"} />
                <.metric_tile :if={log.resting_hr_bpm} emoji="❤️" label="Resting HR" value={"#{log.resting_hr_bpm} bpm"} />
                <.metric_tile :if={log.sleep_minutes} emoji="🌙" label="Sleep" value={"#{:erlang.float_to_binary(log.sleep_minutes / 60, decimals: 1)} hrs"} />
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

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :active, :boolean, required: true
  attr :tab, :atom, required: true
  attr :date_from, :string, required: true
  attr :date_to, :string, required: true

  defp preset_btn(assigns) do
    ~H"""
    <.link
      patch={~p"/health?#{build_params(@tab, @value, @date_from, @date_to)}"}
      class={[
        "px-3 py-1 rounded-full text-xs font-semibold border transition-colors",
        if(@active,
          do: "bg-teal-500 border-teal-500 text-white",
          else: "border-gray-300 text-gray-600 hover:border-teal-400 hover:text-teal-600"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end

  attr :emoji, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp metric_tile(assigns) do
    ~H"""
    <div class="flex flex-col items-center rounded-lg bg-white border border-gray-200 px-3 py-3 gap-1">
      <span class="text-xl">{@emoji}</span>
      <span class="text-sm font-bold text-gray-900">{@value}</span>
      <span class="text-xs text-gray-400">{@label}</span>
    </div>
    """
  end

  # --- Helpers ---

  defp resolve_dates(preset, from_str, to_str) do
    today = Date.utc_today()

    case Map.get(@presets, preset) do
      nil ->
        date_from = parse_date(from_str) || Date.add(today, -30)
        date_to = parse_date(to_str) || today
        {date_from, date_to}

      days ->
        {Date.add(today, -days), today}
    end
  end

  defp build_params(tab, preset, date_from, date_to) do
    base = if tab == :activity, do: %{"tab" => "activity"}, else: %{}
    Map.merge(base, %{"preset" => preset, "from" => date_from, "to" => date_to})
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp date_str(%Date{} = d), do: Date.to_iso8601(d)
  defp date_str(nil), do: ""

  defp summary_line(log) do
    parts = [
      log.steps && "👟 #{format_steps(log.steps)}",
      log.active_kcal && "🔥 #{round(log.active_kcal)} kcal",
      log.resting_hr_bpm && "❤️ #{log.resting_hr_bpm} bpm",
      log.sleep_minutes &&
        "🌙 #{:erlang.float_to_binary(log.sleep_minutes / 60, decimals: 1)} hrs"
    ]

    parts |> Enum.filter(& &1) |> Enum.join("  ·  ")
  end

  defp format_steps(n) when n >= 1000 do
    thousands = div(n, 1000)
    hundreds = rem(n, 1000)
    "#{thousands},#{String.pad_leading(to_string(hundreds), 3, "0")}"
  end

  defp format_steps(n), do: to_string(n)
end
