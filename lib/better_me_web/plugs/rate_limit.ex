defmodule BetterMeWeb.Plugs.RateLimit do
  @moduledoc """
  IP-based rate limiting for auth endpoints using PlugAttack.

  Rules:
  - Password login:  10 attempts per IP per 10 minutes
  - Google OAuth:    20 requests per IP per 10 minutes
  - General browser: 500 requests per IP per minute (DDoS protection)

  Localhost is always allowed (dev unaffected).
  """
  use PlugAttack

  rule "allow local", conn do
    allow(conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}])
  end

  rule "login attempts", conn do
    if conn.method == "POST" and conn.request_path == "/users/log-in" do
      throttle(conn.remote_ip,
        period: 10 * 60 * 1_000,
        limit: 10,
        storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
      )
    end
  end

  rule "google oauth", conn do
    if conn.request_path in ["/auth/google", "/auth/google/callback"] do
      throttle(conn.remote_ip,
        period: 10 * 60 * 1_000,
        limit: 20,
        storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
      )
    end
  end

  rule "general browser", conn do
    throttle(conn.remote_ip,
      period: 60 * 1_000,
      limit: 500,
      storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
    )
  end

  def allow_action(conn, _data, _opts), do: conn

  def block_action(conn, _data, _opts) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(429, """
    <html>
    <body style="font-family:sans-serif;text-align:center;padding:60px">
      <h1>Too many requests</h1>
      <p>Please wait a moment before trying again.</p>
      <a href="/">Go back</a>
    </body>
    </html>
    """)
    |> Plug.Conn.halt()
  end
end
