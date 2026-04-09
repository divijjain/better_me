defmodule BetterMe.Factory do
  use ExMachina.Ecto, repo: BetterMe.Repo

  alias BetterMe.Accounts.User
  alias BetterMe.Habits.{Habit, HabitLog}
  alias BetterMe.Health.Schema.BodyMetric
  alias BetterMe.Journals.Schema.JournalEntry
  alias BetterMe.Nutrition.Schema.{Ingredient, MealLog, Recipe, RecipeIngredient}
  alias BetterMe.Todos.Schema.Todo

  alias BetterMe.Workouts.Schema.{
    Exercise,
    ExerciseSet,
    RoutineDay,
    RoutineExercise,
    RoutineTemplate,
    Workout
  }

  # ---------------------------------------------------------------------------
  # Accounts
  # ---------------------------------------------------------------------------

  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@example.com"),
      hashed_password: Bcrypt.hash_pwd_salt("hello world!")
    }
  end

  def oauth_user_factory do
    struct!(
      user_factory(),
      %{
        provider: "google",
        provider_uid: sequence(:provider_uid, &"google_uid_#{&1}"),
        hashed_password: nil,
        confirmed_at: DateTime.utc_now(:second)
      }
    )
  end

  # ---------------------------------------------------------------------------
  # Habits
  # ---------------------------------------------------------------------------

  def habit_factory do
    %Habit{
      name: sequence(:habit_name, &"Habit #{&1}"),
      category: :health,
      frequency: :daily,
      active: true,
      user: build(:user)
    }
  end

  def habit_log_factory do
    %HabitLog{
      date: Date.utc_today(),
      habit: build(:habit)
    }
  end

  # ---------------------------------------------------------------------------
  # Tasks (Todo schema)
  # ---------------------------------------------------------------------------

  def todo_factory do
    %Todo{
      title: sequence(:todo_title, &"Task #{&1}"),
      category: :personal,
      priority: :medium,
      completed: false,
      user: build(:user)
    }
  end

  # ---------------------------------------------------------------------------
  # Health
  # ---------------------------------------------------------------------------

  def body_metric_factory do
    %BodyMetric{
      date: Date.utc_today(),
      weight: 75.0,
      measurements: %{},
      user: build(:user)
    }
  end

  # ---------------------------------------------------------------------------
  # Journals
  # ---------------------------------------------------------------------------

  def journal_entry_factory do
    %JournalEntry{
      date: Date.utc_today(),
      body: sequence(:journal_body, &"Journal entry #{&1}"),
      mood: 3,
      tags: [],
      user: build(:user)
    }
  end

  # ---------------------------------------------------------------------------
  # Nutrition
  # ---------------------------------------------------------------------------

  def ingredient_factory do
    %Ingredient{
      name: sequence(:ingredient_name, &"Ingredient #{&1}"),
      category: :protein,
      calories_per_100g: 200.0,
      protein_per_100g: 25.0,
      carbs_per_100g: 5.0,
      fat_per_100g: 8.0,
      fiber_per_100g: 0.0,
      sugar_per_100g: 0.0,
      is_vegetarian: false
    }
  end

  def recipe_factory do
    %Recipe{
      title: sequence(:recipe_title, &"Recipe #{&1}"),
      tags: [],
      user: build(:user)
    }
  end

  def recipe_ingredient_factory do
    %RecipeIngredient{
      quantity_grams: 100.0,
      recipe: build(:recipe),
      ingredient: build(:ingredient)
    }
  end

  def meal_log_factory do
    %MealLog{
      date: Date.utc_today(),
      meal_type: :lunch,
      servings: 1.0,
      recipe: build(:recipe),
      user: build(:user)
    }
  end

  # ---------------------------------------------------------------------------
  # Workouts
  # ---------------------------------------------------------------------------

  def workout_factory do
    %Workout{
      date: Date.utc_today(),
      type: :strength,
      user: build(:user)
    }
  end

  def exercise_factory do
    %Exercise{
      name: sequence(:exercise_name, &"Exercise #{&1}"),
      sets: 3,
      is_pr: false,
      workout: build(:workout)
    }
  end

  def exercise_set_factory do
    %ExerciseSet{
      set_number: 1,
      weight: 80.0,
      reps: 5,
      is_pr: false,
      completed: false,
      exercise: build(:exercise)
    }
  end

  def routine_template_factory do
    %RoutineTemplate{
      name: sequence(:routine_name, &"Routine #{&1}"),
      is_active: true,
      user: build(:user)
    }
  end

  def routine_day_factory do
    %RoutineDay{
      name: sequence(:day_name, &"Day #{&1}"),
      position: 1,
      routine_template: build(:routine_template)
    }
  end

  def routine_exercise_factory do
    %RoutineExercise{
      name: sequence(:routine_exercise_name, &"Exercise #{&1}"),
      position: 1,
      working_sets: 3,
      routine_day: build(:routine_day)
    }
  end
end
