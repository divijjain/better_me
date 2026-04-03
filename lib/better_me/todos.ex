defmodule BetterMe.Todos do
  alias BetterMe.Todos.Repository

  defdelegate list_todos(user_id, opts \\ []),   to: Repository
  defdelegate get_todo(id, user_id),             to: Repository
  defdelegate get_todo!(id, user_id),            to: Repository
  defdelegate new_todo(),                        to: Repository
  defdelegate create_todo(user_id, attrs),       to: Repository
  defdelegate update_todo(todo, attrs),          to: Repository
  defdelegate complete_todo(todo),               to: Repository
  defdelegate delete_todo(todo),                 to: Repository
  defdelegate change_todo(todo, attrs \\ %{}),   to: Repository
end
