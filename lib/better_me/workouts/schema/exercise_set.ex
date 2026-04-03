defmodule BetterMe.Workouts.Schema.ExerciseSet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exercise_sets" do
    field :set_number, :integer
    field :weight, :float
    field :reps, :integer
    field :is_pr, :boolean, default: false
    field :completed, :boolean, default: false

    belongs_to :exercise, BetterMe.Workouts.Schema.Exercise

    timestamps()
  end

  def create_changeset(set, attrs) do
    set
    |> cast(attrs, [:set_number, :weight, :reps, :is_pr, :completed, :exercise_id])
    |> validate_required([:set_number, :exercise_id])
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_number(:reps, greater_than: 0)
  end

  def update_changeset(set, attrs) do
    set
    |> cast(attrs, [:weight, :reps, :is_pr, :completed])
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_number(:reps, greater_than: 0)
  end
end
