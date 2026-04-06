defmodule BetterMe.Repo.Migrations.AddSodiumToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add :sodium_mg_per_100g, :float, null: true
    end
  end
end
