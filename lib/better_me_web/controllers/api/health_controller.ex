defmodule BetterMeWeb.Api.HealthController do
  @moduledoc "JSON API for body metrics — list and create (used by HealthKit sync)."

  use BetterMeWeb, :controller
  alias BetterMe.Health

  def index(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    limit = params |> Map.get("limit", "90") |> String.to_integer()
    metrics = Health.list_metrics(user_id, limit: limit)
    json(conn, %{data: Enum.map(metrics, &serialize/1)})
  end

  def create(conn, %{"metric" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    case Health.log_metric(user_id, attrs) do
      {:ok, metric} ->
        conn |> put_status(:created) |> json(%{data: serialize(metric)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  defp serialize(metric) do
    %{
      id: metric.id,
      date: metric.date,
      weight: metric.weight,
      body_fat_pct: metric.body_fat_pct
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
