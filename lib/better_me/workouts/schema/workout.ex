defmodule BetterMe.Workouts.Schema.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :date, :date
    field :type, Ecto.Enum, values: [:strength, :cardio, :flexibility, :sport, :other]
    field :duration, :integer
    field :notes, :string

    belongs_to :user, BetterMe.Accounts.User
    belongs_to :routine_day, BetterMe.Workouts.Schema.RoutineDay
    has_many :exercises, BetterMe.Workouts.Schema.Exercise

    timestamps()
  end

  def create_changeset(workout, attrs) do
    workout
    |> cast(attrs, [:date, :type, :duration, :notes, :user_id, :routine_day_id])
    |> validate_required([:date, :type, :user_id])
    |> validate_number(:duration, greater_than: 0)
  end

  def update_changeset(workout, attrs) do
    workout
    |> cast(attrs, [:date, :type, :duration, :notes, :routine_day_id])
    |> validate_required([:date, :type])
    |> validate_number(:duration, greater_than: 0)
  end
end
