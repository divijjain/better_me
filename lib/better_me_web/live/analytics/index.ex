defmodule BetterMeWeb.AnalyticsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Habits
  alias BetterMe.Health
  alias BetterMe.Journals
  alias BetterMe.Nutrition
  alias BetterMe.Workouts

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:ok,
     socket
     |> assign(:page_title, "Analytics")
     |> assign(:weight, Health.weight_trend(user_id))
     |> assign(:workout_freq, Workouts.workout_frequency(user_id))
     |> assign(:workout_types, Workouts.workout_by_type(user_id))
     |> assign(:calories, Nutrition.daily_calories(user_id))
     |> assign(:mood, Journals.mood_trend(user_id))
     |> assign(:habits, Habits.habit_completion_rates(user_id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-6 space-y-8">
      <h1 class="text-xl font-bold text-gray-900">Analytics</h1>

      <%!-- Body Weight --%>
      <section>
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Body Weight — Last 30 Days
        </h2>
        <%= if @weight == [] do %>
          <p class="text-sm text-gray-400">No data yet.</p>
        <% else %>
          <.bar_chart
            data={@weight}
            value_key={:weight}
            label_fn={&format_date/1}
            unit="kg"
            color="bg-indigo-500"
          />
        <% end %>
      </section>

      <%!-- Workout Frequency --%>
      <section>
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Workouts per Week — Last 8 Weeks
        </h2>
        <%= if @workout_freq == [] do %>
          <p class="text-sm text-gray-400">No data yet.</p>
        <% else %>
          <.bar_chart
            data={@workout_freq}
            value_key={:count}
            label_fn={&format_week/1}
            unit=""
            color="bg-green-500"
          />
        <% end %>
      </section>

      <%!-- Workout Types --%>
      <section>
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Workout Types — Last 30 Days
        </h2>
        <%= if @workout_types == [] do %>
          <p class="text-sm text-gray-400">No data yet.</p>
        <% else %>
          <.bar_chart
            data={@workout_types}
            value_key={:count}
            label_fn={&format_type/1}
            unit=""
            color="bg-emerald-500"
          />
        <% end %>
      </section>

      <%!-- Daily Calories --%>
      <section>
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Daily Calories — Last 14 Days
        </h2>
        <%= if @calories == [] do %>
          <p class="text-sm text-gray-400">No data yet.</p>
        <% else %>
          <.bar_chart
            data={@calories}
            value_key={:calories}
            label_fn={&format_date/1}
            unit="kcal"
            color="bg-orange-400"
          />
        <% end %>
      </section>

      <%!-- Mood Trend --%>
      <section>
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Average Mood per Week — Last 8 Weeks
        </h2>
        <%= if @mood == [] do %>
          <p class="text-sm text-gray-400">No journal entries with mood yet.</p>
        <% else %>
          <.bar_chart
            data={@mood}
            value_key={:avg_mood}
            label_fn={&format_week/1}
            unit="/5"
            max={5}
            color="bg-purple-500"
          />
        <% end %>
      </section>

      <%!-- Habit Completion --%>
      <section>
        <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Habit Completion — Last 30 Days
        </h2>
        <%= if @habits == [] do %>
          <p class="text-sm text-gray-400">No habits yet.</p>
        <% else %>
          <div class="space-y-3">
            <%= for h <- @habits do %>
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span class="text-gray-700 font-medium">{h.name}</span>
                  <span class="text-gray-500">{h.logged} days · {h.rate}%</span>
                </div>
                <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-indigo-400 rounded-full"
                    style={"width: #{min(h.rate, 100)}%"}
                  >
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </section>
    </div>
    """
  end

  # --- Bar chart component ---

  attr :data, :list, required: true
  attr :value_key, :atom, required: true
  attr :label_fn, :any, required: true
  attr :unit, :string, default: ""
  attr :color, :string, default: "bg-indigo-500"
  attr :max, :any, default: nil

  defp bar_chart(assigns) do
    max_val =
      if assigns.max do
        assigns.max
      else
        assigns.data
        |> Enum.map(&Map.get(&1, assigns.value_key))
        |> Enum.map(&Decimal.to_float(to_decimal(&1)))
        |> Enum.max(fn -> 1 end)
      end

    assigns = assign(assigns, :max_val, max_val)

    ~H"""
    <div class="space-y-1.5">
      <%= for row <- @data do %>
        <% raw_val = Map.get(row, @value_key) %>
        <% val = to_float(raw_val) %>
        <% pct = if @max_val > 0, do: min(val / @max_val * 100, 100), else: 0 %>
        <div class="flex items-center gap-2">
          <span class="w-16 text-xs text-gray-400 text-right shrink-0">
            {@label_fn.(row)}
          </span>
          <div class="flex-1 h-5 bg-gray-100 rounded overflow-hidden">
            <div class={["h-full rounded", @color]} style={"width: #{pct}%"}></div>
          </div>
          <span class="w-20 text-xs text-gray-500 shrink-0">
            {format_val(raw_val)}{@unit}
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  # --- Helpers ---

  defp format_date(%{date: date}), do: Calendar.strftime(date, "%b %d")
  defp format_date(%{week: date}), do: Calendar.strftime(date, "%b %d")
  defp format_week(%{week: date}), do: Calendar.strftime(date, "%b %d")
  defp format_type(%{type: type}), do: type |> to_string() |> String.capitalize()

  defp to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp to_float(n) when is_float(n), do: n
  defp to_float(n) when is_integer(n), do: n * 1.0
  defp to_float(nil), do: 0.0

  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(n), do: Decimal.new("#{n}")

  defp format_val(%Decimal{} = d),
    do: d |> Decimal.to_float() |> :erlang.float_to_binary(decimals: 1)

  defp format_val(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)
  defp format_val(n) when is_integer(n), do: to_string(n)
  defp format_val(nil), do: "0"
end
