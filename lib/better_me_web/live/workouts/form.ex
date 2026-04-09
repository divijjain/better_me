defmodule BetterMeWeb.WorkoutsLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Workouts

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {workout, action} = load_workout(params, user_id)
    changeset = Workouts.change_workout(workout)
    templates = Workouts.list_routine_templates(user_id)

    {:ok,
     socket
     |> assign(
       action: action,
       workout: workout,
       user_id: user_id,
       templates: templates,
       routine_days: [],
       selected_template_id: nil,
       selected_day_id: nil,
       preview_exercises: []
     )
     |> assign_form(changeset)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "New Workout", else: "Edit Workout"}
        back_path={~p"/workouts"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
          <.input field={@form[:date]} type="date" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Type</label>
          <.input
            field={@form[:type]}
            type="select"
            options={[
              {"Strength", :strength},
              {"Cardio", :cardio},
              {"Flexibility", :flexibility},
              {"Sport", :sport},
              {"Other", :other}
            ]}
          />
        </div>

        <%!-- Routine picker (only on new workouts) --%>
        <%= if @action == :new do %>
          <div :if={@templates != []}>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Routine <span class="text-gray-400">(optional)</span>
            </label>
            <select
              phx-change="select_template"
              name="template_id"
              class="block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            >
              <option value="">— No routine —</option>
              <%= for t <- @templates do %>
                <option value={t.id} selected={@selected_template_id == t.id}>{t.name}</option>
              <% end %>
            </select>
          </div>

          <div :if={@routine_days != []}>
            <label class="block text-sm font-medium text-gray-700 mb-1">Day</label>
            <select
              phx-change="select_day"
              name="day_id"
              class="block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            >
              <option value="">— Select a day —</option>
              <%= for d <- @routine_days do %>
                <option value={d.id} selected={@selected_day_id == d.id}>{d.name}</option>
              <% end %>
            </select>
          </div>
        <% end %>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Duration (min) <span class="text-gray-400">(optional)</span>
          </label>
          <.input field={@form[:duration]} type="number" placeholder="e.g. 60" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Notes <span class="text-gray-400">(optional)</span>
          </label>
          <.input field={@form[:notes]} type="textarea" class="w-full" />
        </div>

        <.form_actions action={@action} cancel_path={~p"/workouts"} on_delete="delete" />
      </.form>
    </.page_container>
    """
  end

  def handle_event("select_template", %{"template_id" => ""}, socket) do
    {:noreply,
     assign(socket,
       selected_template_id: nil,
       routine_days: [],
       selected_day_id: nil,
       preview_exercises: []
     )}
  end

  def handle_event("select_template", %{"template_id" => template_id}, socket) do
    user_id = socket.assigns.user_id
    {id, _} = Integer.parse(template_id)

    case Workouts.get_routine_template_with_days(id, user_id) do
      {:ok, template} ->
        {:noreply,
         assign(socket,
           selected_template_id: id,
           routine_days: template.days,
           selected_day_id: nil,
           preview_exercises: []
         )}

      {:error, _} ->
        {:noreply,
         assign(socket,
           selected_template_id: nil,
           routine_days: [],
           selected_day_id: nil,
           preview_exercises: []
         )}
    end
  end

  def handle_event("select_day", %{"day_id" => ""}, socket) do
    {:noreply, assign(socket, selected_day_id: nil, preview_exercises: [])}
  end

  def handle_event("select_day", %{"day_id" => day_id}, socket) do
    {id, _} = Integer.parse(day_id)

    exercises =
      case Workouts.get_routine_day_with_exercises(id) do
        {:ok, day} -> day.routine_exercises
        _ -> []
      end

    {:noreply, assign(socket, selected_day_id: id, preview_exercises: exercises)}
  end

  def handle_event("validate", %{"workout" => params}, socket) do
    changeset =
      socket.assigns.workout
      |> Workouts.change_workout(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"workout" => params}, socket) do
    case socket.assigns.action do
      :new -> create_workout(socket, params)
      :edit -> update_workout(socket, params)
    end
  end

  def handle_event("delete", _params, socket) do
    case Workouts.delete_workout(socket.assigns.workout) do
      {:ok, _} -> {:noreply, push_navigate(socket, to: ~p"/workouts")}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not delete workout")}
    end
  end

  defp create_workout(socket, params) do
    case Workouts.create_workout(socket.assigns.user_id, params) do
      {:ok, workout} ->
        maybe_populate_from_routine(socket, workout)

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp maybe_populate_from_routine(socket, workout) do
    case socket.assigns.selected_day_id do
      nil ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout created")
         |> push_navigate(to: ~p"/workouts/#{workout.id}")}

      day_id ->
        Workouts.populate_from_routine(workout, day_id)

        {:noreply,
         socket
         |> put_flash(:info, "Workout created with routine exercises")
         |> push_navigate(to: ~p"/workouts/#{workout.id}")}
    end
  end

  defp update_workout(socket, params) do
    case Workouts.update_workout(socket.assigns.workout, params) do
      {:ok, workout} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout updated")
         |> push_navigate(to: ~p"/workouts/#{workout.id}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_workout(%{"id" => id}, user_id), do: {Workouts.get_workout!(id, user_id), :edit}
  defp load_workout(_params, _user_id), do: {Workouts.new_workout(), :new}

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
end
