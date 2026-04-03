defmodule BetterMe.Repo.Migrations.AddCategoryAndBrandToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add :category, :string, null: false, default: "other"
      add :brand, :string, null: true
    end

    create index(:ingredients, [:category])
  end
end
