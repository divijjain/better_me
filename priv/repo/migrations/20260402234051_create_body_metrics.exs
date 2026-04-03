defmodule BetterMe.Repo.Migrations.CreateBodyMetrics do
  use Ecto.Migration

  def change do
    create table(:body_metrics) do
      add :date,         :date,  null: false
      add :weight,       :float
      add :body_fat_pct, :float
      add :measurements, :map,   default: %{}
      add :user_id,      references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:body_metrics, [:user_id])
    create unique_index(:body_metrics, [:user_id, :date])
  end
end
