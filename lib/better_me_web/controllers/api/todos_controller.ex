defmodule BetterMeWeb.Api.TodosController do
  @moduledoc "JSON API for todos — list, create, complete, delete."

  use BetterMeWeb, :controller
  alias BetterMe.Todos

  def index(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    completed = Map.get(params, "completed", "false") == "true"
    todos = Todos.list_todos(user_id, completed: completed)
    json(conn, %{data: Enum.map(todos, &serialize/1)})
  end

  def create(conn, %{"todo" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    case Todos.create_todo(user_id, attrs) do
      {:ok, todo} ->
        conn |> put_status(:created) |> json(%{data: serialize(todo)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def complete(conn, %{"id" => id}) do
    user_id = conn.assigns.current_scope.user.id

    with {:ok, todo} <- Todos.get_todo(id, user_id),
         {:ok, updated} <- Todos.complete_todo(todo) do
      json(conn, %{data: serialize(updated)})
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{errors: %{detail: "Not found"}})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user_id = conn.assigns.current_scope.user.id

    with {:ok, todo} <- Todos.get_todo(id, user_id),
         {:ok, _} <- Todos.delete_todo(todo) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{errors: %{detail: "Not found"}})
    end
  end

  defp serialize(todo) do
    %{
      id: todo.id,
      title: todo.title,
      category: todo.category,
      priority: todo.priority,
      due_date: todo.due_date,
      repeat: todo.repeat,
      completed: todo.completed
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
