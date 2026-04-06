alias BetterMe.Accounts

users = [
  %{email: "divij@better.me", password: "betterme2026!"},
  %{email: "test@better.me", password: "betterme2026!"}
]

IO.puts("\n--- Seeding users ---")

Enum.each(users, fn attrs ->
  case Accounts.register_user(attrs) do
    {:ok, user} -> IO.puts("  Created: #{user.email}")
    {:error, _} -> IO.puts("  Skipped (already exists): #{attrs.email}")
  end
end)
