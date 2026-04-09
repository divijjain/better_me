defmodule BetterMe.WorkoutsTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Workouts
  alias BetterMe.Workouts.Schema.{Exercise, ExerciseSet, Workout}

  import BetterMe.Factory

  setup do
    %{user: insert(:user)}
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp workout_fixture(user_id, attrs \\ %{}) do
    attrs = Map.merge(%{date: Date.utc_today(), type: :strength}, attrs)
    {:ok, workout} = Workouts.create_workout(user_id, attrs)
    workout
  end

  defp exercise_fixture(user_id, workout_id, attrs \\ %{}) do
    attrs = Map.merge(%{"name" => "Squat"}, attrs)
    {:ok, exercise, :no_pr} = Workouts.add_exercise(user_id, workout_id, attrs)
    exercise
  end

  defp routine_template_fixture(user_id, attrs \\ %{}) do
    attrs = Map.merge(%{name: "PPL #{System.unique_integer()}"}, attrs)
    {:ok, template} = Workouts.create_routine_template(user_id, attrs)
    template
  end

  defp routine_day_fixture(template_id, attrs \\ %{}) do
    attrs = Map.merge(%{name: "Push", position: 1, routine_template_id: template_id}, attrs)
    {:ok, day} = Workouts.Repository.create_routine_day(template_id, attrs)
    day
  end

  defp routine_exercise_fixture(day_id, attrs \\ %{}) do
    attrs = Map.merge(%{name: "Bench Press", position: 1, working_sets: 4}, attrs)
    {:ok, re} = Workouts.Repository.create_routine_exercise(day_id, attrs)
    re
  end

  # ---------------------------------------------------------------------------
  # Workouts
  # ---------------------------------------------------------------------------

  describe "create_workout/2" do
    test "creates a workout with valid attrs", %{user: user} do
      assert {:ok, workout} =
               Workouts.create_workout(user.id, %{date: Date.utc_today(), type: :strength})

      assert workout.type == :strength
      assert workout.date == Date.utc_today()
      assert workout.user_id == user.id
    end

    test "returns error when date is missing", %{user: user} do
      assert {:error, changeset} = Workouts.create_workout(user.id, %{type: :cardio})
      assert %{date: [_]} = errors_on(changeset)
    end

    test "returns error when type is missing", %{user: user} do
      assert {:error, changeset} =
               Workouts.create_workout(user.id, %{date: Date.utc_today()})

      assert %{type: [_]} = errors_on(changeset)
    end

    test "allows optional notes and duration", %{user: user} do
      attrs = %{date: Date.utc_today(), type: :cardio, duration: 45, notes: "Easy run"}
      assert {:ok, workout} = Workouts.create_workout(user.id, attrs)
      assert workout.duration == 45
      assert workout.notes == "Easy run"
    end
  end

  describe "list_workouts/1" do
    test "returns workouts for the user", %{user: user} do
      workout = workout_fixture(user.id)
      workouts = Workouts.list_workouts(user.id)
      assert Enum.any?(workouts, &(&1.id == workout.id))
    end

    test "does not return workouts from other users", %{user: user} do
      other = insert(:user)
      workout_fixture(other.id)
      workouts = Workouts.list_workouts(user.id)
      assert Enum.all?(workouts, &(&1.user_id == user.id))
    end

    test "returns empty list when user has no workouts", %{user: user} do
      assert Workouts.list_workouts(user.id) == []
    end
  end

  describe "get_workout/2" do
    test "returns {:ok, workout} for valid owner", %{user: user} do
      workout = workout_fixture(user.id)
      assert {:ok, found} = Workouts.get_workout(workout.id, user.id)
      assert found.id == workout.id
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      other = insert(:user)
      workout = workout_fixture(other.id)
      assert {:error, :not_found} = Workouts.get_workout(workout.id, user.id)
    end

    test "returns {:error, :not_found} for nonexistent id", %{user: user} do
      assert {:error, :not_found} = Workouts.get_workout(0, user.id)
    end
  end

  describe "get_workout_with_exercises/2" do
    test "preloads exercises and sets", %{user: user} do
      workout = workout_fixture(user.id)
      exercise_fixture(user.id, workout.id)

      assert {:ok, found} = Workouts.get_workout_with_exercises(workout.id, user.id)
      assert is_list(found.exercises)
      assert length(found.exercises) == 1
    end
  end

  describe "update_workout/2" do
    test "updates type and notes", %{user: user} do
      workout = workout_fixture(user.id)
      assert {:ok, updated} = Workouts.update_workout(workout, %{type: :cardio, notes: "Updated"})
      assert updated.type == :cardio
      assert updated.notes == "Updated"
    end
  end

  describe "delete_workout/1" do
    test "deletes the workout", %{user: user} do
      workout = workout_fixture(user.id)
      assert {:ok, _} = Workouts.delete_workout(workout)
      assert {:error, :not_found} = Workouts.get_workout(workout.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Exercises
  # ---------------------------------------------------------------------------

  describe "add_exercise/3" do
    test "adds an exercise to a workout", %{user: user} do
      workout = workout_fixture(user.id)

      assert {:ok, exercise, :no_pr} =
               Workouts.add_exercise(user.id, workout.id, %{"name" => "Deadlift"})

      assert exercise.name == "Deadlift"
      assert exercise.workout_id == workout.id
    end

    test "returns error when name is missing", %{user: user} do
      workout = workout_fixture(user.id)
      assert {:error, changeset} = Workouts.add_exercise(user.id, workout.id, %{})
      assert %{name: [_]} = errors_on(changeset)
    end
  end

  describe "list_exercises/1" do
    test "returns exercises for the workout", %{user: user} do
      workout = workout_fixture(user.id)
      exercise_fixture(user.id, workout.id)
      exercises = Workouts.list_exercises(workout.id)
      assert length(exercises) == 1
    end
  end

  describe "get_exercise/2" do
    test "returns {:ok, exercise} for valid workout", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)
      assert {:ok, found} = Workouts.get_exercise(exercise.id, workout.id)
      assert found.id == exercise.id
    end

    test "returns {:error, :not_found} for wrong workout", %{user: user} do
      workout = workout_fixture(user.id)
      other_workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)
      assert {:error, :not_found} = Workouts.get_exercise(exercise.id, other_workout.id)
    end
  end

  describe "update_exercise/2" do
    test "updates exercise fields", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)
      assert {:ok, updated} = Workouts.update_exercise(exercise, %{name: "Romanian Deadlift"})
      assert updated.name == "Romanian Deadlift"
    end
  end

  describe "delete_exercise/1" do
    test "deletes the exercise", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)
      assert {:ok, _} = Workouts.delete_exercise(exercise)
      assert {:error, :not_found} = Workouts.get_exercise(exercise.id, workout.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Exercise sets & PR detection
  # ---------------------------------------------------------------------------

  describe "log_set/3" do
    test "logs a set and flags it as :pr when it's the first-ever set with weight", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)

      assert {:ok, set, :pr} =
               Workouts.log_set(user.id, exercise, %{"weight" => 100.0, "reps" => 5})

      assert set.weight == 100.0
      assert set.reps == 5
      assert set.set_number == 1
    end

    test "auto-increments set_number", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)

      {:ok, set1, _} = Workouts.log_set(user.id, exercise, %{"weight" => 80.0, "reps" => 5})
      {:ok, set2, _} = Workouts.log_set(user.id, exercise, %{"weight" => 80.0, "reps" => 5})

      assert set1.set_number == 1
      assert set2.set_number == 2
    end

    test "returns :pr for a new personal best", %{user: user} do
      # First workout with a lighter weight
      workout1 = workout_fixture(user.id)
      exercise1 = exercise_fixture(user.id, workout1.id, %{"name" => "Bench"})
      {:ok, _, _} = Workouts.log_set(user.id, exercise1, %{"weight" => 80.0, "reps" => 5})

      # Second workout with a heavier weight — should be a PR
      workout2 = workout_fixture(user.id)
      exercise2 = exercise_fixture(user.id, workout2.id, %{"name" => "Bench"})

      assert {:ok, set, :pr} =
               Workouts.log_set(user.id, exercise2, %{"weight" => 100.0, "reps" => 5})

      assert set.is_pr == true
    end

    test "does not flag :pr when weight is not higher than previous best", %{user: user} do
      workout1 = workout_fixture(user.id)
      exercise1 = exercise_fixture(user.id, workout1.id, %{"name" => "Press"})
      {:ok, _, _} = Workouts.log_set(user.id, exercise1, %{"weight" => 100.0, "reps" => 5})

      workout2 = workout_fixture(user.id)
      exercise2 = exercise_fixture(user.id, workout2.id, %{"name" => "Press"})

      assert {:ok, _set, :no_pr} =
               Workouts.log_set(user.id, exercise2, %{"weight" => 90.0, "reps" => 5})
    end

    test "returns :no_pr when no weight is given", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)

      assert {:ok, set, :no_pr} = Workouts.log_set(user.id, exercise, %{"reps" => 10})
      assert is_nil(set.weight)
    end
  end

  describe "list_exercise_sets/1" do
    test "returns sets ordered by set_number", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)
      {:ok, _, _} = Workouts.log_set(user.id, exercise, %{"weight" => 50.0, "reps" => 10})
      {:ok, _, _} = Workouts.log_set(user.id, exercise, %{"weight" => 60.0, "reps" => 8})

      sets = Workouts.list_exercise_sets(exercise.id)
      assert length(sets) == 2
      assert hd(sets).set_number == 1
    end
  end

  describe "delete_exercise_set/1" do
    test "deletes the set", %{user: user} do
      workout = workout_fixture(user.id)
      exercise = exercise_fixture(user.id, workout.id)
      {:ok, set, _} = Workouts.log_set(user.id, exercise, %{"weight" => 80.0, "reps" => 5})

      assert {:ok, _} = Workouts.delete_exercise_set(set)
      assert {:error, :not_found} = Workouts.get_exercise_set(set.id, exercise.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Routine templates
  # ---------------------------------------------------------------------------

  describe "create_routine_template/2" do
    test "creates a template with valid attrs", %{user: user} do
      assert {:ok, template} =
               Workouts.create_routine_template(user.id, %{name: "Push Pull Legs"})

      assert template.name == "Push Pull Legs"
      assert template.is_active == true
      assert template.user_id == user.id
    end

    test "returns error when name is missing", %{user: user} do
      assert {:error, changeset} = Workouts.create_routine_template(user.id, %{})
      assert %{name: [_]} = errors_on(changeset)
    end
  end

  describe "list_routine_templates/1" do
    test "returns active templates for the user", %{user: user} do
      template = routine_template_fixture(user.id)
      templates = Workouts.list_routine_templates(user.id)
      assert Enum.any?(templates, &(&1.id == template.id))
    end

    test "does not return templates from other users", %{user: user} do
      other = insert(:user)
      routine_template_fixture(other.id)
      templates = Workouts.list_routine_templates(user.id)
      assert Enum.all?(templates, &(&1.user_id == user.id))
    end
  end

  describe "get_routine_template_with_days/2" do
    test "preloads days with exercises", %{user: user} do
      template = routine_template_fixture(user.id)
      day = routine_day_fixture(template.id)
      routine_exercise_fixture(day.id)

      assert {:ok, found} = Workouts.get_routine_template_with_days(template.id, user.id)
      assert length(found.days) == 1
      assert length(hd(found.days).routine_exercises) == 1
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      other = insert(:user)
      template = routine_template_fixture(other.id)
      assert {:error, :not_found} = Workouts.get_routine_template_with_days(template.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Populate from routine
  # ---------------------------------------------------------------------------

  describe "populate_from_routine/2" do
    test "adds exercises from a routine day to the workout", %{user: user} do
      template = routine_template_fixture(user.id)
      day = routine_day_fixture(template.id)
      routine_exercise_fixture(day.id, %{name: "Bench Press", position: 1})
      routine_exercise_fixture(day.id, %{name: "OHP", position: 2})

      workout = workout_fixture(user.id)

      assert {:ok, :populated} = Workouts.populate_from_routine(workout, day.id)

      exercises = Workouts.list_exercises(workout.id)
      assert length(exercises) == 2
      names = Enum.map(exercises, & &1.name)
      assert "Bench Press" in names
      assert "OHP" in names
    end

    test "returns {:error, :routine_day_not_found} for nonexistent day", %{user: user} do
      workout = workout_fixture(user.id)
      assert {:error, :routine_day_not_found} = Workouts.populate_from_routine(workout, 0)
    end
  end

  # ---------------------------------------------------------------------------
  # Analytics
  # ---------------------------------------------------------------------------

  describe "workout_frequency/2" do
    test "returns weekly counts for recent workouts", %{user: user} do
      workout_fixture(user.id)
      freq = Workouts.workout_frequency(user.id, 8)
      assert is_list(freq)
      assert Enum.all?(freq, &(Map.has_key?(&1, :week) and Map.has_key?(&1, :count)))
    end

    test "returns empty list when user has no workouts", %{user: user} do
      assert Workouts.workout_frequency(user.id) == []
    end
  end

  describe "workout_by_type/2" do
    test "returns type breakdown for recent workouts", %{user: user} do
      workout_fixture(user.id, %{type: :strength})
      workout_fixture(user.id, %{type: :cardio})

      breakdown = Workouts.workout_by_type(user.id)
      assert length(breakdown) == 2
      assert Enum.all?(breakdown, &(Map.has_key?(&1, :type) and Map.has_key?(&1, :count)))
    end
  end

  # ---------------------------------------------------------------------------
  # Changesets
  # ---------------------------------------------------------------------------

  describe "Workout.create_changeset/2" do
    test "invalid for unknown type" do
      user = insert(:user)

      cs =
        Workout.create_changeset(%Workout{}, %{
          date: Date.utc_today(),
          type: :yoga,
          user_id: user.id
        })

      assert %{type: [_]} = errors_on(cs)
    end

    test "valid for all workout types" do
      user = insert(:user)

      for type <- [:strength, :cardio, :flexibility, :sport, :other] do
        cs =
          Workout.create_changeset(%Workout{}, %{
            date: Date.utc_today(),
            type: type,
            user_id: user.id
          })

        assert cs.valid?, "expected valid for type #{type}"
      end
    end

    test "invalid when duration is zero or negative" do
      user = insert(:user)

      for d <- [0, -10] do
        cs =
          Workout.create_changeset(%Workout{}, %{
            date: Date.utc_today(),
            type: :cardio,
            user_id: user.id,
            duration: d
          })

        assert %{duration: [_]} = errors_on(cs), "expected invalid for duration #{d}"
      end
    end
  end

  describe "Exercise.create_changeset/2" do
    test "invalid when name exceeds 100 chars" do
      workout = insert(:workout)

      cs =
        Exercise.create_changeset(%Exercise{}, %{
          name: String.duplicate("a", 101),
          workout_id: workout.id
        })

      assert %{name: [_]} = errors_on(cs)
    end

    test "invalid when sets is zero" do
      workout = insert(:workout)

      cs =
        Exercise.create_changeset(%Exercise{}, %{name: "Squat", workout_id: workout.id, sets: 0})

      assert %{sets: [_]} = errors_on(cs)
    end

    test "invalid when reps is zero" do
      workout = insert(:workout)

      cs =
        Exercise.create_changeset(%Exercise{}, %{name: "Squat", workout_id: workout.id, reps: 0})

      assert %{reps: [_]} = errors_on(cs)
    end

    test "valid when weight is zero (bodyweight)" do
      workout = insert(:workout)

      cs =
        Exercise.create_changeset(%Exercise{}, %{
          name: "Pull-up",
          workout_id: workout.id,
          weight: 0.0
        })

      assert cs.valid?
    end

    test "invalid when weight is negative" do
      workout = insert(:workout)

      cs =
        Exercise.create_changeset(%Exercise{}, %{
          name: "Squat",
          workout_id: workout.id,
          weight: -1.0
        })

      assert %{weight: [_]} = errors_on(cs)
    end

    test "invalid when rpe is out of range" do
      workout = insert(:workout)

      for rpe <- [0, 11] do
        cs =
          Exercise.create_changeset(%Exercise{}, %{
            name: "Squat",
            workout_id: workout.id,
            rpe: rpe
          })

        assert %{rpe: [_]} = errors_on(cs), "expected invalid for rpe #{rpe}"
      end
    end

    test "valid when rpe is at boundaries (1 and 10)" do
      workout = insert(:workout)

      for rpe <- [1, 10] do
        cs =
          Exercise.create_changeset(%Exercise{}, %{
            name: "Squat",
            workout_id: workout.id,
            rpe: rpe
          })

        assert cs.valid?, "expected valid for rpe #{rpe}"
      end
    end
  end

  describe "ExerciseSet.create_changeset/2" do
    test "invalid when weight is negative" do
      exercise = insert(:exercise)

      cs =
        ExerciseSet.create_changeset(%ExerciseSet{}, %{
          set_number: 1,
          exercise_id: exercise.id,
          weight: -5.0
        })

      assert %{weight: [_]} = errors_on(cs)
    end

    test "valid when weight is zero (bodyweight set)" do
      exercise = insert(:exercise)

      cs =
        ExerciseSet.create_changeset(%ExerciseSet{}, %{
          set_number: 1,
          exercise_id: exercise.id,
          weight: 0.0
        })

      assert cs.valid?
    end

    test "invalid when reps is zero or negative" do
      exercise = insert(:exercise)

      for reps <- [0, -1] do
        cs =
          ExerciseSet.create_changeset(%ExerciseSet{}, %{
            set_number: 1,
            exercise_id: exercise.id,
            reps: reps
          })

        assert %{reps: [_]} = errors_on(cs), "expected invalid for reps #{reps}"
      end
    end
  end
end
