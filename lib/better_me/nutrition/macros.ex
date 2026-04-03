defmodule BetterMe.Nutrition.Macros do
  @moduledoc """
  Pure macro calculations — no DB, no side effects.
  All functions take plain data and return plain data.
  """

  @doc """
  Calculates macros for a recipe given its recipe_ingredients (preloaded with ingredient).
  Returns %{calories: float, protein: float, carbs: float, fat: float}.
  """
  def for_recipe(recipe_ingredients) do
    Enum.reduce(recipe_ingredients, zero(), fn ri, acc ->
      factor = ri.quantity_grams / 100.0
      ing = ri.ingredient

      %{
        calories: acc.calories + ing.calories_per_100g * factor,
        protein: acc.protein + ing.protein_per_100g * factor,
        carbs: acc.carbs + ing.carbs_per_100g * factor,
        fat: acc.fat + ing.fat_per_100g * factor
      }
    end)
  end

  @doc """
  Scales recipe macros by number of servings.
  """
  def for_meal_log(recipe_macros, servings) do
    %{
      calories: recipe_macros.calories * servings,
      protein: recipe_macros.protein * servings,
      carbs: recipe_macros.carbs * servings,
      fat: recipe_macros.fat * servings
    }
  end

  @doc """
  Sums a list of macro maps into daily totals.
  """
  def daily_totals(macro_list) do
    Enum.reduce(macro_list, zero(), fn m, acc ->
      %{
        calories: acc.calories + m.calories,
        protein: acc.protein + m.protein,
        carbs: acc.carbs + m.carbs,
        fat: acc.fat + m.fat
      }
    end)
  end

  defp zero, do: %{calories: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0}
end
