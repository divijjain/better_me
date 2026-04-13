defmodule BetterMeWeb.Plugs.ApiRateLimit do
  @moduledoc """
  IP-based rate limiting for JSON API endpoints using PlugAttack.

  Rules:
  - API Google auth: 10 requests per IP per 10 minutes
  - API general:     200 requests per IP per minute

  Localhost is always allowed (dev unaffected).
  Reuses the RateLimit ETS storage table (started in Application).
  """
  use PlugAttack
  import Plug.Conn

  rule "allow local", conn do
    allow(conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}])
  end

  rule "api google auth", conn do
    if conn.method == "POST" and conn.request_path == "/api/auth/google" do
      throttle(conn.remote_ip,
        period: 10 * 60 * 1_000,
        limit: 10,
        storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
      )
    end
  end

  rule "api general", conn do
    throttle(conn.remote_ip,
      period: 60 * 1_000,
      limit: 200,
      storage: {PlugAttack.Storage.Ets, BetterMeWeb.Plugs.RateLimit.Storage}
    )
  end

  def allow_action(conn, _data, _opts), do: conn

  def block_action(conn, _data, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(429, ~s({"errors":{"detail":"Too many requests"}}))
    |> halt()
  end
end
