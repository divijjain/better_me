defmodule BetterMeWeb.WorkoutChannel do
  @moduledoc """
  Real-time workout tracking for the Expo app.

  Topic: "workout:<workout_id>"

  Joins are authorized only if the workout belongs to the connected user.
  On join, the current workout (with exercises and sets) is returned as the join reply.

  Client → Server:
    "add_exercise"  %{"name" => ..., ...exercise attrs...}
                    → adds exercise, broadcasts "exercise_added" to all topic subscribers

    "log_set"       %{"exercise_id" => id, "weight" => ..., "reps" => ...}
                    → logs the set, broadcasts "set_logged" with pr: true/false

  Server → Client:
    "exercise_added"  %{exercise: %{...}}
    "set_logged"      %{set: %{...}, pr: bool}
                      pushed when a set is logged (from channel OR from REST API via PubSub)
  """

  use Phoenix.Channel
  alias BetterMe.Workouts

  @impl true
  def join("workout:" <> workout_id_str, _params, socket) do
    user_id = socket.assigns.current_user.id
    workout_id = String.to_integer(workout_id_str)

    case Workouts.get_workout_with_exercises(workout_id, user_id) do
      {:ok, workout} ->
        :ok = Phoenix.PubSub.subscribe(BetterMe.PubSub, "workout:#{workout_id}")
        {:ok, serialize_workout(workout), socket}

      {:error, :not_found} ->
        {:error, %{reason: "not_found"}}
    end
  end

  @impl true
  def handle_in("add_exercise", params, socket) do
    user_id = socket.assigns.current_user.id
    workout_id = workout_id_from_topic(socket.topic)

    case Workouts.add_exercise(user_id, workout_id, params) do
      {:ok, exercise, _pr_flag} ->
        broadcast!(socket, "exercise_added", %{exercise: serialize_exercise(exercise)})
        {:reply, {:ok, %{exercise_id: exercise.id}}, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "add_failed"}}, socket}
    end
  end

  def handle_in("log_set", %{"exercise_id" => exercise_id} = params, socket) do
    user_id = socket.assigns.current_user.id
    workout_id = workout_id_from_topic(socket.topic)
    attrs = Map.drop(params, ["exercise_id"])

    with {:ok, exercise} <- Workouts.get_exercise(exercise_id, workout_id),
         {:ok, set, pr_flag} <- Workouts.log_set(user_id, exercise, attrs) do
      {:reply, {:ok, %{set_id: set.id, pr: pr_flag == :pr}}, socket}
    else
      {:error, :not_found} ->
        {:reply, {:error, %{reason: "exercise_not_found"}}, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "log_failed"}}, socket}
    end
  end

  # Receive PubSub broadcast from LogSet action — push to all channel subscribers
  @impl true
  def handle_info({:set_logged, set, pr_flag}, socket) do
    push(socket, "set_logged", %{set: serialize_set(set), pr: pr_flag == :pr})
    {:noreply, socket}
  end

  defp workout_id_from_topic("workout:" <> id_str), do: String.to_integer(id_str)

  defp serialize_workout(workout) do
    %{
      id: workout.id,
      date: workout.date,
      type: workout.type,
      duration: workout.duration,
      exercises: Enum.map(workout.exercises, &serialize_exercise/1)
    }
  end

  defp serialize_exercise(exercise) do
    sets =
      if Ecto.assoc_loaded?(exercise.exercise_sets),
        do: Enum.map(exercise.exercise_sets, &serialize_set/1),
        else: []

    %{
      id: exercise.id,
      name: exercise.name,
      sets: exercise.sets,
      reps: exercise.reps,
      weight: exercise.weight,
      rpe: exercise.rpe,
      is_pr: exercise.is_pr,
      exercise_sets: sets
    }
  end

  defp serialize_set(set) do
    %{
      id: set.id,
      set_number: set.set_number,
      weight: set.weight,
      reps: set.reps,
      is_pr: set.is_pr,
      completed: set.completed
    }
  end
end
