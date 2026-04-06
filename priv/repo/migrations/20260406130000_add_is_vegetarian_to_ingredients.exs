defmodule BetterMe.Repo.Migrations.AddIsVegetarianToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add :is_vegetarian, :boolean, default: false, null: false
    end
  end
end
