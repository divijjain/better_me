defmodule BetterMeWeb.TodosLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Todos

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, load_todos(socket, user_id)}
  end

  def handle_params(params, _url, socket) do
    filter = Map.get(params, "filter", "pending")
    user_id = socket.assigns.current_scope.user.id
    {:noreply, socket |> assign(:filter, filter) |> load_todos(user_id, filter)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Todos</h1>
        <.link
          navigate={~p"/todos/new"}
          class="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> New
        </.link>
      </div>

      <%!-- Filter tabs --%>
      <div class="flex gap-2 mb-5">
        <.link
          patch={~p"/todos?filter=pending"}
          class={[
            "rounded-full px-3 py-1 text-sm font-medium transition",
            if(@filter == "pending", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200")
          ]}
        >
          Pending
        </.link>
        <.link
          patch={~p"/todos?filter=done"}
          class={[
            "rounded-full px-3 py-1 text-sm font-medium transition",
            if(@filter == "done", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200")
          ]}
        >
          Done
        </.link>
      </div>

      <div :if={@todos == []} class="text-center py-16 text-gray-400">
        <%= if @filter == "done", do: "No completed todos.", else: "Nothing pending. Add your first one!" %>
      </div>

      <ul class="space-y-2">
        <li
          :for={todo <- @todos}
          class="relative flex items-center gap-3 rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm hover:bg-gray-50 transition"
        >
          <button
            phx-click="complete"
            phx-value-id={todo.id}
            disabled={todo.completed}
            class={[
              "flex-shrink-0 h-5 w-5 rounded border-2 transition",
              if(todo.completed,
                do: "border-indigo-600 bg-indigo-600",
                else: "border-gray-300 hover:border-indigo-400"
              )
            ]}
          >
            <.icon :if={todo.completed} name="hero-check" class="h-3 w-3 text-white" />
          </button>

          <div class="flex-1 min-w-0">
            <p class={["text-sm font-medium truncate", if(todo.completed, do: "line-through text-gray-400", else: "text-gray-900")]}>
              {todo.title}
            </p>
            <p class="text-xs text-gray-400 capitalize">
              {todo.category}
              <%= if todo.due_date do %>
                · due {Calendar.strftime(todo.due_date, "%b %-d")}
              <% end %>
            </p>
          </div>

          <span class={[
            "flex-shrink-0 text-xs font-medium px-2 py-0.5 rounded-full",
            priority_class(todo.priority)
          ]}>
            {todo.priority}
          </span>

          <.link
            navigate={~p"/todos/#{todo.id}/edit"}
            class="flex-shrink-0 text-gray-400 hover:text-gray-600"
          >
            <.icon name="hero-pencil-square" class="h-4 w-4" />
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  def handle_event("complete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_scope.user.id

    with {:ok, todo} <- Todos.get_todo(id, user_id),
         {:ok, _}    <- Todos.complete_todo(todo) do
      {:noreply, load_todos(socket, user_id, socket.assigns.filter)}
    else
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not complete todo")}
    end
  end

  defp load_todos(socket, user_id, filter \\ "pending") do
    completed = filter == "done"
    assign(socket, todos: Todos.list_todos(user_id, completed: completed), filter: filter)
  end

  defp priority_class(:high),   do: "bg-red-100 text-red-700"
  defp priority_class(:medium), do: "bg-yellow-100 text-yellow-700"
  defp priority_class(:low),    do: "bg-green-100 text-green-700"
  defp priority_class(_),       do: "bg-gray-100 text-gray-600"
end
