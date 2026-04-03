defmodule BetterMe.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add :name, :string, null: false
      add :calories_per_100g, :float, null: false
      add :protein_per_100g, :float, null: false
      add :carbs_per_100g, :float, null: false
      add :fat_per_100g, :float, null: false

      timestamps()
    end

    create unique_index(:ingredients, [:name])
  end
end
