defmodule BetterMeWeb.Api.AuthController do
  @moduledoc """
  Handles mobile OAuth authentication.

  POST /api/auth/google
    Verifies a Google id_token (from expo-auth-session) via the tokeninfo endpoint,
    finds or creates the user via Google OAuth, and returns a Base64url-encoded
    Phoenix session token for use as a Bearer token on subsequent API requests.
  """

  use BetterMeWeb, :controller
  alias BetterMe.Accounts

  @token_info_url "https://oauth2.googleapis.com/tokeninfo"

  def google(conn, params) do
    google_cfg = Application.fetch_env!(:better_me, :google)

    valid_client_ids =
      [google_cfg[:client_id], google_cfg[:ios_client_id], google_cfg[:android_client_id]]
      |> Enum.reject(&is_nil/1)

    with {:ok, claims} <- verify_google_token(params, valid_client_ids),
         {:ok, user} <- Accounts.find_or_create_by_oauth("google", claims["sub"], claims["email"]) do
      raw_token = Accounts.generate_user_session_token(user)
      encoded = Base.url_encode64(raw_token, padding: false)
      json(conn, %{token: encoded, user: %{id: user.id, email: user.email}})
    else
      {:error, reason} when is_binary(reason) ->
        conn |> put_status(:unauthorized) |> json(%{errors: %{detail: reason}})

      _ ->
        conn |> put_status(:unauthorized) |> json(%{errors: %{detail: "Authentication failed"}})
    end
  end

  defp verify_google_token(%{"id_token" => id_token}, valid_client_ids) do
    resp = Req.get!(@token_info_url, params: [id_token: id_token])
    check_token_response(resp, valid_client_ids)
  end

  defp verify_google_token(%{"access_token" => access_token}, _valid_client_ids) do
    # Access tokens from native OAuth (expo-auth-session) — verify via userinfo
    resp =
      Req.get!("https://www.googleapis.com/oauth2/v3/userinfo",
        headers: [{"Authorization", "Bearer #{access_token}"}]
      )

    case resp.status do
      200 ->
        body = resp.body

        if body["sub"] && body["email"] do
          {:ok, body}
        else
          {:error, "Invalid access token"}
        end

      _ ->
        {:error, "Invalid Google access token"}
    end
  end

  defp verify_google_token(_params, _valid_client_ids) do
    {:error, "id_token or access_token required"}
  end

  defp check_token_response(resp, valid_client_ids) do
    case resp.status do
      200 ->
        if resp.body["aud"] in valid_client_ids do
          {:ok, resp.body}
        else
          {:error, "Invalid token audience"}
        end

      _ ->
        {:error, "Invalid Google token"}
    end
  end
end
