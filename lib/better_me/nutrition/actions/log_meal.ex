defmodule BetterMe.Nutrition.Actions.LogMeal do
  alias BetterMe.Nutrition.Repository

  @doc """
  Logs a meal for a user. Validates the recipe belongs to the user before inserting.
  Returns {:ok, meal_log} | {:error, reason}.
  """
  def run(user_id, attrs) do
    recipe_id = Map.get(attrs, :recipe_id) || Map.get(attrs, "recipe_id")

    with {:ok, _recipe} <- Repository.get_recipe(recipe_id, user_id) do
      Repository.log_meal(user_id, attrs)
    end
  end
end
