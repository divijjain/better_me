defmodule BetterMeWeb.Plugs.BearerAuth do
  @moduledoc """
  Authenticates API requests via a Bearer token in the Authorization header.

  The token is a Base64url-encoded Phoenix session token (raw binary from
  `Accounts.generate_user_session_token/1`). On success, assigns
  `:current_scope` to the conn — matching the pattern used by LiveView auth.
  """

  import Plug.Conn
  alias BetterMe.Accounts
  alias BetterMe.Accounts.Scope

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> encoded] <- get_req_header(conn, "authorization"),
         {:ok, raw} <- Base.url_decode64(encoded, padding: false),
         {user, _inserted_at} <- Accounts.get_user_by_session_token(raw) do
      assign(conn, :current_scope, Scope.for_user(user))
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{errors: %{detail: "Unauthorized"}})
        |> halt()
    end
  end
end
