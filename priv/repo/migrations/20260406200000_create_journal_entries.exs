defmodule BetterMe.Repo.Migrations.CreateJournalEntries do
  use Ecto.Migration

  def change do
    create table(:journal_entries) do
      add :date, :date, null: false
      add :body, :text, null: false
      add :mood, :integer, null: true
      add :tags, {:array, :string}, default: [], null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:journal_entries, [:user_id])

    create unique_index(:journal_entries, [:user_id, :date],
             name: :journal_entries_user_date_unique
           )
  end
end
