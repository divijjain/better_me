defmodule BetterMe.Nutrition.Schema.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [
    :dairy,
    :fat,
    :fruit,
    :grain,
    :legume,
    :nut,
    :other,
    :protein,
    :seafood,
    :spice,
    :vegetable
  ]

  def categories, do: @categories

  schema "ingredients" do
    field :name, :string
    field :brand, :string
    field :category, Ecto.Enum, values: @categories, default: :other
    field :calories_per_100g, :float
    field :protein_per_100g, :float
    field :carbs_per_100g, :float
    field :fat_per_100g, :float
    field :fiber_per_100g, :float, default: 0.0
    field :sugar_per_100g, :float, default: 0.0
    field :glycemic_index, :integer
    field :sodium_mg_per_100g, :float
    field :is_vegetarian, :boolean, default: false

    has_many :recipe_ingredients, BetterMe.Nutrition.Schema.RecipeIngredient

    timestamps()
  end

  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [
      :name,
      :brand,
      :category,
      :calories_per_100g,
      :protein_per_100g,
      :carbs_per_100g,
      :fat_per_100g,
      :fiber_per_100g,
      :sugar_per_100g,
      :glycemic_index,
      :sodium_mg_per_100g,
      :is_vegetarian
    ])
    |> validate_required([
      :name,
      :category,
      :calories_per_100g,
      :protein_per_100g,
      :carbs_per_100g,
      :fat_per_100g
    ])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_number(:calories_per_100g, greater_than_or_equal_to: 0)
    |> validate_number(:protein_per_100g, greater_than_or_equal_to: 0)
    |> validate_number(:carbs_per_100g, greater_than_or_equal_to: 0)
    |> validate_number(:fat_per_100g, greater_than_or_equal_to: 0)
    |> validate_number(:fiber_per_100g, greater_than_or_equal_to: 0)
    |> validate_number(:sugar_per_100g, greater_than_or_equal_to: 0)
    |> validate_number(:glycemic_index, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:sodium_mg_per_100g, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
