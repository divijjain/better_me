defmodule BetterMe.NutritionTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Nutrition
  alias BetterMe.Nutrition.Schema.{Ingredient, MealLog, Recipe, RecipeIngredient}

  import BetterMe.Factory

  setup do
    %{user: insert(:user)}
  end

  # ---------------------------------------------------------------------------
  # Ingredients
  # ---------------------------------------------------------------------------

  describe "create_ingredient/1" do
    test "creates an ingredient with valid attrs" do
      attrs = %{
        name: "Chicken Breast",
        category: :protein,
        calories_per_100g: 165.0,
        protein_per_100g: 31.0,
        carbs_per_100g: 0.0,
        fat_per_100g: 3.6
      }

      assert {:ok, ingredient} = Nutrition.create_ingredient(attrs)
      assert ingredient.name == "Chicken Breast"
      assert ingredient.category == :protein
    end

    test "returns error when name is missing" do
      assert {:error, changeset} =
               Nutrition.create_ingredient(%{category: :protein, calories_per_100g: 100.0})

      assert %{name: [_]} = errors_on(changeset)
    end

    test "returns error for duplicate name" do
      existing = insert(:ingredient)

      assert {:error, changeset} =
               Nutrition.create_ingredient(%{
                 name: existing.name,
                 category: :grain,
                 calories_per_100g: 100.0,
                 protein_per_100g: 5.0,
                 carbs_per_100g: 20.0,
                 fat_per_100g: 1.0
               })

      assert changeset.valid? == false
    end

    test "returns error for negative calorie value" do
      attrs = %{name: "Bad Food", category: :other, calories_per_100g: -1.0}
      assert {:error, changeset} = Nutrition.create_ingredient(attrs)
      assert %{calories_per_100g: [_]} = errors_on(changeset)
    end
  end

  describe "list_ingredients/0" do
    test "returns all ingredients" do
      ingredient = insert(:ingredient)
      ingredients = Nutrition.list_ingredients()
      assert Enum.any?(ingredients, &(&1.id == ingredient.id))
    end
  end

  describe "get_ingredient/1" do
    test "returns {:ok, ingredient} for valid id" do
      ingredient = insert(:ingredient)
      assert {:ok, found} = Nutrition.get_ingredient(ingredient.id)
      assert found.id == ingredient.id
    end

    test "returns {:error, :not_found} for nonexistent id" do
      assert {:error, :not_found} = Nutrition.get_ingredient(0)
    end
  end

  describe "update_ingredient/2" do
    test "updates ingredient fields" do
      ingredient = insert(:ingredient)
      assert {:ok, updated} = Nutrition.update_ingredient(ingredient, %{calories_per_100g: 250.0})
      assert updated.calories_per_100g == 250.0
    end
  end

  describe "delete_ingredient/1" do
    test "deletes the ingredient" do
      ingredient = insert(:ingredient)
      assert {:ok, _} = Nutrition.delete_ingredient(ingredient)
      assert {:error, :not_found} = Nutrition.get_ingredient(ingredient.id)
    end
  end

  describe "ingredient_categories/0" do
    test "returns a list of category atoms" do
      categories = Nutrition.ingredient_categories()
      assert is_list(categories)
      assert :protein in categories
      assert :dairy in categories
    end
  end

  # ---------------------------------------------------------------------------
  # Recipes
  # ---------------------------------------------------------------------------

  describe "create_recipe/2" do
    test "creates a recipe with valid attrs", %{user: user} do
      assert {:ok, recipe} = Nutrition.create_recipe(user.id, %{title: "My Salad"})
      assert recipe.title == "My Salad"
      assert recipe.user_id == user.id
    end

    test "returns error when title is missing", %{user: user} do
      assert {:error, changeset} = Nutrition.create_recipe(user.id, %{})
      assert %{title: [_]} = errors_on(changeset)
    end
  end

  describe "list_recipes/1" do
    test "returns recipes for the user", %{user: user} do
      recipe = insert(:recipe, user: user)
      recipes = Nutrition.list_recipes(user.id)
      assert Enum.any?(recipes, &(&1.id == recipe.id))
    end

    test "does not return recipes from other users", %{user: user} do
      insert(:recipe, user: insert(:user))
      recipes = Nutrition.list_recipes(user.id)
      assert Enum.all?(recipes, &(&1.user_id == user.id))
    end
  end

  describe "get_recipe/2" do
    test "returns {:ok, recipe} with preloaded ingredients", %{user: user} do
      recipe = insert(:recipe, user: user)
      ingredient = insert(:ingredient)
      insert(:recipe_ingredient, recipe: recipe, ingredient: ingredient)

      assert {:ok, found} = Nutrition.get_recipe(recipe.id, user.id)
      assert found.id == recipe.id
      assert length(found.recipe_ingredients) == 1
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      recipe = insert(:recipe, user: insert(:user))
      assert {:error, :not_found} = Nutrition.get_recipe(recipe.id, user.id)
    end
  end

  describe "update_recipe/2" do
    test "updates recipe title", %{user: user} do
      recipe = insert(:recipe, user: user)
      assert {:ok, updated} = Nutrition.update_recipe(recipe, %{title: "Updated Salad"})
      assert updated.title == "Updated Salad"
    end
  end

  describe "delete_recipe/1" do
    test "deletes the recipe", %{user: user} do
      recipe = insert(:recipe, user: user)
      assert {:ok, _} = Nutrition.delete_recipe(recipe)
      assert {:error, :not_found} = Nutrition.get_recipe(recipe.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Recipe ingredients
  # ---------------------------------------------------------------------------

  describe "add_recipe_ingredient/1" do
    test "adds ingredient to recipe", %{user: user} do
      recipe = insert(:recipe, user: user)
      ingredient = insert(:ingredient)

      assert {:ok, ri} =
               Nutrition.add_recipe_ingredient(%{
                 recipe_id: recipe.id,
                 ingredient_id: ingredient.id,
                 quantity_grams: 150.0
               })

      assert ri.quantity_grams == 150.0
    end

    test "returns error for duplicate ingredient in same recipe", %{user: user} do
      recipe = insert(:recipe, user: user)
      ingredient = insert(:ingredient)
      attrs = %{recipe_id: recipe.id, ingredient_id: ingredient.id, quantity_grams: 100.0}

      assert {:ok, _} = Nutrition.add_recipe_ingredient(attrs)
      assert {:error, changeset} = Nutrition.add_recipe_ingredient(attrs)
      assert changeset.valid? == false
    end
  end

  describe "remove_recipe_ingredient/1" do
    test "removes ingredient from recipe", %{user: user} do
      recipe = insert(:recipe, user: user)
      ingredient = insert(:ingredient)
      insert(:recipe_ingredient, recipe: recipe, ingredient: ingredient)

      {:ok, found} = Nutrition.get_recipe(recipe.id, user.id)
      [ri] = found.recipe_ingredients

      assert {:ok, _} = Nutrition.remove_recipe_ingredient(ri)

      {:ok, refreshed} = Nutrition.get_recipe(recipe.id, user.id)
      assert refreshed.recipe_ingredients == []
    end
  end

  # ---------------------------------------------------------------------------
  # Meal logs
  # ---------------------------------------------------------------------------

  describe "log_meal_for_user/2" do
    test "creates a meal log for owned recipe", %{user: user} do
      recipe = insert(:recipe, user: user)
      ingredient = insert(:ingredient)
      insert(:recipe_ingredient, recipe: recipe, ingredient: ingredient)

      attrs = %{
        date: Date.utc_today(),
        meal_type: :breakfast,
        recipe_id: recipe.id,
        servings: 2.0
      }

      assert {:ok, log} = Nutrition.log_meal_for_user(user.id, attrs)
      assert log.meal_type == :breakfast
      assert log.servings == 2.0
    end

    test "returns error for recipe owned by another user", %{user: user} do
      other_recipe = insert(:recipe, user: insert(:user))

      attrs = %{
        date: Date.utc_today(),
        meal_type: :lunch,
        recipe_id: other_recipe.id,
        servings: 1.0
      }

      assert {:error, _} = Nutrition.log_meal_for_user(user.id, attrs)
    end
  end

  describe "list_meal_logs/2" do
    test "returns logs for user on the given date", %{user: user} do
      recipe = insert(:recipe, user: user)
      log = insert(:meal_log, user: user, recipe: recipe, date: Date.utc_today())
      logs = Nutrition.list_meal_logs(user.id, Date.utc_today())
      assert Enum.any?(logs, &(&1.id == log.id))
    end

    test "does not return logs from other dates", %{user: user} do
      recipe = insert(:recipe, user: user)
      insert(:meal_log, user: user, recipe: recipe, date: Date.utc_today())
      logs = Nutrition.list_meal_logs(user.id, Date.add(Date.utc_today(), -1))
      assert logs == []
    end
  end

  describe "daily_summary/2" do
    test "returns totals and meals grouped by type", %{user: user} do
      recipe = insert(:recipe, user: user)
      ingredient = insert(:ingredient)
      insert(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
      insert(:meal_log, user: user, recipe: recipe, date: Date.utc_today(), meal_type: :lunch)

      summary = Nutrition.daily_summary(user.id, Date.utc_today())
      assert is_map(summary.meals_by_type)
      assert is_map(summary.totals)
      assert Map.has_key?(summary.totals, :calories)
      assert Map.has_key?(summary.totals, :protein)
    end

    test "returns zero totals when no logs", %{user: user} do
      summary = Nutrition.daily_summary(user.id, Date.utc_today())
      assert summary.totals.calories == 0.0
    end
  end

  describe "delete_meal_log/1" do
    test "deletes the meal log", %{user: user} do
      recipe = insert(:recipe, user: user)
      log = insert(:meal_log, user: user, recipe: recipe)
      assert {:ok, _} = Nutrition.delete_meal_log(log)
      assert {:error, :not_found} = Nutrition.get_meal_log(log.id, user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Changesets
  # ---------------------------------------------------------------------------

  defp valid_ingredient_attrs(overrides) do
    Map.merge(
      %{
        name: "Test #{System.unique_integer()}",
        category: :protein,
        calories_per_100g: 200.0,
        protein_per_100g: 25.0,
        carbs_per_100g: 5.0,
        fat_per_100g: 8.0
      },
      overrides
    )
  end

  describe "Ingredient changeset" do
    test "invalid when name exceeds 100 chars" do
      cs =
        Ingredient.changeset(
          %Ingredient{},
          valid_ingredient_attrs(%{name: String.duplicate("a", 101)})
        )

      assert %{name: [_]} = errors_on(cs)
    end

    test "invalid when any macro is negative" do
      for field <- [:calories_per_100g, :protein_per_100g, :carbs_per_100g, :fat_per_100g] do
        cs = Ingredient.changeset(%Ingredient{}, valid_ingredient_attrs(%{field => -1.0}))
        assert errors_on(cs)[field] != nil, "expected invalid for #{field} = -1.0"
      end
    end

    test "invalid when glycemic_index is out of range" do
      for gi <- [-1, 101] do
        cs = Ingredient.changeset(%Ingredient{}, valid_ingredient_attrs(%{glycemic_index: gi}))
        assert %{glycemic_index: [_]} = errors_on(cs), "expected invalid for glycemic_index #{gi}"
      end
    end

    test "valid when glycemic_index is at boundaries (0 and 100)" do
      for gi <- [0, 100] do
        cs = Ingredient.changeset(%Ingredient{}, valid_ingredient_attrs(%{glycemic_index: gi}))
        assert cs.valid?, "expected valid for glycemic_index #{gi}"
      end
    end
  end

  describe "Recipe changeset" do
    test "invalid when title exceeds 200 chars" do
      user = insert(:user)

      cs =
        Recipe.create_changeset(%Recipe{}, %{title: String.duplicate("a", 201), user_id: user.id})

      assert %{title: [_]} = errors_on(cs)
    end

    test "invalid when title is empty" do
      user = insert(:user)
      cs = Recipe.create_changeset(%Recipe{}, %{title: "", user_id: user.id})
      assert %{title: [_]} = errors_on(cs)
    end
  end

  describe "RecipeIngredient changeset" do
    test "invalid when quantity_grams is zero or negative" do
      recipe = insert(:recipe)
      ingredient = insert(:ingredient)

      for qty <- [0.0, -50.0] do
        cs =
          RecipeIngredient.changeset(%RecipeIngredient{}, %{
            recipe_id: recipe.id,
            ingredient_id: ingredient.id,
            quantity_grams: qty
          })

        assert %{quantity_grams: [_]} = errors_on(cs),
               "expected invalid for quantity_grams #{qty}"
      end
    end

    test "invalid without quantity_grams" do
      recipe = insert(:recipe)
      ingredient = insert(:ingredient)

      cs =
        RecipeIngredient.changeset(%RecipeIngredient{}, %{
          recipe_id: recipe.id,
          ingredient_id: ingredient.id
        })

      assert %{quantity_grams: [_]} = errors_on(cs)
    end
  end

  describe "MealLog changeset" do
    test "invalid when servings is zero or negative" do
      recipe = insert(:recipe)
      user = insert(:user)

      for s <- [0.0, -1.0] do
        cs =
          MealLog.changeset(%MealLog{}, %{
            date: Date.utc_today(),
            meal_type: :lunch,
            servings: s,
            recipe_id: recipe.id,
            user_id: user.id
          })

        assert %{servings: [_]} = errors_on(cs), "expected invalid for servings #{s}"
      end
    end

    test "invalid for unknown meal_type" do
      recipe = insert(:recipe)
      user = insert(:user)

      cs =
        MealLog.changeset(%MealLog{}, %{
          date: Date.utc_today(),
          meal_type: :brunch,
          servings: 1.0,
          recipe_id: recipe.id,
          user_id: user.id
        })

      assert %{meal_type: [_]} = errors_on(cs)
    end

    test "valid for all meal types" do
      recipe = insert(:recipe)
      user = insert(:user)

      for type <- [:breakfast, :lunch, :dinner, :snack] do
        cs =
          MealLog.changeset(%MealLog{}, %{
            date: Date.utc_today(),
            meal_type: type,
            servings: 1.0,
            recipe_id: recipe.id,
            user_id: user.id
          })

        assert cs.valid?, "expected valid for meal_type #{type}"
      end
    end
  end
end
