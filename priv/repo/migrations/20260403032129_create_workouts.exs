defmodule BetterMe.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :date, :date, null: false
      add :type, :string, null: false
      add :duration, :integer
      add :notes, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:workouts, [:user_id])
    create index(:workouts, [:user_id, :date])
  end
end
