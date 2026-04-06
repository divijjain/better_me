import Ecto.Query
alias BetterMe.{Accounts, Habits, Repo}
alias BetterMe.Habits.Habit

primary_user = Accounts.get_user_by_email("divij@better.me")

unless primary_user do
  IO.puts("  Skipped habits — primary user not found")
  System.halt(0)
end

habit_seeds = [
  %{
    name: "Morning run",
    category: :fitness,
    frequency: :daily,
    log_days: Enum.to_list(0..13)
  },
  %{
    name: "Read 30 mins",
    category: :learning,
    frequency: :daily,
    log_days: [0, 1, 2, 4, 5, 6, 7, 9, 10, 11]
  },
  %{
    name: "Meditate",
    category: :health,
    frequency: :daily,
    log_days: [0, 2, 5, 8, 12, 15, 20]
  },
  %{
    name: "No sugar",
    category: :health,
    frequency: :daily,
    log_days: Enum.to_list(0..20)
  }
]

today = Date.utc_today()

IO.puts("\n--- Seeding habits ---")

Enum.each(habit_seeds, fn seed ->
  attrs = Map.take(seed, [:name, :category, :frequency])

  exists = Repo.exists?(from h in Habit, where: h.name == ^attrs.name and h.user_id == ^primary_user.id)

  case exists do
    false ->
      {:ok, habit} = Habits.create_habit(primary_user.id, attrs)
      IO.puts("  Created: #{habit.name}")

      Enum.each(seed.log_days, fn days_ago ->
        date = Date.add(today, -days_ago)
        Habits.log_habit(habit.id, %{date: date, completed: true})
      end)

      IO.puts("    Logged #{length(seed.log_days)} days")

    true ->
      IO.puts("  Skipped (already exists): #{attrs.name}")
  end
end)
