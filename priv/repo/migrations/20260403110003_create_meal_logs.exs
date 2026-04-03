defmodule BetterMe.Repo.Migrations.CreateMealLogs do
  use Ecto.Migration

  def change do
    create table(:meal_logs) do
      add :date, :date, null: false
      add :servings, :float, null: false, default: 1.0
      add :meal_type, :string, null: false
      add :recipe_id, references(:recipes, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:meal_logs, [:user_id])
    create index(:meal_logs, [:user_id, :date])
    create index(:meal_logs, [:recipe_id])
  end
end
