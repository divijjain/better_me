# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias BetterMe.Accounts
alias BetterMe.Habits

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

users = [
  %{email: "divij@better.me", password: "betterme2026!"},
  %{email: "test@better.me", password: "betterme2026!"}
]

created_users =
  Enum.map(users, fn attrs ->
    case Accounts.register_user(attrs) do
      {:ok, user} ->
        IO.puts("Created user: #{user.email}")
        user

      {:error, _} ->
        IO.puts("Skipped (already exists): #{attrs.email}")
        Accounts.get_user_by_email(attrs.email)
    end
  end)

primary_user = hd(created_users)

# ---------------------------------------------------------------------------
# Habits + log history for primary user
# ---------------------------------------------------------------------------

habit_seeds = [
  %{
    name: "Morning run",
    category: :fitness,
    frequency: :daily,
    # logged every day for last 14 days
    log_days: Enum.to_list(0..13)
  },
  %{
    name: "Read 30 mins",
    category: :learning,
    frequency: :daily,
    # logged most days, missed a few
    log_days: [0, 1, 2, 4, 5, 6, 7, 9, 10, 11]
  },
  %{
    name: "Meditate",
    category: :health,
    frequency: :daily,
    # sporadic
    log_days: [0, 2, 5, 8, 12, 15, 20]
  },
  %{
    name: "No sugar",
    category: :health,
    frequency: :daily,
    # strong streak
    log_days: Enum.to_list(0..20)
  }
]

today = Date.utc_today()

Enum.each(habit_seeds, fn seed ->
  attrs = Map.take(seed, [:name, :category, :frequency])

  case Habits.create_habit(primary_user.id, attrs) do
    {:ok, habit} ->
      IO.puts("Created habit: #{habit.name}")

      Enum.each(seed.log_days, fn days_ago ->
        date = Date.add(today, -days_ago)

        case Habits.log_habit(habit.id, %{date: date, completed: true}) do
          {:ok, _} -> :ok
          {:error, _} -> :ok
        end
      end)

      IO.puts("  Logged #{length(seed.log_days)} days for #{habit.name}")

    {:error, changeset} ->
      IO.puts("Failed to create habit #{seed.name}: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\nDone. Login at /users/log-in with divij@better.me")
IO.puts("Check mailbox at /dev/mailbox for the magic link.")
