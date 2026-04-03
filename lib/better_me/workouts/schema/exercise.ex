defmodule BetterMe.Workouts.Schema.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercises" do
    field :name, :string
    field :sets, :integer
    field :reps, :integer
    field :weight, :float
    field :rpe, :integer
    field :is_pr, :boolean, default: false

    belongs_to :workout, BetterMe.Workouts.Schema.Workout

    has_many :exercise_sets, BetterMe.Workouts.Schema.ExerciseSet,
      preload_order: [asc: :set_number]

    timestamps()
  end

  def create_changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :sets, :reps, :weight, :rpe, :is_pr, :workout_id])
    |> validate_required([:name, :workout_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_number(:sets, greater_than: 0)
    |> validate_number(:reps, greater_than: 0)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_inclusion(:rpe, 1..10)
  end

  def update_changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :sets, :reps, :weight, :rpe, :is_pr])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_number(:sets, greater_than: 0)
    |> validate_number(:reps, greater_than: 0)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_inclusion(:rpe, 1..10)
  end
end
