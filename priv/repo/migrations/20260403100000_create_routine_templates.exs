defmodule BetterMe.Repo.Migrations.CreateRoutineTemplates do
  use Ecto.Migration

  def change do
    create table(:routine_templates) do
      add :name, :string, null: false
      add :is_active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:routine_templates, [:user_id])

    create table(:routine_days) do
      add :name, :string, null: false
      add :position, :integer, null: false

      add :routine_template_id, references(:routine_templates, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:routine_days, [:routine_template_id])

    create table(:routine_exercises) do
      add :name, :string, null: false
      add :working_sets, :integer
      add :rep_range, :string
      add :notes, :text
      add :position, :integer, null: false
      add :routine_day_id, references(:routine_days, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:routine_exercises, [:routine_day_id])
  end
end
