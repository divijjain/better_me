defmodule BetterMe.Nutrition.Schema.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipes" do
    field :title, :string
    field :tags, {:array, :string}, default: []

    belongs_to :user, BetterMe.Accounts.User
    has_many :recipe_ingredients, BetterMe.Nutrition.Schema.RecipeIngredient
    has_many :ingredients, through: [:recipe_ingredients, :ingredient]

    timestamps()
  end

  def create_changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:title, :tags])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 200)
  end

  def update_changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:title, :tags])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 200)
  end
end
