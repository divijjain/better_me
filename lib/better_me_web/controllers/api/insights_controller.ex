defmodule BetterMeWeb.Api.InsightsController do
  @moduledoc "JSON API for AI insights — ask a question, get a grounded answer."

  use BetterMeWeb, :controller
  alias BetterMe.Insights.InsightWorkflow

  @daily_limit 20

  def ask(conn, %{"question" => question}) do
    user_id = conn.assigns.current_scope.user.id
    question = String.trim(question)

    cond do
      question == "" ->
        conn |> put_status(:bad_request) |> json(%{errors: %{detail: "Question is required"}})

      queries_today(user_id) >= @daily_limit ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{errors: %{detail: "Daily limit of #{@daily_limit} questions reached"}})

      true ->
        increment_queries(user_id)

        case InsightWorkflow.run(user_id, question) do
          {:ok, answer} ->
            json(conn, %{
              data: %{
                answer: answer,
                queries_today: queries_today(user_id),
                daily_limit: @daily_limit
              }
            })

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{errors: %{detail: inspect(reason)}})
        end
    end
  end

  def quota(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    json(conn, %{data: %{queries_today: queries_today(user_id), daily_limit: @daily_limit}})
  end

  defp queries_today(user_id) do
    key = "insight:#{user_id}:#{Date.utc_today()}"
    period = 24 * 60 * 60 * 1_000

    alias BetterMeWeb.Plugs.RateLimit
    alias PlugAttack.Storage.Ets, as: PlugAttackEts

    case PlugAttackEts.increment(RateLimit.Storage, key, period, 0) do
      {count, _} -> max(count - 1, 0)
      _ -> 0
    end
  end

  defp increment_queries(user_id) do
    key = "insight:#{user_id}:#{Date.utc_today()}"
    period = 24 * 60 * 60 * 1_000

    alias BetterMeWeb.Plugs.RateLimit
    alias PlugAttack.Storage.Ets, as: PlugAttackEts

    PlugAttackEts.increment(RateLimit.Storage, key, period, 1)
  end
end
