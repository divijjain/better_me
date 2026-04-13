defmodule BetterMeWeb.Api.JournalController do
  @moduledoc "JSON API for journal entries — list, create, update, delete."

  use BetterMeWeb, :controller
  alias BetterMe.Journals

  def index(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    entries = Journals.list_entries(user_id)
    json(conn, %{data: Enum.map(entries, &serialize/1)})
  end

  def create(conn, %{"entry" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    case Journals.create_entry(user_id, attrs) do
      {:ok, entry} ->
        conn |> put_status(:created) |> json(%{data: serialize(entry)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "entry" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    with {:ok, entry} <- Journals.get_entry(id, user_id),
         {:ok, updated} <- Journals.update_entry(entry, attrs) do
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

    with {:ok, entry} <- Journals.get_entry(id, user_id),
         {:ok, _} <- Journals.delete_entry(entry) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{errors: %{detail: "Not found"}})
    end
  end

  defp serialize(entry) do
    %{
      id: entry.id,
      date: entry.date,
      body: entry.body,
      mood: entry.mood,
      tags: entry.tags
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
