defmodule BetterMe.Repo.Migrations.AddFiberAndSugarToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add :fiber_per_100g, :float, default: 0.0, null: false
      add :sugar_per_100g, :float, default: 0.0, null: false
    end
  end
end
