defmodule BetterMe.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "habits" do
    field :name, :string
    field :category, Ecto.Enum, values: [:health, :fitness, :personal, :learning, :work, :misc]
    field :frequency, Ecto.Enum, values: [:daily, :weekly], default: :daily
    field :active, :boolean, default: true

    belongs_to :user, BetterMe.Accounts.User
    has_many :logs, BetterMe.Habits.HabitLog

    timestamps(type: :utc_datetime)
  end

  def create_changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :category, :frequency])
    |> validate_required([:name, :category])
    |> validate_length(:name, min: 1, max: 100)
  end

  def update_changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :category, :active])
    |> validate_required([:name, :category])
    |> validate_length(:name, min: 1, max: 100)
  end
end
