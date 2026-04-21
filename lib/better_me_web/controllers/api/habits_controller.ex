defmodule BetterMeWeb.Api.HabitsController do
  @moduledoc "JSON API for habits — list, create, and log completion."

  use BetterMeWeb, :controller
  alias BetterMe.Habits

  def index(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    {:ok, habits} = Habits.list_habits_with_meta(user_id)
    json(conn, %{data: Enum.map(habits, &serialize/1)})
  end

  def create(conn, %{"habit" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    case Habits.create_habit(user_id, attrs) do
      {:ok, habit} ->
        conn |> put_status(:created) |> json(%{data: serialize(habit)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "habit" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    with {:ok, habit} <- Habits.get_habit(id, user_id),
         {:ok, updated} <- Habits.update_habit(habit, attrs) do
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

    with {:ok, habit} <- Habits.get_habit(id, user_id),
         {:ok, _} <- Habits.delete_habit(habit) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{errors: %{detail: "Not found"}})
    end
  end

  def log(conn, %{"habit_id" => habit_id} = params) do
    attrs = if params["date"], do: %{date: params["date"]}, else: %{}

    case Habits.log_habit(habit_id, attrs) do
      {:ok, log} ->
        conn |> put_status(:created) |> json(%{data: %{id: log.id, habit_id: log.habit_id}})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  defp serialize(habit) do
    %{
      id: habit.id,
      name: habit.name,
      category: habit.category,
      frequency: habit.frequency,
      streak: Map.get(habit, :current_streak, nil),
      logged_today: Map.get(habit, :logged_today, nil)
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
