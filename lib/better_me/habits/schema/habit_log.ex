defmodule BetterMe.Habits.HabitLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "habit_logs" do
    field :date, :date
    field :completed, :boolean, default: true
    field :note, :string

    belongs_to :habit, BetterMe.Habits.Habit

    timestamps(type: :utc_datetime)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:date, :completed, :note])
    |> validate_required([:date])
    |> unique_constraint([:habit_id, :date], message: "already logged for this date")
  end
end
