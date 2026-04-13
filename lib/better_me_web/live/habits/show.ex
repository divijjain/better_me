defmodule BetterMeWeb.HabitsLive.Show do
  use BetterMeWeb, :live_view

  alias BetterMe.Habits

  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    case Habits.habit_stats(id, user_id) do
      {:ok, stats} -> {:ok, assign(socket, stats: stats, user_id: user_id, habit_id: id)}
      {:error, :not_found} -> {:ok, push_navigate(socket, to: ~p"/habits")}
    end
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_container>
      <%!-- Header --%>
      <div class="mb-6 flex items-center gap-3">
        <.link navigate={~p"/habits"} class="text-gray-400 hover:text-gray-600">
          <.icon name="hero-arrow-left" class="h-5 w-5" />
        </.link>
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-gray-900">{@stats.habit.name}</h1>
          <p class="text-sm text-gray-400 capitalize">
            {@stats.habit.category} · {@stats.habit.frequency}
          </p>
        </div>
        <.edit_link path={~p"/habits/#{@stats.habit.id}/edit"} />
      </div>

      <%!-- Streak stats --%>
      <div class="grid grid-cols-2 gap-4 mb-8">
        <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm text-center">
          <p class="text-3xl font-bold text-indigo-600">{@stats.current_streak}🔥</p>
          <p class="mt-1 text-sm text-gray-500">Current streak</p>
        </div>
        <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm text-center">
          <p class="text-3xl font-bold text-amber-500">{@stats.longest_streak}⭐</p>
          <p class="mt-1 text-sm text-gray-500">Longest streak</p>
        </div>
      </div>

      <%!-- 30-day calendar --%>
      <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm mb-6">
        <h2 class="text-sm font-semibold text-gray-700 mb-4">Last 30 days</h2>
        <div class="grid grid-cols-10 gap-1.5">
          <div
            :for={day <- last_30_days()}
            :key={day}
            class={[
              "h-9 w-9 rounded-md flex items-center justify-center text-xs font-medium",
              if(MapSet.member?(@stats.calendar_dates, day),
                do: "bg-indigo-500 text-white",
                else: "bg-gray-100 text-gray-400"
              )
            ]}
          >
            {day.day}
          </div>
        </div>
        <div class="mt-3 flex items-center gap-2 text-xs text-gray-400">
          <div class="h-3 w-3 rounded-sm bg-gray-100" /> Not done
          <div class="h-3 w-3 rounded-sm bg-indigo-500 ml-2" /> Done
        </div>
      </div>

      <%!-- Log today button --%>
      <% logged_today = MapSet.member?(@stats.calendar_dates, Date.utc_today()) %>
      <button
        phx-click="log_today"
        disabled={logged_today}
        class={[
          "w-full rounded-xl py-3 text-sm font-semibold transition",
          if(logged_today,
            do: "bg-indigo-100 text-indigo-400 cursor-not-allowed",
            else: "bg-indigo-600 text-white hover:bg-indigo-500"
          )
        ]}
      >
        <span :if={logged_today}>Logged today ✓</span>
        <span :if={!logged_today}>Log for today</span>
      </button>
    </.page_container>
    """
  end

  def handle_event("log_today", _params, socket) do
    {:noreply, do_log_today(socket)}
  end

  defp do_log_today(socket) do
    attrs = %{date: Date.utc_today(), completed: true}

    with {:ok, _log} <-
           Habits.log_habit(socket.assigns.habit_id, attrs),
         {:ok, stats} <- Habits.habit_stats(socket.assigns.habit_id, socket.assigns.user_id) do
      assign(socket, :stats, stats)
    else
      {:error, _} -> put_flash(socket, :error, "Could not log habit")
    end
  end

  defp last_30_days do
    today = Date.utc_today()
    Enum.map(29..0//-1, &Date.add(today, -&1))
  end
end
