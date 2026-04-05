defmodule BetterMe.Profiles.TDEE do
  @moduledoc """
  Pure TDEE and macro target calculation — no DB, no side effects.
  Uses the Mifflin-St Jeor BMR formula.
  """

  @activity_multipliers %{
    sedentary:        1.2,
    lightly_active:   1.375,
    moderately_active: 1.55,
    very_active:      1.725,
    extra_active:     1.9
  }

  @doc """
  Calculates daily macro targets from a user profile.
  fat_pct is derived as 100 - protein_pct - carbs_pct.
  Returns %{calories: integer, protein_g: float, carbs_g: float, fat_g: float}.
  """
  def calculate(profile) do
    tdee     = tdee(profile)
    fat_pct  = 100 - profile.protein_pct - profile.carbs_pct

    %{
      calories: round(tdee),
      protein_g: macro_grams(tdee, profile.protein_pct, 4),
      carbs_g:   macro_grams(tdee, profile.carbs_pct,   4),
      fat_g:     macro_grams(tdee, fat_pct,             9)
    }
  end

  defp tdee(profile) do
    bmr(profile) * Map.fetch!(@activity_multipliers, profile.activity_level)
  end

  defp bmr(%{gender: :female} = p) do
    10 * p.weight_kg + 6.25 * p.height_cm - 5 * p.age - 161
  end

  defp bmr(p) do
    # male and other use the male formula
    10 * p.weight_kg + 6.25 * p.height_cm - 5 * p.age + 5
  end

  defp macro_grams(tdee, pct, calories_per_gram) do
    Float.round(tdee * pct / 100 / calories_per_gram, 1)
  end
end
