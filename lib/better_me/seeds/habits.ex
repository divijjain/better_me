defmodule BetterMe.Seeds.Habits do
  @moduledoc "Seed sample habits and logs for the primary user."

  alias BetterMe.Accounts
  alias BetterMe.Habits
  alias BetterMe.Habits.Habit
  alias BetterMe.Repo
  import Ecto.Query

  def run do
    IO.puts("\n--- Seeding habits ---")

    case Accounts.get_user_by_email("divij@better.me") do
      nil ->
        IO.puts("  Skipped — primary user not found")

      user ->
        today = Date.utc_today()
        Enum.each(seeds(), &upsert_habit(&1, user, today))
    end
  end

  defp upsert_habit(seed, user, today) do
    attrs = Map.take(seed, [:name, :category, :frequency])
    exists = Repo.exists?(from h in Habit, where: h.name == ^attrs.name and h.user_id == ^user.id)

    if exists do
      IO.puts("  Skipped (already exists): #{attrs.name}")
    else
      {:ok, habit} = Habits.create_habit(user.id, attrs)

      Enum.each(seed.log_days, fn days_ago ->
        Habits.log_habit(habit.id, %{date: Date.add(today, -days_ago), completed: true})
      end)

      IO.puts("  Created: #{habit.name} (#{length(seed.log_days)} logs)")
    end
  end

  defp seeds do
    [
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
      %{name: "No sugar", category: :health, frequency: :daily, log_days: Enum.to_list(0..20)}
    ]
  end
end
