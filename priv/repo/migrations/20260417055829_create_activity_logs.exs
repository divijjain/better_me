defmodule BetterMe.Repo.Migrations.CreateActivityLogs do
  use Ecto.Migration

  def change do
    create table(:activity_logs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :steps, :integer
      add :active_kcal, :float
      add :resting_hr_bpm, :integer
      add :sleep_minutes, :integer

      timestamps()
    end

    create unique_index(:activity_logs, [:user_id, :date])
    create index(:activity_logs, [:user_id])
  end
end
