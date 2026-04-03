defmodule BetterMe.Repo.Migrations.AddSubstitutionsToRoutineExercises do
  use Ecto.Migration

  def change do
    alter table(:routine_exercises) do
      add :substitution_1, :string
      add :substitution_2, :string
    end
  end
end
