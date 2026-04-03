defmodule BetterMe.Repo.Migrations.CreateExerciseSets do
  use Ecto.Migration

  def change do
    create table(:exercise_sets) do
      add :set_number, :integer, null: false
      add :weight, :float
      add :reps, :integer
      add :is_pr, :boolean, default: false, null: false
      add :completed, :boolean, default: false, null: false
      add :exercise_id, references(:exercises, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:exercise_sets, [:exercise_id])
  end
end
