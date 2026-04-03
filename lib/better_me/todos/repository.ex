defmodule BetterMe.Todos.Repository do
  import Ecto.Query
  alias BetterMe.Repo
  alias BetterMe.Todos.Schema.Todo

  def list_todos(user_id, opts \\ []) do
    completed = Keyword.get(opts, :completed, false)
    category  = Keyword.get(opts, :category)

    Todo
    |> where(user_id: ^user_id, completed: ^completed)
    |> maybe_where_category(category)
    |> order_by([t], [asc: t.priority, asc: t.due_date, asc: t.inserted_at])
    |> limit(200)
    |> Repo.all()
  end

  def get_todo(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil  -> {:error, :not_found}
      todo -> {:ok, todo}
    end
  end

  def get_todo!(id, user_id) do
    case get_todo(id, user_id) do
      {:ok, todo}        -> todo
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Todo
    end
  end

  def new_todo, do: %Todo{}

  def create_todo(user_id, attrs) do
    %Todo{user_id: user_id}
    |> Todo.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_todo(todo, attrs) do
    todo
    |> Todo.update_changeset(attrs)
    |> Repo.update()
  end

  def complete_todo(todo) do
    todo
    |> Todo.update_changeset(%{completed: true})
    |> Repo.update()
  end

  def delete_todo(todo) do
    Repo.delete(todo)
  end

  def change_todo(todo, attrs \\ %{}) do
    Todo.update_changeset(todo, attrs)
  end

  defp maybe_where_category(query, nil), do: query
  defp maybe_where_category(query, cat), do: where(query, category: ^cat)
end
