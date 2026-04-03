defmodule BetterMe.Repo.Migrations.AddRoutineDayToWorkouts do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :routine_day_id, references(:routine_days, on_delete: :nilify_all)
    end
  end
end
