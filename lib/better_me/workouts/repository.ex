defmodule BetterMe.Workouts.Repository do
  import Ecto.Query

  alias BetterMe.Repo

  alias BetterMe.Workouts.Schema.{
    Exercise,
    ExerciseSet,
    RoutineDay,
    RoutineExercise,
    RoutineTemplate,
    Workout
  }

  # ---------------------------------------------------------------------------
  # Routine Templates
  # ---------------------------------------------------------------------------

  def list_routine_templates(user_id) do
    RoutineTemplate
    |> where(user_id: ^user_id, is_active: true)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def get_routine_template(id, user_id) do
    case Repo.get_by(RoutineTemplate, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      template -> {:ok, template}
    end
  end

  def get_routine_template_with_days(id, user_id) do
    case Repo.get_by(RoutineTemplate, id: id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      template ->
        {:ok, Repo.preload(template, days: :routine_exercises)}
    end
  end

  def create_routine_template(user_id, attrs) do
    %RoutineTemplate{user_id: user_id}
    |> RoutineTemplate.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Routine Days
  # ---------------------------------------------------------------------------

  def list_routine_days(template_id) do
    RoutineDay
    |> where(routine_template_id: ^template_id)
    |> order_by([d], asc: d.position)
    |> Repo.all()
  end

  def get_routine_day_with_exercises(day_id) do
    case Repo.get(RoutineDay, day_id) do
      nil -> {:error, :not_found}
      day -> {:ok, Repo.preload(day, :routine_exercises)}
    end
  end

  def create_routine_day(template_id, attrs) do
    %RoutineDay{routine_template_id: template_id}
    |> RoutineDay.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Routine Exercises
  # ---------------------------------------------------------------------------

  def create_routine_exercise(day_id, attrs) do
    %RoutineExercise{routine_day_id: day_id}
    |> RoutineExercise.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------------------------------------------------------
  # Workouts
  # ---------------------------------------------------------------------------

  def list_workouts(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Workout
    |> where(user_id: ^user_id)
    |> order_by([w], desc: w.date, desc: w.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_workouts_with_routine(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Workout
    |> where(user_id: ^user_id)
    |> order_by([w], desc: w.date, desc: w.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(:routine_day)
  end

  def get_workout(id, user_id) do
    case Repo.get_by(Workout, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      workout -> {:ok, workout}
    end
  end

  def get_workout!(id, user_id) do
    case get_workout(id, user_id) do
      {:ok, workout} -> workout
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Workout
    end
  end

  def get_workout_with_exercises(id, user_id) do
    case Repo.get_by(Workout, id: id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      workout ->
        {:ok, Repo.preload(workout, exercises: :exercise_sets, routine_day: :routine_exercises)}
    end
  end

  def new_workout, do: %Workout{date: Date.utc_today()}

  def create_workout(user_id, attrs) do
    %Workout{user_id: user_id}
    |> Workout.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_workout(workout, attrs) do
    workout
    |> Workout.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_workout(workout) do
    Repo.delete(workout)
  end

  def change_workout(workout, attrs \\ %{}) do
    Workout.update_changeset(workout, attrs)
  end

  # ---------------------------------------------------------------------------
  # Exercises
  # ---------------------------------------------------------------------------

  def list_exercises(workout_id) do
    Exercise
    |> where(workout_id: ^workout_id)
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end

  def get_exercise(id, workout_id) do
    case Repo.get_by(Exercise, id: id, workout_id: workout_id) do
      nil -> {:error, :not_found}
      exercise -> {:ok, exercise}
    end
  end

  def new_exercise, do: %Exercise{}

  def add_exercise(workout_id, attrs) do
    %Exercise{workout_id: workout_id}
    |> Exercise.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_exercise(exercise, attrs) do
    exercise
    |> Exercise.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_exercise(exercise) do
    Repo.delete(exercise)
  end

  def change_exercise(exercise, attrs \\ %{}) do
    Exercise.update_changeset(exercise, attrs)
  end

  # ---------------------------------------------------------------------------
  # Exercise Sets
  # ---------------------------------------------------------------------------

  def list_exercise_sets(exercise_id) do
    ExerciseSet
    |> where(exercise_id: ^exercise_id)
    |> order_by([s], asc: s.set_number)
    |> Repo.all()
  end

  def get_exercise_set(id, exercise_id) do
    case Repo.get_by(ExerciseSet, id: id, exercise_id: exercise_id) do
      nil -> {:error, :not_found}
      set -> {:ok, set}
    end
  end

  def add_exercise_set(exercise_id, attrs) do
    %ExerciseSet{exercise_id: exercise_id}
    |> ExerciseSet.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_exercise_set(set, attrs) do
    set
    |> ExerciseSet.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_exercise_set(set) do
    Repo.delete(set)
  end

  def next_set_number(exercise_id) do
    ExerciseSet
    |> where(exercise_id: ^exercise_id)
    |> select([s], count(s.id))
    |> Repo.one()
    |> Kernel.+(1)
  end

  # ---------------------------------------------------------------------------
  # PR queries
  # ---------------------------------------------------------------------------

  # Returns the previous best weight for this exercise name scoped to the user,
  # excluding the current workout. Used by DetectPR action.
  def previous_best(user_id, exercise_name, exclude_workout_id) do
    ExerciseSet
    |> join(:inner, [s], e in Exercise, on: s.exercise_id == e.id)
    |> join(:inner, [_s, e], w in Workout, on: e.workout_id == w.id)
    |> where([_s, _e, w], w.user_id == ^user_id)
    |> where([_s, e, _w], e.name == ^exercise_name)
    |> where([_s, e, _w], e.workout_id != ^exclude_workout_id)
    |> select([s, _e, _w], max(s.weight))
    |> Repo.one()
  end

  def mark_as_pr(exercise) do
    exercise
    |> Exercise.update_changeset(%{is_pr: true})
    |> Repo.update()
  end

  def mark_set_as_pr(set) do
    set
    |> ExerciseSet.update_changeset(%{is_pr: true})
    |> Repo.update()
  end

  def workout_frequency(user_id, weeks \\ 8) do
    since = Date.add(Date.utc_today(), -(weeks * 7))

    Repo.all(
      from w in Workout,
        where: w.user_id == ^user_id and w.date >= ^since,
        group_by: fragment("date_trunc('week', ?::timestamp)", w.date),
        order_by: fragment("date_trunc('week', ?::timestamp)", w.date),
        select: %{
          week: fragment("date_trunc('week', ?::timestamp)::date", w.date),
          count: count(w.id)
        }
    )
  end

  def workout_by_type(user_id, days \\ 30) do
    since = Date.add(Date.utc_today(), -days)

    Repo.all(
      from w in Workout,
        where: w.user_id == ^user_id and w.date >= ^since,
        group_by: w.type,
        order_by: [desc: count(w.id)],
        select: %{type: w.type, count: count(w.id)}
    )
  end
end
