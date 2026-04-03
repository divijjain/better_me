defmodule BetterMe.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string, null: false
      add :category, :string, null: false
      add :priority, :string, null: false, default: "medium"
      add :due_date, :date
      add :completed, :boolean, null: false, default: false
      add :repeat, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:todos, [:user_id])
    create index(:todos, [:user_id, :completed])
  end
end
