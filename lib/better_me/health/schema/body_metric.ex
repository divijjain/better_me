defmodule BetterMe.Health.Schema.BodyMetric do
  use Ecto.Schema
  import Ecto.Changeset

  schema "body_metrics" do
    field :date, :date
    field :weight, :float
    field :body_fat_pct, :float

    belongs_to :user, BetterMe.Accounts.User

    timestamps()
  end

  def create_changeset(metric, attrs) do
    metric
    |> cast(attrs, [:date, :weight, :body_fat_pct, :user_id])
    |> validate_required([:date, :user_id])
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:body_fat_pct, greater_than_or_equal_to: 0, less_than: 100)
    |> unique_constraint([:user_id, :date])
  end

  def update_changeset(metric, attrs) do
    metric
    |> cast(attrs, [:date, :weight, :body_fat_pct])
    |> validate_required([:date])
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:body_fat_pct, greater_than_or_equal_to: 0, less_than: 100)
    |> unique_constraint([:user_id, :date])
  end
end
