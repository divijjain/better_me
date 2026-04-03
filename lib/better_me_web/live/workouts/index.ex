defmodule BetterMeWeb.WorkoutsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Workouts

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:ok,
     assign(socket, workouts: Workouts.list_workouts_with_routine(user_id), user_id: user_id)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Workouts" new_path={~p"/workouts/new"} />

      <.empty_state :if={@workouts == []} message="No workouts yet. Log your first session!" />

      <ul class="space-y-2">
        <li
          :for={workout <- @workouts}
          :key={workout.id}
          class="relative flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm hover:bg-gray-50 transition"
        >
          <.link navigate={~p"/workouts/#{workout.id}"} class="absolute inset-0"></.link>
          <div class="relative pointer-events-none">
            <p class="text-sm font-semibold text-gray-900">
              {Calendar.strftime(workout.date, "%b %-d, %Y")}
            </p>
            <p class="text-xs text-gray-400 capitalize mt-0.5">
              {if workout.routine_day, do: workout.routine_day.name, else: workout.type}
              <%= if workout.duration do %>
                · {workout.duration} min
              <% end %>
            </p>
          </div>
          <div class="relative flex items-center gap-3">
            <.edit_link path={~p"/workouts/#{workout.id}/edit"} />
          </div>
        </li>
      </ul>
    </.page_container>
    """
  end
end
