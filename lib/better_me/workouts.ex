defmodule BetterMe.Workouts do
  alias BetterMe.Workouts.Actions.{AddExercise, LogSet, PopulateFromRoutine}
  alias BetterMe.Workouts.Repository

  # Routine Templates
  defdelegate list_routine_templates(user_id), to: Repository
  defdelegate get_routine_template(id, user_id), to: Repository
  defdelegate get_routine_template_with_days(id, user_id), to: Repository
  defdelegate create_routine_template(user_id, attrs), to: Repository

  # Routine Days
  defdelegate list_routine_days(template_id), to: Repository
  defdelegate get_routine_day_with_exercises(day_id), to: Repository

  # Workouts
  defdelegate list_workouts(user_id, opts \\ []), to: Repository
  defdelegate list_workouts_with_routine(user_id, opts \\ []), to: Repository
  defdelegate get_workout(id, user_id), to: Repository
  defdelegate get_workout!(id, user_id), to: Repository
  defdelegate get_workout_with_exercises(id, user_id), to: Repository
  defdelegate new_workout(), to: Repository
  defdelegate create_workout(user_id, attrs), to: Repository
  defdelegate update_workout(workout, attrs), to: Repository
  defdelegate delete_workout(workout), to: Repository
  defdelegate change_workout(workout, attrs \\ %{}), to: Repository

  # Exercises
  defdelegate list_exercises(workout_id), to: Repository
  defdelegate get_exercise(id, workout_id), to: Repository
  defdelegate new_exercise(), to: Repository
  defdelegate add_exercise(user_id, workout_id, attrs), to: AddExercise, as: :run
  defdelegate update_exercise(exercise, attrs), to: Repository
  defdelegate delete_exercise(exercise), to: Repository
  defdelegate change_exercise(exercise, attrs \\ %{}), to: Repository

  # Exercise Sets
  defdelegate list_exercise_sets(exercise_id), to: Repository
  defdelegate get_exercise_set(id, exercise_id), to: Repository
  defdelegate update_exercise_set(set, attrs), to: Repository
  defdelegate delete_exercise_set(set), to: Repository
  defdelegate log_set(user_id, exercise, attrs), to: LogSet, as: :run
  defdelegate populate_from_routine(workout, day_id), to: PopulateFromRoutine, as: :run
end
