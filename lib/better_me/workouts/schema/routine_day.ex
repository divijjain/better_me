defmodule BetterMe.Workouts.Schema.RoutineDay do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_days" do
    field :name, :string
    field :position, :integer

    belongs_to :routine_template, BetterMe.Workouts.Schema.RoutineTemplate

    has_many :routine_exercises, BetterMe.Workouts.Schema.RoutineExercise,
      foreign_key: :routine_day_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(day, attrs) do
    day
    |> cast(attrs, [:name, :position, :routine_template_id])
    |> validate_required([:name, :position, :routine_template_id])
  end
end
