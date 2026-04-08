alias BetterMe.Nutrition.Schema.Ingredient
alias BetterMe.Repo

# All macros per 100g (raw/dry unless noted). Source: USDA FoodData Central / IFCT 2017.
# All items are vegetarian.

ingredients = [
  # --- Millets ---
  %{name: "Pearl Millet / Bajra (raw)",    category: :grain, calories_per_100g: 361.0, protein_per_100g: 11.0, carbs_per_100g: 67.0, fat_per_100g: 5.0, fiber_per_100g: 8.5,  sugar_per_100g: 0.0, glycemic_index: 54, sodium_mg_per_100g: 10.0, is_vegetarian: true},
  %{name: "Finger Millet / Ragi (raw)",    category: :grain, calories_per_100g: 336.0, protein_per_100g: 7.3,  carbs_per_100g: 72.0, fat_per_100g: 1.5, fiber_per_100g: 3.6,  sugar_per_100g: 0.0, glycemic_index: 68, sodium_mg_per_100g: 11.0, is_vegetarian: true},
  %{name: "Foxtail Millet / Kangni (raw)", category: :grain, calories_per_100g: 351.0, protein_per_100g: 12.0, carbs_per_100g: 63.0, fat_per_100g: 4.3, fiber_per_100g: 8.0,  sugar_per_100g: 0.0, glycemic_index: 50, sodium_mg_per_100g: 5.0,  is_vegetarian: true},
  %{name: "Sorghum / Jowar (raw)",         category: :grain, calories_per_100g: 329.0, protein_per_100g: 10.0, carbs_per_100g: 72.0, fat_per_100g: 3.5, fiber_per_100g: 6.7,  sugar_per_100g: 1.0, glycemic_index: 62, sodium_mg_per_100g: 6.0,  is_vegetarian: true},
  %{name: "Kodo Millet (raw)",             category: :grain, calories_per_100g: 353.0, protein_per_100g: 8.3,  carbs_per_100g: 65.0, fat_per_100g: 3.6, fiber_per_100g: 9.0,  sugar_per_100g: 0.0, glycemic_index: 50, sodium_mg_per_100g: 6.0,  is_vegetarian: true},
  %{name: "Little Millet / Kutki (raw)",   category: :grain, calories_per_100g: 341.0, protein_per_100g: 7.7,  carbs_per_100g: 67.0, fat_per_100g: 4.7, fiber_per_100g: 7.6,  sugar_per_100g: 0.0, glycemic_index: 52, sodium_mg_per_100g: 8.0,  is_vegetarian: true},
  %{name: "Barnyard Millet / Sanwa (raw)", category: :grain, calories_per_100g: 342.0, protein_per_100g: 6.2,  carbs_per_100g: 65.0, fat_per_100g: 2.7, fiber_per_100g: 10.1, sugar_per_100g: 0.0, glycemic_index: 41, sodium_mg_per_100g: 6.0,  is_vegetarian: true},
  %{name: "Proso Millet (raw)",            category: :grain, calories_per_100g: 378.0, protein_per_100g: 11.0, carbs_per_100g: 73.0, fat_per_100g: 4.2, fiber_per_100g: 8.5,  sugar_per_100g: 0.0, glycemic_index: 70, sodium_mg_per_100g: 5.0,  is_vegetarian: true},
  %{name: "Amaranth (raw)",                category: :grain, calories_per_100g: 371.0, protein_per_100g: 14.0, carbs_per_100g: 65.0, fat_per_100g: 7.0, fiber_per_100g: 6.7,  sugar_per_100g: 1.7, glycemic_index: 35, sodium_mg_per_100g: 4.0,  is_vegetarian: true},

  # --- Pulses / Dals ---
  %{name: "Red Lentils / Masoor Dal (raw)",    category: :legume, calories_per_100g: 352.0, protein_per_100g: 25.0, carbs_per_100g: 60.0, fat_per_100g: 1.1, fiber_per_100g: 11.0, sugar_per_100g: 2.0, glycemic_index: 21, sodium_mg_per_100g: 6.0,  is_vegetarian: true},
  %{name: "Yellow Moong Dal (raw)",            category: :legume, calories_per_100g: 347.0, protein_per_100g: 24.0, carbs_per_100g: 63.0, fat_per_100g: 1.2, fiber_per_100g: 7.6,  sugar_per_100g: 6.0, glycemic_index: 25, sodium_mg_per_100g: 15.0, is_vegetarian: true},
  %{name: "Whole Green Moong (raw)",           category: :legume, calories_per_100g: 347.0, protein_per_100g: 24.0, carbs_per_100g: 63.0, fat_per_100g: 1.2, fiber_per_100g: 16.0, sugar_per_100g: 6.6, glycemic_index: 25, sodium_mg_per_100g: 15.0, is_vegetarian: true},
  %{name: "Toor / Arhar Dal (raw)",            category: :legume, calories_per_100g: 343.0, protein_per_100g: 22.0, carbs_per_100g: 63.0, fat_per_100g: 1.5, fiber_per_100g: 15.0, sugar_per_100g: 0.0, glycemic_index: 29, sodium_mg_per_100g: 17.0, is_vegetarian: true},
  %{name: "Urad Dal (raw)",                    category: :legume, calories_per_100g: 341.0, protein_per_100g: 25.0, carbs_per_100g: 59.0, fat_per_100g: 1.6, fiber_per_100g: 18.0, sugar_per_100g: 0.0, glycemic_index: 29, sodium_mg_per_100g: 38.0, is_vegetarian: true},
  %{name: "Chana Dal (raw)",                   category: :legume, calories_per_100g: 364.0, protein_per_100g: 20.0, carbs_per_100g: 61.0, fat_per_100g: 5.0, fiber_per_100g: 17.0, sugar_per_100g: 0.0, glycemic_index: 11, sodium_mg_per_100g: 24.0, is_vegetarian: true},
  %{name: "Whole Black Chickpeas / Kala Chana (raw)", category: :legume, calories_per_100g: 364.0, protein_per_100g: 20.0, carbs_per_100g: 61.0, fat_per_100g: 5.0, fiber_per_100g: 17.0, sugar_per_100g: 0.0, glycemic_index: 28, sodium_mg_per_100g: 24.0, is_vegetarian: true},
  %{name: "Rajma / Kidney Beans (raw)",        category: :legume, calories_per_100g: 333.0, protein_per_100g: 24.0, carbs_per_100g: 60.0, fat_per_100g: 0.8, fiber_per_100g: 15.0, sugar_per_100g: 2.2, glycemic_index: 24, sodium_mg_per_100g: 28.0, is_vegetarian: true},
  %{name: "Moth Beans / Matki (raw)",          category: :legume, calories_per_100g: 343.0, protein_per_100g: 23.0, carbs_per_100g: 62.0, fat_per_100g: 1.6, fiber_per_100g: 4.5,  sugar_per_100g: 0.0, glycemic_index: 35, sodium_mg_per_100g: 30.0, is_vegetarian: true},
  %{name: "Cowpea / Lobia (raw)",              category: :legume, calories_per_100g: 336.0, protein_per_100g: 24.0, carbs_per_100g: 60.0, fat_per_100g: 1.3, fiber_per_100g: 11.0, sugar_per_100g: 0.0, glycemic_index: 33, sodium_mg_per_100g: 16.0, is_vegetarian: true},
  %{name: "Horse Gram / Kulthi (raw)",         category: :legume, calories_per_100g: 321.0, protein_per_100g: 22.0, carbs_per_100g: 57.0, fat_per_100g: 0.5, fiber_per_100g: 5.3,  sugar_per_100g: 0.0, glycemic_index: 29, sodium_mg_per_100g: 26.0, is_vegetarian: true},
  %{name: "Field Peas / Matar Dal (raw)",      category: :legume, calories_per_100g: 341.0, protein_per_100g: 25.0, carbs_per_100g: 60.0, fat_per_100g: 1.1, fiber_per_100g: 26.0, sugar_per_100g: 0.0, glycemic_index: 22, sodium_mg_per_100g: 5.0,  is_vegetarian: true},
  %{name: "Val / Hyacinth Beans (raw)",        category: :legume, calories_per_100g: 347.0, protein_per_100g: 24.0, carbs_per_100g: 61.0, fat_per_100g: 0.9, fiber_per_100g: 5.0,  sugar_per_100g: 0.0, glycemic_index: 30, sodium_mg_per_100g: 20.0, is_vegetarian: true},
]

IO.puts("\n--- Seeding millets & pulses ---")

Enum.each(ingredients, fn attrs ->
  case Repo.get_by(Ingredient, name: attrs.name) do
    nil ->
      case %Ingredient{} |> Ingredient.changeset(attrs) |> Repo.insert() do
        {:ok, i}     -> IO.puts("  Created: #{i.name}")
        {:error, cs} -> IO.puts("  Failed:  #{attrs.name} — #{inspect(cs.errors)}")
      end

    existing ->
      case existing |> Ingredient.changeset(attrs) |> Repo.update() do
        {:ok, i}     -> IO.puts("  Updated: #{i.name}")
        {:error, cs} -> IO.puts("  Failed to update: #{attrs.name} — #{inspect(cs.errors)}")
      end
  end
end)
