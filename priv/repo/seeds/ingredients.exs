alias BetterMe.Nutrition.Schema.Ingredient
alias BetterMe.Repo

# All macros per 100g (raw). Source: USDA FoodData Central.
# Idempotent: inserts new, updates existing (picks up new fields on re-run).

ingredients = [
  # --- Fruits ---
  %{name: "Apple",       category: :fruit, calories_per_100g: 52.0,  protein_per_100g: 0.3,  carbs_per_100g: 14.0, fat_per_100g: 0.2, fiber_per_100g: 2.4, sugar_per_100g: 10.4},
  %{name: "Banana",      category: :fruit, calories_per_100g: 89.0,  protein_per_100g: 1.1,  carbs_per_100g: 23.0, fat_per_100g: 0.3, fiber_per_100g: 2.6, sugar_per_100g: 12.2},
  %{name: "Orange",      category: :fruit, calories_per_100g: 47.0,  protein_per_100g: 0.9,  carbs_per_100g: 12.0, fat_per_100g: 0.1, fiber_per_100g: 2.4, sugar_per_100g: 9.4},
  %{name: "Mango",       category: :fruit, calories_per_100g: 60.0,  protein_per_100g: 0.8,  carbs_per_100g: 15.0, fat_per_100g: 0.4, fiber_per_100g: 1.6, sugar_per_100g: 13.7},
  %{name: "Strawberry",  category: :fruit, calories_per_100g: 32.0,  protein_per_100g: 0.7,  carbs_per_100g: 7.7,  fat_per_100g: 0.3, fiber_per_100g: 2.0, sugar_per_100g: 4.9},
  %{name: "Blueberry",   category: :fruit, calories_per_100g: 57.0,  protein_per_100g: 0.7,  carbs_per_100g: 14.5, fat_per_100g: 0.3, fiber_per_100g: 2.4, sugar_per_100g: 10.0},
  %{name: "Watermelon",  category: :fruit, calories_per_100g: 30.0,  protein_per_100g: 0.6,  carbs_per_100g: 7.6,  fat_per_100g: 0.2, fiber_per_100g: 0.4, sugar_per_100g: 6.2},
  %{name: "Grapes",      category: :fruit, calories_per_100g: 69.0,  protein_per_100g: 0.7,  carbs_per_100g: 18.0, fat_per_100g: 0.2, fiber_per_100g: 0.9, sugar_per_100g: 15.5},
  %{name: "Pineapple",   category: :fruit, calories_per_100g: 50.0,  protein_per_100g: 0.5,  carbs_per_100g: 13.1, fat_per_100g: 0.1, fiber_per_100g: 1.4, sugar_per_100g: 9.9},
  %{name: "Papaya",      category: :fruit, calories_per_100g: 43.0,  protein_per_100g: 0.5,  carbs_per_100g: 11.0, fat_per_100g: 0.3, fiber_per_100g: 1.7, sugar_per_100g: 7.8},
  %{name: "Kiwi",        category: :fruit, calories_per_100g: 61.0,  protein_per_100g: 1.1,  carbs_per_100g: 14.7, fat_per_100g: 0.5, fiber_per_100g: 3.0, sugar_per_100g: 9.0},
  %{name: "Pear",        category: :fruit, calories_per_100g: 57.0,  protein_per_100g: 0.4,  carbs_per_100g: 15.2, fat_per_100g: 0.1, fiber_per_100g: 3.1, sugar_per_100g: 9.8},
  %{name: "Pomegranate", category: :fruit, calories_per_100g: 83.0,  protein_per_100g: 1.7,  carbs_per_100g: 18.7, fat_per_100g: 1.2, fiber_per_100g: 4.0, sugar_per_100g: 13.7},
  %{name: "Guava",       category: :fruit, calories_per_100g: 68.0,  protein_per_100g: 2.6,  carbs_per_100g: 14.3, fat_per_100g: 1.0, fiber_per_100g: 5.4, sugar_per_100g: 8.9},
  %{name: "Lemon",       category: :fruit, calories_per_100g: 29.0,  protein_per_100g: 1.1,  carbs_per_100g: 9.3,  fat_per_100g: 0.3, fiber_per_100g: 2.8, sugar_per_100g: 2.5},

  # --- Vegetables ---
  %{name: "Spinach",      category: :vegetable, calories_per_100g: 23.0,  protein_per_100g: 2.9, carbs_per_100g: 3.6,  fat_per_100g: 0.4, fiber_per_100g: 2.2, sugar_per_100g: 0.4},
  %{name: "Broccoli",     category: :vegetable, calories_per_100g: 34.0,  protein_per_100g: 2.8, carbs_per_100g: 6.6,  fat_per_100g: 0.4, fiber_per_100g: 2.6, sugar_per_100g: 1.7},
  %{name: "Carrot",       category: :vegetable, calories_per_100g: 41.0,  protein_per_100g: 0.9, carbs_per_100g: 9.6,  fat_per_100g: 0.2, fiber_per_100g: 2.8, sugar_per_100g: 4.7},
  %{name: "Tomato",       category: :vegetable, calories_per_100g: 18.0,  protein_per_100g: 0.9, carbs_per_100g: 3.9,  fat_per_100g: 0.2, fiber_per_100g: 1.2, sugar_per_100g: 2.6},
  %{name: "Cucumber",     category: :vegetable, calories_per_100g: 16.0,  protein_per_100g: 0.7, carbs_per_100g: 3.6,  fat_per_100g: 0.1, fiber_per_100g: 0.5, sugar_per_100g: 1.7},
  %{name: "Bell Pepper",  category: :vegetable, calories_per_100g: 31.0,  protein_per_100g: 1.0, carbs_per_100g: 6.0,  fat_per_100g: 0.3, fiber_per_100g: 2.1, sugar_per_100g: 4.2},
  %{name: "Onion",        category: :vegetable, calories_per_100g: 40.0,  protein_per_100g: 1.1, carbs_per_100g: 9.3,  fat_per_100g: 0.1, fiber_per_100g: 1.7, sugar_per_100g: 4.2},
  %{name: "Garlic",       category: :vegetable, calories_per_100g: 149.0, protein_per_100g: 6.4, carbs_per_100g: 33.1, fat_per_100g: 0.5, fiber_per_100g: 2.1, sugar_per_100g: 1.0},
  %{name: "Sweet Potato", category: :vegetable, calories_per_100g: 86.0,  protein_per_100g: 1.6, carbs_per_100g: 20.1, fat_per_100g: 0.1, fiber_per_100g: 3.0, sugar_per_100g: 4.2},
  %{name: "Potato",       category: :vegetable, calories_per_100g: 77.0,  protein_per_100g: 2.0, carbs_per_100g: 17.5, fat_per_100g: 0.1, fiber_per_100g: 2.2, sugar_per_100g: 0.8},
  %{name: "Cauliflower",  category: :vegetable, calories_per_100g: 25.0,  protein_per_100g: 1.9, carbs_per_100g: 4.9,  fat_per_100g: 0.3, fiber_per_100g: 2.0, sugar_per_100g: 1.9},
  %{name: "Cabbage",      category: :vegetable, calories_per_100g: 25.0,  protein_per_100g: 1.3, carbs_per_100g: 5.8,  fat_per_100g: 0.1, fiber_per_100g: 2.5, sugar_per_100g: 3.2},
  %{name: "Kale",         category: :vegetable, calories_per_100g: 49.0,  protein_per_100g: 4.3, carbs_per_100g: 8.8,  fat_per_100g: 0.9, fiber_per_100g: 3.6, sugar_per_100g: 2.3},
  %{name: "Zucchini",     category: :vegetable, calories_per_100g: 17.0,  protein_per_100g: 1.2, carbs_per_100g: 3.1,  fat_per_100g: 0.3, fiber_per_100g: 1.0, sugar_per_100g: 2.5},
  %{name: "Mushroom",     category: :vegetable, calories_per_100g: 22.0,  protein_per_100g: 3.1, carbs_per_100g: 3.3,  fat_per_100g: 0.3, fiber_per_100g: 1.0, sugar_per_100g: 2.0},
  %{name: "Green Beans",  category: :vegetable, calories_per_100g: 31.0,  protein_per_100g: 1.8, carbs_per_100g: 7.1,  fat_per_100g: 0.2, fiber_per_100g: 3.4, sugar_per_100g: 3.3},
  %{name: "Peas",         category: :vegetable, calories_per_100g: 81.0,  protein_per_100g: 5.4, carbs_per_100g: 14.5, fat_per_100g: 0.4, fiber_per_100g: 5.1, sugar_per_100g: 5.7},
  %{name: "Beetroot",     category: :vegetable, calories_per_100g: 43.0,  protein_per_100g: 1.6, carbs_per_100g: 9.6,  fat_per_100g: 0.2, fiber_per_100g: 2.8, sugar_per_100g: 6.8},
  %{name: "Eggplant",     category: :vegetable, calories_per_100g: 25.0,  protein_per_100g: 1.0, carbs_per_100g: 5.9,  fat_per_100g: 0.2, fiber_per_100g: 3.0, sugar_per_100g: 3.5},
  %{name: "Asparagus",    category: :vegetable, calories_per_100g: 20.0,  protein_per_100g: 2.2, carbs_per_100g: 3.9,  fat_per_100g: 0.1, fiber_per_100g: 2.1, sugar_per_100g: 1.9},
  %{name: "Corn",         category: :vegetable, calories_per_100g: 86.0,  protein_per_100g: 3.3, carbs_per_100g: 19.0, fat_per_100g: 1.4, fiber_per_100g: 2.7, sugar_per_100g: 3.2},
  %{name: "Celery",       category: :vegetable, calories_per_100g: 16.0,  protein_per_100g: 0.7, carbs_per_100g: 3.0,  fat_per_100g: 0.2, fiber_per_100g: 1.6, sugar_per_100g: 1.3},
]

IO.puts("\n--- Seeding ingredients ---")

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
