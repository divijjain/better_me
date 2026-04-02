defmodule BetterMe.Repo.Migrations.CreateHabits do
  use Ecto.Migration

  def change do
    create table(:habits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :category, :string, null: false
      add :frequency, :string, null: false, default: "daily"
      add :active, :boolean, null: false, default: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:habits, [:user_id])

    create table(:habit_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date, :date, null: false
      add :completed, :boolean, null: false, default: true
      add :note, :string
      add :habit_id, references(:habits, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:habit_logs, [:habit_id])
    create unique_index(:habit_logs, [:habit_id, :date])
  end
end
