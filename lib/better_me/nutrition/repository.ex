defmodule BetterMe.Nutrition.Repository do
  import Ecto.Query
  alias BetterMe.Nutrition.Schema.{Ingredient, MealLog, Recipe, RecipeIngredient}
  alias BetterMe.Repo

  # --- Ingredients ---

  def list_ingredients do
    Ingredient |> order_by([i], asc: i.category, asc: i.name) |> Repo.all()
  end

  def ingredient_categories, do: Ingredient.categories()

  def get_ingredient(id) do
    case Repo.get(Ingredient, id) do
      nil -> {:error, :not_found}
      ingredient -> {:ok, ingredient}
    end
  end

  def get_ingredient!(id), do: Repo.get!(Ingredient, id)

  def create_ingredient(attrs) do
    %Ingredient{}
    |> Ingredient.changeset(attrs)
    |> Repo.insert()
  end

  def update_ingredient(ingredient, attrs) do
    ingredient
    |> Ingredient.changeset(attrs)
    |> Repo.update()
  end

  def delete_ingredient(ingredient) do
    Repo.delete(ingredient)
  end

  def change_ingredient(ingredient, attrs \\ %{}) do
    Ingredient.changeset(ingredient, attrs)
  end

  def new_ingredient, do: %Ingredient{}

  # --- Recipes ---

  def list_recipes(user_id) do
    Recipe
    |> where(user_id: ^user_id)
    |> order_by([r], asc: r.title)
    |> Repo.all()
  end

  def get_recipe(id, user_id) do
    query =
      Recipe
      |> where(id: ^id, user_id: ^user_id)
      |> preload(recipe_ingredients: :ingredient)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      recipe -> {:ok, recipe}
    end
  end

  def get_recipe!(id, user_id) do
    Recipe
    |> where(id: ^id, user_id: ^user_id)
    |> preload(recipe_ingredients: :ingredient)
    |> Repo.one!()
  end

  def create_recipe(user_id, attrs) do
    %Recipe{user_id: user_id}
    |> Recipe.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_recipe(recipe, attrs) do
    recipe
    |> Recipe.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_recipe(recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(recipe, attrs \\ %{}) do
    Recipe.create_changeset(recipe, attrs)
  end

  def new_recipe, do: %Recipe{}

  # --- Recipe Ingredients ---

  def add_recipe_ingredient(attrs) do
    %RecipeIngredient{}
    |> RecipeIngredient.changeset(attrs)
    |> Repo.insert()
  end

  def remove_recipe_ingredient(recipe_ingredient) do
    Repo.delete(recipe_ingredient)
  end

  def get_recipe_ingredient(id) do
    case Repo.get(RecipeIngredient, id) do
      nil -> {:error, :not_found}
      ri -> {:ok, ri}
    end
  end

  # --- Meal Logs ---

  def list_meal_logs(user_id, date) do
    MealLog
    |> where(user_id: ^user_id, date: ^date)
    |> order_by([m], asc: m.meal_type)
    |> preload(recipe: [recipe_ingredients: :ingredient])
    |> Repo.all()
  end

  def log_meal(user_id, attrs) do
    %MealLog{user_id: user_id}
    |> MealLog.changeset(attrs)
    |> Repo.insert()
  end

  def delete_meal_log(meal_log) do
    Repo.delete(meal_log)
  end

  def get_meal_log(id, user_id) do
    case Repo.get_by(MealLog, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      meal_log -> {:ok, meal_log}
    end
  end

  def daily_calories(user_id, days \\ 14) do
    since = Date.add(Date.utc_today(), -days)

    Repo.all(
      from ml in MealLog,
        join: ri in RecipeIngredient,
        on: ri.recipe_id == ml.recipe_id,
        join: ing in Ingredient,
        on: ing.id == ri.ingredient_id,
        where: ml.user_id == ^user_id and ml.date >= ^since,
        group_by: ml.date,
        order_by: [asc: ml.date],
        select: %{
          date: ml.date,
          calories:
            sum(
              fragment(
                "? * ? / 100.0 * ?",
                ing.calories_per_100g,
                ri.quantity_grams,
                ml.servings
              )
            )
        }
    )
  end
end
