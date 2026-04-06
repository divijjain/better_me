defmodule BetterMe.Repo.Migrations.AddGlycemicIndexToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add :glycemic_index, :integer, null: true
    end
  end
end
