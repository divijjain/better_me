defmodule BetterMe.Nutrition.Actions.DailySummary do
  alias BetterMe.Nutrition.{Macros, Repository}

  @meal_type_order [:breakfast, :lunch, :dinner, :snack]

  @doc """
  Loads all meal logs for a user on a given date and returns:
    %{
      meals_by_type: %{breakfast: [...], lunch: [...], ...},
      totals: %{calories: float, protein: float, carbs: float, fat: float}
    }
  Each meal log is augmented with a :macros key for that entry.
  """
  def run(user_id, date) do
    logs = Repository.list_meal_logs(user_id, date)

    logs_with_macros =
      Enum.map(logs, fn log ->
        recipe_macros = Macros.for_recipe(log.recipe.recipe_ingredients)
        meal_macros = Macros.for_meal_log(recipe_macros, log.servings)
        Map.put(log, :macros, meal_macros)
      end)

    meals_by_type =
      @meal_type_order
      |> Enum.map(fn type ->
        entries = Enum.filter(logs_with_macros, &(&1.meal_type == type))
        {type, entries}
      end)
      |> Enum.into(%{})

    totals =
      logs_with_macros
      |> Enum.map(& &1.macros)
      |> Macros.daily_totals()

    %{meals_by_type: meals_by_type, totals: totals}
  end

  def meal_type_order, do: @meal_type_order
end
