defmodule BetterMe.Nutrition.Schema.MealLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meal_logs" do
    field :date, :date
    field :servings, :float, default: 1.0
    field :meal_type, Ecto.Enum, values: [:breakfast, :lunch, :dinner, :snack]

    belongs_to :recipe, BetterMe.Nutrition.Schema.Recipe
    belongs_to :user, BetterMe.Accounts.User

    timestamps()
  end

  def changeset(meal_log, attrs) do
    meal_log
    |> cast(attrs, [:date, :servings, :meal_type, :recipe_id])
    |> validate_required([:date, :servings, :meal_type, :recipe_id])
    |> validate_number(:servings, greater_than: 0)
    |> foreign_key_constraint(:recipe_id)
  end
end
