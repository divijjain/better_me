defmodule BetterMe.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles) do
      add :age,            :integer, null: false
      add :weight_kg,      :float,   null: false
      add :height_cm,      :float,   null: false
      add :gender,         :string,  null: false
      add :activity_level, :string,  null: false
      add :protein_pct,    :integer, null: false, default: 30
      add :carbs_pct,      :integer, null: false, default: 40
      add :user_id,        references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:user_profiles, [:user_id])
  end
end
