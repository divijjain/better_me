defmodule BetterMe.Health.Schema.ActivityLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activity_logs" do
    field :date, :date
    field :steps, :integer
    field :active_kcal, :float
    field :resting_hr_bpm, :integer
    field :sleep_minutes, :integer

    belongs_to :user, BetterMe.Accounts.User

    timestamps()
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:date, :steps, :active_kcal, :resting_hr_bpm, :sleep_minutes, :user_id])
    |> validate_required([:date, :user_id])
    |> validate_number(:steps, greater_than_or_equal_to: 0)
    |> validate_number(:active_kcal, greater_than_or_equal_to: 0)
    |> validate_number(:resting_hr_bpm, greater_than: 0)
    |> validate_number(:sleep_minutes, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :date])
  end
end
