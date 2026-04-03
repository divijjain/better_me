defmodule BetterMe.Nutrition.Schema.RecipeIngredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_ingredients" do
    field :quantity_grams, :float

    belongs_to :recipe, BetterMe.Nutrition.Schema.Recipe
    belongs_to :ingredient, BetterMe.Nutrition.Schema.Ingredient

    timestamps()
  end

  def changeset(recipe_ingredient, attrs) do
    recipe_ingredient
    |> cast(attrs, [:recipe_id, :ingredient_id, :quantity_grams])
    |> validate_required([:recipe_id, :ingredient_id, :quantity_grams])
    |> validate_number(:quantity_grams, greater_than: 0)
    |> unique_constraint([:recipe_id, :ingredient_id])
    |> foreign_key_constraint(:recipe_id)
    |> foreign_key_constraint(:ingredient_id)
  end
end
