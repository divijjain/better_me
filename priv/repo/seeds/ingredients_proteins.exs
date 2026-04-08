alias BetterMe.Nutrition.Schema.Ingredient
alias BetterMe.Repo

# All macros per 100g (raw/uncooked unless noted). Source: USDA FoodData Central.

ingredients = [
  # --- Meat & Poultry --- (not vegetarian)
  %{name: "Chicken Breast",       category: :protein, calories_per_100g: 165.0, protein_per_100g: 31.0, carbs_per_100g: 0.0,  fat_per_100g: 3.6,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 74.0,  is_vegetarian: false},
  %{name: "Chicken Thigh",        category: :protein, calories_per_100g: 209.0, protein_per_100g: 26.0, carbs_per_100g: 0.0,  fat_per_100g: 11.0, fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 84.0,  is_vegetarian: false},
  %{name: "Lean Ground Beef",     category: :protein, calories_per_100g: 215.0, protein_per_100g: 26.0, carbs_per_100g: 0.0,  fat_per_100g: 12.0, fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 75.0,  is_vegetarian: false},
  %{name: "Beef Steak (Sirloin)", category: :protein, calories_per_100g: 207.0, protein_per_100g: 28.0, carbs_per_100g: 0.0,  fat_per_100g: 10.0, fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 57.0,  is_vegetarian: false},
  %{name: "Lamb",                 category: :protein, calories_per_100g: 258.0, protein_per_100g: 25.0, carbs_per_100g: 0.0,  fat_per_100g: 17.0, fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 72.0,  is_vegetarian: false},
  %{name: "Pork Tenderloin",      category: :protein, calories_per_100g: 143.0, protein_per_100g: 26.0, carbs_per_100g: 0.0,  fat_per_100g: 3.5,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 53.0,  is_vegetarian: false},
  %{name: "Turkey Breast",        category: :protein, calories_per_100g: 135.0, protein_per_100g: 30.0, carbs_per_100g: 0.0,  fat_per_100g: 1.0,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 63.0,  is_vegetarian: false},

  # --- Seafood --- (not vegetarian)
  %{name: "Salmon",               category: :seafood, calories_per_100g: 208.0, protein_per_100g: 20.0, carbs_per_100g: 0.0,  fat_per_100g: 13.0, fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 59.0,  is_vegetarian: false},
  %{name: "Tuna (canned, water)", category: :seafood, calories_per_100g: 116.0, protein_per_100g: 26.0, carbs_per_100g: 0.0,  fat_per_100g: 1.0,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 320.0, is_vegetarian: false},
  %{name: "Shrimp",               category: :seafood, calories_per_100g: 99.0,  protein_per_100g: 24.0, carbs_per_100g: 0.2,  fat_per_100g: 0.3,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 111.0, is_vegetarian: false},
  %{name: "Cod",                  category: :seafood, calories_per_100g: 82.0,  protein_per_100g: 18.0, carbs_per_100g: 0.0,  fat_per_100g: 0.7,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 54.0,  is_vegetarian: false},
  %{name: "Tilapia",              category: :seafood, calories_per_100g: 96.0,  protein_per_100g: 20.0, carbs_per_100g: 0.0,  fat_per_100g: 1.7,  fiber_per_100g: 0.0, sugar_per_100g: 0.0, glycemic_index: nil, sodium_mg_per_100g: 52.0,  is_vegetarian: false},

  # --- Eggs (non-vegetarian) & Dairy ---
  %{name: "Whole Egg",            category: :protein, calories_per_100g: 155.0, protein_per_100g: 13.0, carbs_per_100g: 1.1,  fat_per_100g: 11.0, fiber_per_100g: 0.0, sugar_per_100g: 1.1, glycemic_index: nil, sodium_mg_per_100g: 124.0, is_vegetarian: false},
  %{name: "Egg White",            category: :protein, calories_per_100g: 52.0,  protein_per_100g: 11.0, carbs_per_100g: 0.7,  fat_per_100g: 0.2,  fiber_per_100g: 0.0, sugar_per_100g: 0.7, glycemic_index: nil, sodium_mg_per_100g: 166.0, is_vegetarian: false},
  %{name: "Greek Yogurt (plain)", category: :dairy,   calories_per_100g: 59.0,  protein_per_100g: 10.0, carbs_per_100g: 3.6,  fat_per_100g: 0.4,  fiber_per_100g: 0.0, sugar_per_100g: 3.2, glycemic_index: 11,  sodium_mg_per_100g: 36.0,  is_vegetarian: true},
  %{name: "Cottage Cheese",       category: :dairy,   calories_per_100g: 98.0,  protein_per_100g: 11.0, carbs_per_100g: 3.4,  fat_per_100g: 4.3,  fiber_per_100g: 0.0, sugar_per_100g: 2.7, glycemic_index: 10,  sodium_mg_per_100g: 364.0, is_vegetarian: true},
  %{name: "Whole Milk",           category: :dairy,   calories_per_100g: 61.0,  protein_per_100g: 3.2,  carbs_per_100g: 4.8,  fat_per_100g: 3.3,  fiber_per_100g: 0.0, sugar_per_100g: 5.1, glycemic_index: 31,  sodium_mg_per_100g: 44.0,  is_vegetarian: true},
  %{name: "Whey Protein Powder",  category: :protein, calories_per_100g: 373.0, protein_per_100g: 75.0, carbs_per_100g: 8.0,  fat_per_100g: 5.0,  fiber_per_100g: 0.0, sugar_per_100g: 4.0, glycemic_index: nil, sodium_mg_per_100g: 200.0, is_vegetarian: true},

  # --- Plant Proteins --- (all vegetarian)
  %{name: "Lentils",              category: :legume,  calories_per_100g: 116.0, protein_per_100g: 9.0,  carbs_per_100g: 20.0, fat_per_100g: 0.4,  fiber_per_100g: 7.9, sugar_per_100g: 1.8, glycemic_index: 32,  sodium_mg_per_100g: 2.0,   is_vegetarian: true},
  %{name: "Chickpeas",            category: :legume,  calories_per_100g: 164.0, protein_per_100g: 8.9,  carbs_per_100g: 27.0, fat_per_100g: 2.6,  fiber_per_100g: 7.6, sugar_per_100g: 4.8, glycemic_index: 28,  sodium_mg_per_100g: 7.0,   is_vegetarian: true},
  %{name: "Black Beans",          category: :legume,  calories_per_100g: 132.0, protein_per_100g: 8.9,  carbs_per_100g: 24.0, fat_per_100g: 0.5,  fiber_per_100g: 8.7, sugar_per_100g: 0.3, glycemic_index: 30,  sodium_mg_per_100g: 1.0,   is_vegetarian: true},
  %{name: "Tofu (firm)",          category: :protein, calories_per_100g: 76.0,  protein_per_100g: 8.0,  carbs_per_100g: 1.9,  fat_per_100g: 4.8,  fiber_per_100g: 0.3, sugar_per_100g: 0.6, glycemic_index: nil, sodium_mg_per_100g: 7.0,   is_vegetarian: true},
  %{name: "Edamame",              category: :legume,  calories_per_100g: 121.0, protein_per_100g: 11.0, carbs_per_100g: 8.9,  fat_per_100g: 5.2,  fiber_per_100g: 5.2, sugar_per_100g: 2.2, glycemic_index: 18,  sodium_mg_per_100g: 6.0,   is_vegetarian: true},
]

IO.puts("\n--- Seeding protein ingredients ---")

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
