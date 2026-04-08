defmodule BetterMe.Nutrition do
  alias BetterMe.Nutrition.Actions
  alias BetterMe.Nutrition.Repository

  # Ingredients
  defdelegate list_ingredients(), to: Repository
  defdelegate get_ingredient(id), to: Repository
  defdelegate get_ingredient!(id), to: Repository
  defdelegate create_ingredient(attrs), to: Repository
  defdelegate update_ingredient(ingredient, attrs), to: Repository
  defdelegate delete_ingredient(ingredient), to: Repository
  defdelegate change_ingredient(ingredient, attrs \\ %{}), to: Repository
  defdelegate new_ingredient(), to: Repository
  defdelegate ingredient_categories(), to: Repository

  # Recipes
  defdelegate list_recipes(user_id), to: Repository
  defdelegate get_recipe(id, user_id), to: Repository
  defdelegate get_recipe!(id, user_id), to: Repository
  defdelegate create_recipe(user_id, attrs), to: Repository
  defdelegate update_recipe(recipe, attrs), to: Repository
  defdelegate delete_recipe(recipe), to: Repository
  defdelegate change_recipe(recipe, attrs \\ %{}), to: Repository
  defdelegate new_recipe(), to: Repository

  # Recipe ingredients
  defdelegate add_recipe_ingredient(attrs), to: Repository
  defdelegate remove_recipe_ingredient(recipe_ingredient), to: Repository
  defdelegate get_recipe_ingredient(id), to: Repository

  # Meal logs
  defdelegate list_meal_logs(user_id, date), to: Repository
  defdelegate log_meal(user_id, attrs), to: Repository
  defdelegate delete_meal_log(meal_log), to: Repository
  defdelegate get_meal_log(id, user_id), to: Repository
  defdelegate get_meal_log_with_recipe(id, user_id), to: Repository

  defdelegate log_meal_for_user(user_id, attrs), to: Actions.LogMeal, as: :run
  defdelegate daily_summary(user_id, date), to: Actions.DailySummary, as: :run
  defdelegate meal_type_order(), to: Actions.DailySummary
  defdelegate daily_calories(user_id, days \\ 14), to: Repository
end
