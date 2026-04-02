defmodule BetterMe.Habits.Repository do
  import Ecto.Query

  alias BetterMe.Repo
  alias BetterMe.Habits.{Habit, HabitLog}

  # ---------------------------------------------------------------------------
  # Habits CRUD
  # ---------------------------------------------------------------------------

  def list_habits(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    Habit
    |> where(user_id: ^user_id, active: true)
    |> order_by([h], asc: h.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_habit(id, user_id) do
    case Repo.get_by(Habit, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      habit -> {:ok, habit}
    end
  end

  def get_habit!(id, user_id) do
    case get_habit(id, user_id) do
      {:ok, habit} -> habit
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Habit
    end
  end

  def new_habit, do: %Habit{}

  def create_habit(user_id, attrs) do
    %Habit{user_id: user_id}
    |> Habit.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_habit(habit, attrs) do
    habit
    |> Habit.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_habit(habit) do
    Repo.delete(habit)
  end

  def change_habit(habit, attrs \\ %{}) do
    Habit.create_changeset(habit, attrs)
  end

  def insert_log(habit_id, attrs) do
    %HabitLog{habit_id: habit_id}
    |> HabitLog.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Raw log queries — used by action modules, not called directly from outside
  # ---------------------------------------------------------------------------

  def get_log_dates(habit_id) do
    HabitLog
    |> where(habit_id: ^habit_id, completed: true)
    |> select([l], l.date)
    |> Repo.all()
  end

  def list_recent_logs(habit_id, since) do
    HabitLog
    |> where(habit_id: ^habit_id)
    |> where([l], l.date >= ^since)
    |> order_by([l], desc: l.date)
    |> Repo.all()
  end

  def exists_log_today?(habit_id) do
    today = Date.utc_today()
    Repo.exists?(from l in HabitLog, where: l.habit_id == ^habit_id and l.date == ^today)
  end

  # ---------------------------------------------------------------------------
  # Bulk helpers — used by Actions.ListWithMeta
  # ---------------------------------------------------------------------------

  def streak_map_for([]), do: %{}

  def streak_map_for(habit_ids) do
    HabitLog
    |> where([l], l.habit_id in ^habit_ids and l.completed == true)
    |> select([l], {l.habit_id, l.date})
    |> Repo.all()
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  def logged_today_set_for([]), do: MapSet.new()

  def logged_today_set_for(habit_ids) do
    today = Date.utc_today()

    HabitLog
    |> where([l], l.habit_id in ^habit_ids and l.date == ^today)
    |> select([l], l.habit_id)
    |> Repo.all()
    |> MapSet.new()
  end
end
