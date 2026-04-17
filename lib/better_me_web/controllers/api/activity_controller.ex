defmodule BetterMeWeb.Api.ActivityController do
  @moduledoc "JSON API for daily activity logs — list and upsert (used by HealthKit sync and manual entry)."

  use BetterMeWeb, :controller
  alias BetterMe.Health

  def index(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    limit = params |> Map.get("limit", "90") |> String.to_integer()
    logs = Health.list_activity(user_id, limit: limit)
    json(conn, %{data: Enum.map(logs, &serialize/1)})
  end

  def create(conn, %{"activity" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    case Health.log_activity(user_id, attrs) do
      {:ok, log} ->
        conn |> put_status(:created) |> json(%{data: serialize(log)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  defp serialize(log) do
    %{
      id: log.id,
      date: log.date,
      steps: log.steps,
      active_kcal: log.active_kcal,
      resting_hr_bpm: log.resting_hr_bpm,
      sleep_minutes: log.sleep_minutes
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
