defmodule BetterMe.Seeds.Users do
  @moduledoc "Seed dev users."

  alias BetterMe.Accounts

  def run do
    IO.puts("\n--- Seeding users ---")

    Enum.each(
      [
        %{email: "divij@better.me", password: "betterme2026!"},
        %{email: "test@better.me", password: "betterme2026!"}
      ],
      fn attrs ->
        case Accounts.register_user(attrs) do
          {:ok, user} -> IO.puts("  Created: #{user.email}")
          {:error, _} -> IO.puts("  Skipped (already exists): #{attrs.email}")
        end
      end
    )
  end
end
