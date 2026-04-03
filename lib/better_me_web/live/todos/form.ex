defmodule BetterMeWeb.TodosLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Todos

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {todo, action} = load_todo(params, user_id)
    changeset = Todos.change_todo(todo)

    {:ok,
     socket
     |> assign(action: action, todo: todo, user_id: user_id)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "New Todo", else: "Edit Todo"}
        back_path={~p"/todos"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
          <.input
            field={@form[:title]}
            type="text"
            placeholder="What needs to be done?"
            class="w-full"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
          <.input
            field={@form[:category]}
            type="select"
            options={[
              {"Work", :work},
              {"Personal", :personal},
              {"Health", :health},
              {"Learning", :learning},
              {"Misc", :misc}
            ]}
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Priority</label>
          <.input
            field={@form[:priority]}
            type="select"
            options={[{"High", :high}, {"Medium", :medium}, {"Low", :low}]}
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Due date <span class="text-gray-400">(optional)</span>
          </label>
          <.input field={@form[:due_date]} type="date" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Repeat</label>
          <.input
            field={@form[:repeat]}
            type="select"
            options={[{"None", :none}, {"Daily", :daily}, {"Weekly", :weekly}, {"Monthly", :monthly}]}
          />
        </div>

        <.form_actions action={@action} cancel_path={~p"/todos"} on_delete="delete" />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", %{"todo" => params}, socket) do
    changeset =
      socket.assigns.todo
      |> Todos.change_todo(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"todo" => params}, socket) do
    case socket.assigns.action do
      :new -> create_todo(socket, params)
      :edit -> update_todo(socket, params)
    end
  end

  def handle_event("delete", _params, socket) do
    case Todos.delete_todo(socket.assigns.todo) do
      {:ok, _} -> {:noreply, push_navigate(socket, to: ~p"/todos")}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not delete todo")}
    end
  end

  defp create_todo(socket, params) do
    case Todos.create_todo(socket.assigns.user_id, params) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Todo created") |> push_navigate(to: ~p"/todos")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_todo(socket, params) do
    case Todos.update_todo(socket.assigns.todo, params) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Todo updated") |> push_navigate(to: ~p"/todos")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_todo(%{"id" => id}, user_id), do: {Todos.get_todo!(id, user_id), :edit}
  defp load_todo(_params, _user_id), do: {Todos.new_todo(), :new}

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
end
