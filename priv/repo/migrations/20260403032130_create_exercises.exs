defmodule BetterMe.Repo.Migrations.CreateExercises do
  use Ecto.Migration

  def change do
    create table(:exercises) do
      add :name, :string, null: false
      add :sets, :integer
      add :reps, :integer
      add :weight, :float
      add :rpe, :integer
      add :is_pr, :boolean, default: false, null: false
      add :workout_id, references(:workouts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:exercises, [:workout_id])
  end
end
