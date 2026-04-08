defmodule BetterMeWeb.Plugs.RateLimit do
  @moduledoc """
  IP-based rate limiting for auth endpoints using PlugAttack.

  Rules:
  - Password login:  10 attempts per IP per 10 minutes
  - Google OAuth:    20 requests per IP per 10 minutes
  - General browser: 500 requests per IP per minute (DDoS protection)
  """
  use PlugAttack

  # Allow all private/loopback IPs (dev + internal traffic)
  rule "allow local", conn do
    allow(conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}])
  end

  # Strict limit on password login attempts
  rule "login attempts", conn do
    if conn.method == "POST" and conn.request_path == "/users/log-in" do
      throttle(conn.remote_ip,
        period: 10 * 60 * 1_000,
        limit: 10,
        storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
      )
    end
  end

  # Moderate limit on Google OAuth (prevent redirect flooding)
  rule "google oauth", conn do
    if conn.request_path in ["/auth/google", "/auth/google/callback"] do
      throttle(conn.remote_ip,
        period: 10 * 60 * 1_000,
        limit: 20,
        storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
      )
    end
  end

  # General DDoS protection across all browser routes
  rule "general browser", conn do
    throttle(conn.remote_ip,
      period: 60 * 1_000,
      limit: 500,
      storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
    )
  end

  def allow_action(conn, {:throttle, data}, _opts) do
    conn
    |> Plug.Conn.put_resp_header("x-ratelimit-limit", to_string(data[:limit]))
    |> Plug.Conn.put_resp_header("x-ratelimit-remaining", to_string(data[:remaining]))
    |> Plug.Conn.put_resp_header("x-ratelimit-reset", to_string(data[:reset_at]))
  end

  def block_action(conn, {:throttle, _data}, _opts) do
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
