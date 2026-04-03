defmodule BetterMe.Workouts.Schema.RoutineExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_exercises" do
    field :name, :string
    field :working_sets, :integer
    field :rep_range, :string
    field :notes, :string
    field :position, :integer
    field :substitution_1, :string
    field :substitution_2, :string

    belongs_to :routine_day, BetterMe.Workouts.Schema.RoutineDay

    timestamps()
  end

  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [
      :name,
      :working_sets,
      :rep_range,
      :notes,
      :position,
      :substitution_1,
      :substitution_2,
      :routine_day_id
    ])
    |> validate_required([:name, :position, :routine_day_id])
  end
end
