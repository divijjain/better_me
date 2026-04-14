defmodule BetterMeWeb.UserSocket do
  @moduledoc """
  WebSocket entry point for the mobile Expo app.

  Authenticates via a Base64url-encoded Phoenix session token passed in the
  `token` connect param — the same token returned by POST /api/auth/google.

  Topics:
    "habits:<user_id>"   → HabitsChannel
    "workout:<id>"       → WorkoutChannel
    "health:<user_id>"   → HealthChannel
  """

  use Phoenix.Socket
  alias BetterMe.Accounts

  channel "workout:*", BetterMeWeb.WorkoutChannel
  channel "health:*", BetterMeWeb.HealthChannel

  @impl true
  def connect(%{"token" => encoded}, socket, _connect_info) do
    with {:ok, raw} <- Base.url_decode64(encoded, padding: false),
         {user, _inserted_at} <- Accounts.get_user_by_session_token(raw) do
      {:ok, assign(socket, :current_user, user)}
    else
      _ -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
