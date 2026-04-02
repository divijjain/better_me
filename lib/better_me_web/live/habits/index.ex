defmodule BetterMeWeb.HabitsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Habits

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, load_habits(socket, user_id)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Habits</h1>
        <.link
          navigate={~p"/habits/new"}
          class="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> New
        </.link>
      </div>

      <div :if={@habits == []} class="text-center py-16 text-gray-400">
        No habits yet. Add your first one!
      </div>

      <ul class="space-y-3">
        <li
          :for={habit <- @habits}
          class="relative flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm hover:bg-gray-50 transition"
        >
          <.link navigate={~p"/habits/#{habit.id}"} class="absolute inset-0"></.link>
          <div class="relative flex items-center gap-3 pointer-events-none">
            <button
              phx-click="log_today"
              phx-value-id={habit.id}
              class={[
                "flex h-8 w-8 items-center justify-center rounded-full border-2 transition pointer-events-auto",
                if(habit.logged_today,
                  do: "border-indigo-600 bg-indigo-600 text-white",
                  else: "border-gray-300 text-gray-300 hover:border-indigo-400"
                )
              ]}
              disabled={habit.logged_today}
              title={if habit.logged_today, do: "Logged today", else: "Log for today"}
            >
              <.icon name="hero-check" class="h-4 w-4" />
            </button>
            <div>
              <p class="font-medium text-gray-900">{habit.name}</p>
              <p class="text-xs text-gray-400 capitalize">{habit.category}</p>
            </div>
          </div>
          <div class="relative flex items-center gap-3">
            <span class="text-sm font-semibold text-indigo-600">
              {habit.streak}🔥
            </span>
            <.link
              navigate={~p"/habits/#{habit.id}/edit"}
              class="text-gray-400 hover:text-gray-600"
            >
              <.icon name="hero-pencil-square" class="h-4 w-4" />
            </.link>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  def handle_event("log_today", %{"id" => id}, socket) do
    {:noreply, do_log_today(socket, id)}
  end

  defp do_log_today(socket, habit_id) do
    user_id = socket.assigns.current_scope.user.id

    with {:ok, habit} <- Habits.get_habit(habit_id, user_id),
         {:ok, _log} <- Habits.log_habit(habit.id, %{date: Date.utc_today(), completed: true}) do
      load_habits(socket, user_id)
    else
      {:error, _} -> put_flash(socket, :error, "Could not log habit")
    end
  end

  defp load_habits(socket, user_id) do
    assign(socket, habits: Habits.list_habits_with_meta(user_id), current_user_id: user_id)
  end
end
