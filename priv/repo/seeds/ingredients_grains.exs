alias BetterMe.Nutrition.Schema.Ingredient
alias BetterMe.Repo

# All macros per 100g (raw/dry unless noted). Source: USDA FoodData Central.
# All grains are vegetarian.

ingredients = [
  # --- Rice ---
  %{name: "White Rice (raw)",   category: :grain, calories_per_100g: 365.0, protein_per_100g: 7.1,  carbs_per_100g: 80.0, fat_per_100g: 0.7, fiber_per_100g: 1.3,  sugar_per_100g: 0.1, glycemic_index: 72, sodium_mg_per_100g: 1.0,   is_vegetarian: true},
  %{name: "Brown Rice (raw)",   category: :grain, calories_per_100g: 370.0, protein_per_100g: 7.9,  carbs_per_100g: 77.0, fat_per_100g: 2.9, fiber_per_100g: 3.5,  sugar_per_100g: 0.7, glycemic_index: 50, sodium_mg_per_100g: 7.0,   is_vegetarian: true},
  %{name: "Basmati Rice (raw)", category: :grain, calories_per_100g: 355.0, protein_per_100g: 8.0,  carbs_per_100g: 78.0, fat_per_100g: 0.5, fiber_per_100g: 1.0,  sugar_per_100g: 0.1, glycemic_index: 57, sodium_mg_per_100g: 1.0,   is_vegetarian: true},

  # --- Oats ---
  %{name: "Rolled Oats",        category: :grain, calories_per_100g: 389.0, protein_per_100g: 17.0, carbs_per_100g: 66.0, fat_per_100g: 7.0, fiber_per_100g: 10.6, sugar_per_100g: 1.1, glycemic_index: 55, sodium_mg_per_100g: 2.0,   is_vegetarian: true},
  %{name: "Steel Cut Oats",     category: :grain, calories_per_100g: 379.0, protein_per_100g: 13.0, carbs_per_100g: 68.0, fat_per_100g: 6.5, fiber_per_100g: 10.0, sugar_per_100g: 1.0, glycemic_index: 42, sodium_mg_per_100g: 2.0,   is_vegetarian: true},

  # --- Pasta & Noodles ---
  %{name: "Pasta (dry)",        category: :grain, calories_per_100g: 371.0, protein_per_100g: 13.0, carbs_per_100g: 75.0, fat_per_100g: 1.5, fiber_per_100g: 3.2,  sugar_per_100g: 2.7, glycemic_index: 50, sodium_mg_per_100g: 6.0,   is_vegetarian: true},
  %{name: "Whole Wheat Pasta",  category: :grain, calories_per_100g: 348.0, protein_per_100g: 13.0, carbs_per_100g: 68.0, fat_per_100g: 2.5, fiber_per_100g: 8.0,  sugar_per_100g: 2.5, glycemic_index: 42, sodium_mg_per_100g: 8.0,   is_vegetarian: true},
  %{name: "Rice Noodles (dry)", category: :grain, calories_per_100g: 364.0, protein_per_100g: 6.0,  carbs_per_100g: 84.0, fat_per_100g: 0.6, fiber_per_100g: 1.8,  sugar_per_100g: 0.0, glycemic_index: 61, sodium_mg_per_100g: 182.0, is_vegetarian: true},

  # --- Bread ---
  %{name: "White Bread",        category: :grain, calories_per_100g: 265.0, protein_per_100g: 9.0,  carbs_per_100g: 49.0, fat_per_100g: 3.2, fiber_per_100g: 2.7,  sugar_per_100g: 5.0, glycemic_index: 75, sodium_mg_per_100g: 491.0, is_vegetarian: true},
  %{name: "Whole Wheat Bread",  category: :grain, calories_per_100g: 247.0, protein_per_100g: 13.0, carbs_per_100g: 41.0, fat_per_100g: 4.2, fiber_per_100g: 6.0,  sugar_per_100g: 5.6, glycemic_index: 53, sodium_mg_per_100g: 400.0, is_vegetarian: true},
  %{name: "Sourdough Bread",    category: :grain, calories_per_100g: 289.0, protein_per_100g: 9.0,  carbs_per_100g: 56.0, fat_per_100g: 1.2, fiber_per_100g: 2.2,  sugar_per_100g: 2.0, glycemic_index: 48, sodium_mg_per_100g: 517.0, is_vegetarian: true},

  # --- Other Grains ---
  %{name: "Quinoa (raw)",       category: :grain, calories_per_100g: 368.0, protein_per_100g: 14.0, carbs_per_100g: 64.0, fat_per_100g: 6.1, fiber_per_100g: 7.0,  sugar_per_100g: 4.6, glycemic_index: 53, sodium_mg_per_100g: 5.0,   is_vegetarian: true},
  %{name: "Couscous (dry)",     category: :grain, calories_per_100g: 376.0, protein_per_100g: 13.0, carbs_per_100g: 77.0, fat_per_100g: 0.6, fiber_per_100g: 5.0,  sugar_per_100g: 0.5, glycemic_index: 65, sodium_mg_per_100g: 10.0,  is_vegetarian: true},
  %{name: "Bulgur Wheat (dry)", category: :grain, calories_per_100g: 342.0, protein_per_100g: 12.0, carbs_per_100g: 76.0, fat_per_100g: 1.3, fiber_per_100g: 18.3, sugar_per_100g: 0.4, glycemic_index: 48, sodium_mg_per_100g: 17.0,  is_vegetarian: true},
  %{name: "Buckwheat (raw)",    category: :grain, calories_per_100g: 343.0, protein_per_100g: 13.0, carbs_per_100g: 72.0, fat_per_100g: 3.4, fiber_per_100g: 10.0, sugar_per_100g: 0.0, glycemic_index: 49, sodium_mg_per_100g: 1.0,   is_vegetarian: true},
  %{name: "Barley (raw)",       category: :grain, calories_per_100g: 354.0, protein_per_100g: 12.0, carbs_per_100g: 74.0, fat_per_100g: 2.3, fiber_per_100g: 17.0, sugar_per_100g: 0.8, glycemic_index: 28, sodium_mg_per_100g: 12.0,  is_vegetarian: true},
  %{name: "Corn Tortilla",      category: :grain, calories_per_100g: 218.0, protein_per_100g: 5.7,  carbs_per_100g: 46.0, fat_per_100g: 3.0, fiber_per_100g: 6.3,  sugar_per_100g: 1.3, glycemic_index: 52, sodium_mg_per_100g: 244.0, is_vegetarian: true},
  %{name: "Rye Bread",          category: :grain, calories_per_100g: 259.0, protein_per_100g: 9.0,  carbs_per_100g: 48.0, fat_per_100g: 3.3, fiber_per_100g: 5.8,  sugar_per_100g: 4.0, glycemic_index: 41, sodium_mg_per_100g: 603.0, is_vegetarian: true},
]

IO.puts("\n--- Seeding grain ingredients ---")

Enum.each(ingredients, fn attrs ->
  case Repo.get_by(Ingredient, name: attrs.name) do
    nil ->
      case %Ingredient{} |> Ingredient.changeset(attrs) |> Repo.insert() do
        {:ok, i}     -> IO.puts("  Created: #{i.name}")
        {:error, cs} -> IO.puts("  Failed: #{attrs.name} — #{inspect(cs.errors)}")
      end

    existing ->
      case existing |> Ingredient.changeset(attrs) |> Repo.update() do
        {:ok, i}     -> IO.puts("  Updated: #{i.name}")
        {:error, cs} -> IO.puts("  Failed to update: #{attrs.name} — #{inspect(cs.errors)}")
      end
  end
end)
