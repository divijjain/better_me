defmodule BetterMeWeb.Plugs.RateLimitTest do
  use BetterMeWeb.ConnCase, async: false

  alias BetterMeWeb.Plugs.RateLimit

  # Generate a unique non-localhost IP per test to avoid shared ETS state
  defp unique_ip do
    n = System.unique_integer([:positive])
    {rem(n, 254) + 1, rem(n + 1, 254) + 1, rem(n + 2, 254) + 1, rem(n + 3, 254) + 1}
  end

  defp with_ip(conn, ip), do: %{conn | remote_ip: ip}

  describe "normal requests" do
    test "passes through a GET request without halting" do
      ip = unique_ip()

      conn =
        build_conn(:get, "/habits")
        |> with_ip(ip)
        |> RateLimit.call([])

      refute conn.halted
    end
  end

  describe "login throttle" do
    test "allows POST /users/log-in within limit" do
      ip = unique_ip()

      conn =
        build_conn(:post, "/users/log-in")
        |> with_ip(ip)
        |> RateLimit.call([])

      refute conn.halted
    end

    test "blocks POST /users/log-in after 10 attempts from same IP" do
      ip = unique_ip()

      for _ <- 1..10 do
        build_conn(:post, "/users/log-in")
        |> with_ip(ip)
        |> RateLimit.call([])
      end

      conn =
        build_conn(:post, "/users/log-in")
        |> with_ip(ip)
        |> RateLimit.call([])

      assert conn.halted
      assert conn.status == 429
    end

    test "does not block POST /users/log-in from a different IP" do
      ip1 = unique_ip()
      ip2 = unique_ip()

      for _ <- 1..10 do
        build_conn(:post, "/users/log-in")
        |> with_ip(ip1)
        |> RateLimit.call([])
      end

      conn =
        build_conn(:post, "/users/log-in")
        |> with_ip(ip2)
        |> RateLimit.call([])

      refute conn.halted
    end
  end

  describe "google oauth throttle" do
    test "allows GET /auth/google within limit" do
      ip = unique_ip()

      conn =
        build_conn(:get, "/auth/google")
        |> with_ip(ip)
        |> RateLimit.call([])

      refute conn.halted
    end
  end

  describe "localhost bypass" do
    test "always allows localhost even beyond login limit" do
      localhost = {127, 0, 0, 1}

      for _ <- 1..15 do
        conn =
          build_conn(:post, "/users/log-in")
          |> with_ip(localhost)
          |> RateLimit.call([])

        refute conn.halted
      end
    end
  end
end
