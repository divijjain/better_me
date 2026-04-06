defmodule BetterMe.Profiles.Schema.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @activity_levels [:sedentary, :lightly_active, :moderately_active, :very_active, :extra_active]
  @genders [:male, :female, :other]

  def activity_levels, do: @activity_levels
  def genders, do: @genders

  schema "user_profiles" do
    field :age, :integer
    field :weight_kg, :float
    field :height_cm, :float
    field :gender, Ecto.Enum, values: @genders
    field :activity_level, Ecto.Enum, values: @activity_levels
    field :protein_pct, :integer, default: 30
    field :carbs_pct, :integer, default: 40

    belongs_to :user, BetterMe.Accounts.User

    timestamps()
  end

  # fat_pct is derived — never stored, always computed as 100 - protein_pct - carbs_pct
  def fat_pct(%__MODULE__{protein_pct: p, carbs_pct: c}), do: 100 - p - c

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :age,
      :weight_kg,
      :height_cm,
      :gender,
      :activity_level,
      :protein_pct,
      :carbs_pct
    ])
    |> validate_required([
      :age,
      :weight_kg,
      :height_cm,
      :gender,
      :activity_level,
      :protein_pct,
      :carbs_pct
    ])
    |> validate_number(:age, greater_than: 0, less_than: 120)
    |> validate_number(:weight_kg, greater_than: 0)
    |> validate_number(:height_cm, greater_than: 0)
    |> validate_number(:protein_pct, greater_than_or_equal_to: 1, less_than_or_equal_to: 98)
    |> validate_number(:carbs_pct, greater_than_or_equal_to: 1, less_than_or_equal_to: 98)
    |> validate_macro_split()
    |> unique_constraint(:user_id)
  end

  defp validate_macro_split(changeset) do
    protein = get_field(changeset, :protein_pct) || 0
    carbs = get_field(changeset, :carbs_pct) || 0

    if protein + carbs > 99 do
      add_error(changeset, :carbs_pct, "protein + carbs must leave at least 1% for fat")
    else
      changeset
    end
  end
end
