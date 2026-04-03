defmodule BetterMeWeb.HabitsLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Habits

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {habit, action} = load_habit(params, user_id)
    changeset = Habits.change_habit(habit)

    {:ok,
     socket
     |> assign(action: action, habit: habit, user_id: user_id)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "New Habit", else: "Edit Habit"}
        back_path={~p"/habits"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
          <.input
            field={@form[:name]}
            type="text"
            placeholder="e.g. Morning run"
            class="w-full"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
          <.input
            field={@form[:category]}
            type="select"
            options={[
              {"Health", :health},
              {"Fitness", :fitness},
              {"Personal", :personal},
              {"Learning", :learning},
              {"Work", :work},
              {"Misc", :misc}
            ]}
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Frequency</label>
          <.input
            field={@form[:frequency]}
            type="select"
            options={[{"Daily", :daily}, {"Weekly", :weekly}]}
          />
        </div>

        <.form_actions action={@action} cancel_path={~p"/habits"} on_delete="delete" />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", %{"habit" => params}, socket) do
    changeset =
      socket.assigns.habit
      |> Habits.change_habit(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"habit" => params}, socket) do
    case socket.assigns.action do
      :new -> create_habit(socket, params)
      :edit -> update_habit(socket, params)
    end
  end

  def handle_event("delete", _params, socket) do
    {:noreply, do_delete(socket)}
  end

  defp create_habit(socket, params) do
    case Habits.create_habit(socket.assigns.user_id, params) do
      {:ok, _habit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Habit created")
         |> push_navigate(to: ~p"/habits")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_habit(socket, params) do
    case Habits.update_habit(socket.assigns.habit, params) do
      {:ok, _habit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Habit updated")
         |> push_navigate(to: ~p"/habits")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_habit(%{"id" => id}, user_id) do
    {Habits.get_habit!(id, user_id), :edit}
  end

  defp load_habit(_params, _user_id) do
    {Habits.new_habit(), :new}
  end

  defp do_delete(socket) do
    case Habits.delete_habit(socket.assigns.habit) do
      {:ok, _} -> push_navigate(socket, to: ~p"/habits")
      {:error, _} -> put_flash(socket, :error, "Could not delete habit")
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
