defmodule BetterMeWeb.GoogleOAuthController do
  use BetterMeWeb, :controller

  alias BetterMe.Accounts
  alias BetterMeWeb.UserAuth

  @google_auth_url "https://accounts.google.com/o/oauth2/v2/auth"
  @google_token_url "https://oauth2.googleapis.com/token"
  @google_userinfo_url "https://www.googleapis.com/oauth2/v3/userinfo"

  def request(conn, _params) do
    state = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    client_id = Application.fetch_env!(:better_me, :google)[:client_id]
    redirect_uri = callback_url(conn)

    params =
      URI.encode_query(%{
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: "openid email profile",
        state: state,
        access_type: "online"
      })

    conn
    |> put_session(:oauth_state, state)
    |> redirect(external: "#{@google_auth_url}?#{params}")
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    with :ok <- verify_state(conn, state),
         {:ok, token_resp} <- exchange_code(conn, code),
         {:ok, user_info} <- fetch_user_info(token_resp["access_token"]),
         {:ok, user} <-
           Accounts.find_or_create_by_oauth("google", user_info["sub"], user_info["email"]) do
      conn
      |> delete_session(:oauth_state)
      |> put_flash(:info, "Welcome!")
      |> UserAuth.log_in_user(user, %{"remember_me" => "true"})
    else
      {:error, :state_mismatch} ->
        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: ~p"/users/log-in")

      {:error, reason} when is_binary(reason) ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/users/log-in")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not sign in with Google. Please try another method.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Google sign-in was cancelled.")
    |> redirect(to: ~p"/users/log-in")
  end

  defp verify_state(conn, state) do
    if get_session(conn, :oauth_state) == state, do: :ok, else: {:error, :state_mismatch}
  end

  defp exchange_code(conn, code) do
    client_id = Application.fetch_env!(:better_me, :google)[:client_id]
    client_secret = Application.fetch_env!(:better_me, :google)[:client_secret]

    resp =
      Req.post!(@google_token_url,
        form: [
          code: code,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: callback_url(conn),
          grant_type: "authorization_code"
        ]
      )

    if resp.status == 200 do
      {:ok, resp.body}
    else
      {:error, "Failed to exchange Google token."}
    end
  end

  defp fetch_user_info(access_token) do
    resp =
      Req.get!(@google_userinfo_url,
        headers: [{"authorization", "Bearer #{access_token}"}]
      )

    if resp.status == 200 do
      {:ok, resp.body}
    else
      {:error, "Failed to fetch Google user info."}
    end
  end

  defp callback_url(conn) do
    url(conn, ~p"/auth/google/callback")
  end
end
