defmodule BetterMe.HabitsTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Habits
  alias BetterMe.Habits.{Habit, HabitLog}

  import BetterMe.Factory

  setup do
    %{user: insert(:user)}
  end

  # ---------------------------------------------------------------------------
  # CRUD
  # ---------------------------------------------------------------------------

  describe "create_habit/2" do
    test "creates a habit with valid attrs", %{user: user} do
      assert {:ok, habit} = Habits.create_habit(user.id, %{name: "Meditate", category: :health})
      assert habit.name == "Meditate"
      assert habit.category == :health
      assert habit.frequency == :daily
      assert habit.active == true
      assert habit.user_id == user.id
    end

    test "returns error changeset when name is missing", %{user: user} do
      assert {:error, changeset} = Habits.create_habit(user.id, %{category: :health})
      assert %{name: [_]} = errors_on(changeset)
    end

    test "returns error changeset when category is missing", %{user: user} do
      assert {:error, changeset} = Habits.create_habit(user.id, %{name: "Run"})
      assert %{category: [_]} = errors_on(changeset)
    end

    test "returns error for invalid category", %{user: user} do
      assert {:error, changeset} =
               Habits.create_habit(user.id, %{name: "Run", category: :invalid})

      assert %{category: [_]} = errors_on(changeset)
    end
  end

  describe "list_habits/1" do
    test "returns habits for the user", %{user: user} do
      habit = insert(:habit, user: user)
      habits = Habits.list_habits(user.id)
      assert Enum.any?(habits, &(&1.id == habit.id))
    end

    test "does not return habits from other users", %{user: user} do
      insert(:habit, user: insert(:user))
      habits = Habits.list_habits(user.id)
      assert Enum.all?(habits, &(&1.user_id == user.id))
    end

    test "returns empty list when user has no habits", %{user: user} do
      assert Habits.list_habits(user.id) == []
    end
  end

  describe "get_habit/2" do
    test "returns {:ok, habit} for existing habit", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, found} = Habits.get_habit(habit.id, user.id)
      assert found.id == habit.id
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      habit = insert(:habit, user: insert(:user))
      assert {:error, :not_found} = Habits.get_habit(habit.id, user.id)
    end

    test "returns {:error, :not_found} for nonexistent id", %{user: user} do
      assert {:error, :not_found} = Habits.get_habit(0, user.id)
    end
  end

  describe "update_habit/2" do
    test "updates name and category", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, updated} = Habits.update_habit(habit, %{name: "Yoga", category: :fitness})
      assert updated.name == "Yoga"
      assert updated.category == :fitness
    end

    test "can deactivate a habit", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, updated} = Habits.update_habit(habit, %{active: false})
      refute updated.active
    end
  end

  describe "delete_habit/1" do
    test "deletes the habit", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, _} = Habits.delete_habit(habit)
      assert {:error, :not_found} = Habits.get_habit(habit.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Logging
  # ---------------------------------------------------------------------------

  describe "log_habit/2" do
    test "logs a habit for today by default", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, log} = Habits.log_habit(habit.id, %{})
      assert log.habit_id == habit.id
      assert log.date == Date.utc_today()
    end

    test "logs a habit for a specific date", %{user: user} do
      habit = insert(:habit, user: user)
      date = Date.add(Date.utc_today(), -1)
      assert {:ok, log} = Habits.log_habit(habit.id, %{date: date})
      assert log.date == date
    end

    test "prevents duplicate log on the same date", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, _} = Habits.log_habit(habit.id, %{date: Date.utc_today()})
      assert {:error, changeset} = Habits.log_habit(habit.id, %{date: Date.utc_today()})
      assert changeset.valid? == false
    end
  end

  describe "logged_today?/2" do
    test "returns false before logging", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, false} = Habits.logged_today?(habit.id, user.id)
    end

    test "returns true after logging today", %{user: user} do
      habit = insert(:habit, user: user)
      insert(:habit_log, habit: habit, date: Date.utc_today())
      assert {:ok, true} = Habits.logged_today?(habit.id, user.id)
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      habit = insert(:habit, user: insert(:user))
      assert {:error, :not_found} = Habits.logged_today?(habit.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Streak
  # ---------------------------------------------------------------------------

  describe "current_streak/2" do
    test "returns 0 for habit with no logs", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, 0} = Habits.current_streak(habit.id, user.id)
    end

    test "returns 1 after logging today", %{user: user} do
      habit = insert(:habit, user: user)
      insert(:habit_log, habit: habit, date: Date.utc_today())
      assert {:ok, 1} = Habits.current_streak(habit.id, user.id)
    end

    test "returns consecutive streak length", %{user: user} do
      habit = insert(:habit, user: user)
      today = Date.utc_today()

      for days_ago <- [0, 1, 2] do
        Habits.log_habit(habit.id, %{date: Date.add(today, -days_ago)})
      end

      assert {:ok, 3} = Habits.current_streak(habit.id, user.id)
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      habit = insert(:habit, user: insert(:user))
      assert {:error, :not_found} = Habits.current_streak(habit.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Recent logs
  # ---------------------------------------------------------------------------

  describe "recent_logs/3" do
    test "returns empty list for habit with no logs", %{user: user} do
      habit = insert(:habit, user: user)
      assert {:ok, []} = Habits.recent_logs(habit.id, user.id)
    end

    test "returns logs within the default 30-day window", %{user: user} do
      habit = insert(:habit, user: user)
      insert(:habit_log, habit: habit, date: Date.utc_today())
      assert {:ok, [log]} = Habits.recent_logs(habit.id, user.id)
      assert log.habit_id == habit.id
    end

    test "excludes logs older than the window", %{user: user} do
      habit = insert(:habit, user: user)
      old_date = Date.add(Date.utc_today(), -60)
      Habits.log_habit(habit.id, %{date: old_date})
      assert {:ok, []} = Habits.recent_logs(habit.id, user.id, 30)
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      habit = insert(:habit, user: insert(:user))
      assert {:error, :not_found} = Habits.recent_logs(habit.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # List with meta
  # ---------------------------------------------------------------------------

  describe "list_habits_with_meta/1" do
    test "returns habits with streak and logged_today fields", %{user: user} do
      habit = insert(:habit, user: user)
      insert(:habit_log, habit: habit, date: Date.utc_today())

      assert {:ok, [meta]} = Habits.list_habits_with_meta(user.id)
      assert meta.id == habit.id
      assert meta.streak >= 1
      assert meta.logged_today == true
    end

    test "returns empty list for user with no habits", %{user: user} do
      assert {:ok, []} = Habits.list_habits_with_meta(user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Habit stats
  # ---------------------------------------------------------------------------

  describe "habit_stats/2" do
    test "returns stats struct for valid habit", %{user: user} do
      habit = insert(:habit, user: user)
      insert(:habit_log, habit: habit, date: Date.utc_today())

      assert {:ok, stats} = Habits.habit_stats(habit.id, user.id)
      assert stats.habit.id == habit.id
      assert is_integer(stats.current_streak)
      assert is_integer(stats.longest_streak)
      assert is_struct(stats.calendar_dates, MapSet) or is_list(stats.calendar_dates)
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      habit = insert(:habit, user: insert(:user))
      assert {:error, :not_found} = Habits.habit_stats(habit.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Changesets
  # ---------------------------------------------------------------------------

  describe "Habit.create_changeset/2" do
    test "valid with required fields" do
      changeset = Habit.create_changeset(%Habit{}, %{name: "Run", category: :health})
      assert changeset.valid?
    end

    test "invalid without name" do
      changeset = Habit.create_changeset(%Habit{}, %{category: :health})
      assert %{name: [_]} = errors_on(changeset)
    end

    test "invalid without category" do
      changeset = Habit.create_changeset(%Habit{}, %{name: "Run"})
      assert %{category: [_]} = errors_on(changeset)
    end

    test "invalid when name exceeds 100 chars" do
      changeset =
        Habit.create_changeset(%Habit{}, %{name: String.duplicate("a", 101), category: :health})

      assert %{name: [_]} = errors_on(changeset)
    end

    test "invalid for unknown category" do
      changeset = Habit.create_changeset(%Habit{}, %{name: "Run", category: :unknown})
      assert %{category: [_]} = errors_on(changeset)
    end

    test "valid for all allowed categories" do
      for cat <- [:health, :fitness, :personal, :learning, :work, :misc] do
        changeset = Habit.create_changeset(%Habit{}, %{name: "Habit", category: cat})
        assert changeset.valid?, "expected valid for category #{cat}"
      end
    end

    test "defaults frequency to :daily" do
      changeset = Habit.create_changeset(%Habit{}, %{name: "Run", category: :health})
      assert Ecto.Changeset.get_field(changeset, :frequency) == :daily
    end
  end

  describe "Habit.update_changeset/2" do
    test "can set active to false" do
      habit = insert(:habit)
      changeset = Habit.update_changeset(habit, %{active: false})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :active) == false
    end

    test "invalid without name" do
      habit = insert(:habit)
      changeset = Habit.update_changeset(habit, %{name: ""})
      assert %{name: [_]} = errors_on(changeset)
    end
  end

  describe "HabitLog changeset" do
    test "invalid without date" do
      habit = insert(:habit)
      changeset = HabitLog.changeset(%HabitLog{habit_id: habit.id}, %{})
      assert %{date: [_]} = errors_on(changeset)
    end

    test "valid with date" do
      habit = insert(:habit)
      changeset = HabitLog.changeset(%HabitLog{habit_id: habit.id}, %{date: Date.utc_today()})
      assert changeset.valid?
    end
  end
end
