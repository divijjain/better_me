defmodule BetterMeWeb.WorkoutsLive.Show do
  use BetterMeWeb, :live_view

  alias BetterMe.Workouts

  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    case Workouts.get_workout_with_exercises(id, user_id) do
      {:ok, workout} ->
        {:ok,
         socket
         |> assign(workout: workout, user_id: user_id, add_exercise_form: nil)
         |> build_set_forms(workout)
         |> build_substitution_map(workout)
         |> assign_add_exercise_form()}

      {:error, :not_found} ->
        {:ok, push_navigate(socket, to: ~p"/workouts")}
    end
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_container>
      <%!-- Header --%>
      <div class="mb-6 flex items-center gap-3">
        <.link navigate={~p"/workouts"} class="text-gray-400 hover:text-gray-600">
          <.icon name="hero-arrow-left" class="h-5 w-5" />
        </.link>
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-gray-900">
            {Calendar.strftime(@workout.date, "%b %-d, %Y")}
          </h1>
          <p class="text-sm text-gray-400 capitalize mt-0.5">
            {@workout.type}
            <span :if={@workout.duration}>· {@workout.duration} min</span>
          </p>
        </div>
        <.edit_link path={~p"/workouts/#{@workout.id}/edit"} />
      </div>

      <%!-- Notes --%>
      <div
        :if={@workout.notes}
        class="mb-6 rounded-lg bg-gray-50 border border-gray-200 px-4 py-3 text-sm text-gray-600"
      >
        {@workout.notes}
      </div>

      <%!-- Exercise list --%>
      <.empty_state :if={@workout.exercises == []} message="No exercises yet. Add one below." />

      <div class="space-y-4 mb-6">
        <div
          :for={exercise <- @workout.exercises}
          :key={exercise.id}
          class="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden"
        >
          <%!-- Exercise header --%>
          <div class="flex items-center justify-between px-4 py-3 bg-gray-50 border-b border-gray-200">
            <div>
              <div class="flex items-center gap-2">
                <span class="text-sm font-semibold text-gray-900">{exercise.name}</span>
                <span
                  :if={exercise.is_pr}
                  class="text-xs font-semibold text-amber-600 bg-amber-50 border border-amber-200 rounded-full px-2 py-0.5"
                >
                  PR 🏆
                </span>
              </div>
              <%= if subs = Map.get(@substitutions, exercise.name) do %>
                <p class="text-xs text-gray-400 mt-0.5">
                  Sub: {Enum.join(subs, " / ")}
                </p>
              <% end %>
            </div>
            <button
              phx-click="delete_exercise"
              phx-value-id={exercise.id}
              data-confirm="Remove this exercise and all its sets?"
              class="text-gray-300 hover:text-red-400 transition"
            >
              <.icon name="hero-x-mark" class="h-4 w-4" />
            </button>
          </div>

          <%!-- Sets --%>
          <div class="px-4 py-3">
            <p :if={exercise.exercise_sets == []} class="text-xs text-gray-400 mb-3">
              No sets logged yet.
            </p>
            <div :if={exercise.exercise_sets != []} class="mb-3 space-y-2">
              <%!-- Set header row --%>
              <div class="grid grid-cols-[2rem_1fr_1fr_2rem] gap-2 text-xs font-medium text-gray-400 px-1">
                <span>Set</span>
                <span>Weight (kg)</span>
                <span>Reps</span>
                <span></span>
              </div>

              <%!-- Logged sets --%>
              <div
                :for={set <- exercise.exercise_sets}
                :key={set.id}
                class={[
                  "grid grid-cols-[2rem_1fr_1fr_2rem] gap-2 items-center rounded-md px-1 py-1.5 text-sm",
                  set.completed && "bg-green-50",
                  !set.completed && "bg-gray-50"
                ]}
              >
                <span class="font-medium text-gray-500">{set.set_number}</span>

                <.form
                  for={@set_forms[set.id]}
                  phx-change="update_set"
                  phx-value-set-id={set.id}
                  id={"set-form-#{set.id}"}
                  class="contents"
                >
                  <input
                    type="number"
                    name="set[weight]"
                    value={set.weight}
                    step="0.5"
                    min="0"
                    placeholder="—"
                    class="w-full rounded border border-gray-200 px-2 py-1 text-sm focus:border-indigo-400 focus:outline-none"
                    phx-debounce="500"
                  />
                  <input
                    type="number"
                    name="set[reps]"
                    value={set.reps}
                    min="1"
                    placeholder="—"
                    class="w-full rounded border border-gray-200 px-2 py-1 text-sm focus:border-indigo-400 focus:outline-none"
                    phx-debounce="500"
                  />
                </.form>

                <button
                  phx-click="delete_set"
                  phx-value-set-id={set.id}
                  phx-value-exercise-id={exercise.id}
                  class="text-gray-300 hover:text-red-400 transition"
                >
                  <.icon name="hero-x-mark" class="h-3.5 w-3.5" />
                </button>
              </div>
            </div>

            <%!-- Add set button --%>
            <button
              phx-click="add_set"
              phx-value-exercise-id={exercise.id}
              class="w-full rounded-md border border-dashed border-indigo-300 py-1.5 text-xs font-medium text-indigo-500 hover:bg-indigo-50 transition"
            >
              + Add Set
            </button>
          </div>
        </div>
      </div>

      <%!-- Add exercise form --%>
      <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
        <h2 class="text-sm font-semibold text-gray-700 mb-4">Add Exercise</h2>
        <.form
          for={@add_exercise_form}
          phx-change="validate_exercise"
          phx-submit="add_exercise"
          class="space-y-3"
        >
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <.input
              field={@add_exercise_form[:name]}
              type="text"
              placeholder="e.g. Bench Press"
              class="w-full"
            />
          </div>

          <button
            type="submit"
            class="w-full rounded-md bg-indigo-600 py-2 text-sm font-medium text-white hover:bg-indigo-500"
          >
            Add Exercise
          </button>
        </.form>
      </div>
    </.page_container>
    """
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  def handle_event("validate_exercise", %{"exercise" => params}, socket) do
    changeset =
      Workouts.new_exercise()
      |> Workouts.change_exercise(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :add_exercise_form, to_form(changeset))}
  end

  def handle_event("add_exercise", %{"exercise" => params}, socket) do
    %{workout: workout, user_id: user_id} = socket.assigns

    case Workouts.add_exercise(user_id, workout.id, params) do
      {:ok, _exercise, :pr} ->
        {:noreply,
         socket
         |> put_flash(:info, "Exercise added — new PR! 🏆")
         |> reload_workout()}

      {:ok, _exercise, :no_pr} ->
        {:noreply, reload_workout(socket)}

      {:error, changeset} ->
        {:noreply, assign(socket, :add_exercise_form, to_form(changeset))}
    end
  end

  def handle_event("delete_exercise", %{"id" => id}, socket) do
    %{workout: workout} = socket.assigns

    case Workouts.get_exercise(id, workout.id) do
      {:ok, exercise} ->
        {:ok, _} = Workouts.delete_exercise(exercise)
        {:noreply, reload_workout(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Exercise not found")}
    end
  end

  def handle_event("add_set", %{"exercise-id" => exercise_id}, socket) do
    {id, _} = Integer.parse(exercise_id)

    case find_exercise(socket.assigns.workout, id) do
      {:ok, exercise} ->
        case Workouts.log_set(socket.assigns.user_id, exercise, %{}) do
          {:ok, _set, :pr} ->
            {:noreply, socket |> put_flash(:info, "New PR! 🏆") |> reload_workout()}

          {:ok, _set, :no_pr} ->
            {:noreply, reload_workout(socket)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not add set")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Exercise not found")}
    end
  end

  def handle_event("update_set", %{"set" => params, "set-id" => set_id}, socket) do
    {id, _} = Integer.parse(set_id)

    with {:ok, exercise} <- find_exercise_for_set(socket.assigns.workout, id),
         {:ok, set} <- Workouts.get_exercise_set(id, exercise.id),
         {:ok, _} <- Workouts.update_exercise_set(set, set_attrs(params)) do
      {:noreply, reload_workout(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("delete_set", %{"set-id" => set_id, "exercise-id" => exercise_id}, socket) do
    {sid, _} = Integer.parse(set_id)
    {eid, _} = Integer.parse(exercise_id)

    case Workouts.get_exercise_set(sid, eid) do
      {:ok, set} ->
        {:ok, _} = Workouts.delete_exercise_set(set)
        {:noreply, reload_workout(socket)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp reload_workout(socket) do
    %{workout: workout, user_id: user_id} = socket.assigns
    {:ok, workout} = Workouts.get_workout_with_exercises(workout.id, user_id)

    socket
    |> assign(:workout, workout)
    |> build_set_forms(workout)
    |> build_substitution_map(workout)
    |> assign_add_exercise_form()
  end

  defp build_set_forms(socket, workout) do
    set_forms =
      workout.exercises
      |> Enum.flat_map(& &1.exercise_sets)
      |> Map.new(fn set -> {set.id, to_form(%{}, as: "set")} end)

    assign(socket, :set_forms, set_forms)
  end

  defp build_substitution_map(socket, workout) do
    subs =
      case workout.routine_day do
        %{routine_exercises: routine_exercises} ->
          Map.new(routine_exercises, fn re ->
            values = [re.substitution_1, re.substitution_2] |> Enum.reject(&is_nil/1)
            {re.name, values}
          end)

        _ ->
          %{}
      end

    assign(socket, :substitutions, subs)
  end

  defp assign_add_exercise_form(socket) do
    changeset = Workouts.change_exercise(Workouts.new_exercise())
    assign(socket, :add_exercise_form, to_form(changeset))
  end

  defp find_exercise(workout, exercise_id) do
    case Enum.find(workout.exercises, &(&1.id == exercise_id)) do
      nil -> {:error, :not_found}
      exercise -> {:ok, exercise}
    end
  end

  defp find_exercise_for_set(workout, set_id) do
    exercise =
      Enum.find(workout.exercises, fn ex ->
        Enum.any?(ex.exercise_sets, &(&1.id == set_id))
      end)

    if exercise, do: {:ok, exercise}, else: {:error, :not_found}
  end

  defp set_attrs(params) do
    %{
      "weight" => parse_float(params["weight"]),
      "reps" => parse_int(params["reps"]),
      "completed" => params["weight"] not in [nil, ""] or params["reps"] not in [nil, ""]
    }
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil

  defp parse_float(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> nil
    end
  end
end
