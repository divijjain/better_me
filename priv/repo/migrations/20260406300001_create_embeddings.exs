defmodule BetterMe.Repo.Migrations.CreateEmbeddings do
  use Ecto.Migration

  def up do
    create table(:embeddings) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :source_type, :string, null: false
      add :source_id, :integer, null: false
      add :content, :text, null: false
      add :embedding, :vector, size: 1536

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:embeddings, [:user_id])
    create index(:embeddings, [:source_type, :source_id])

    create unique_index(:embeddings, [:user_id, :source_type, :source_id],
             name: :embeddings_user_source_unique
           )

    # IVFFlat index for cosine similarity search — built after data is loaded
    # Lists value: roughly sqrt(number of rows). Start with 10 for dev.
    execute """
    CREATE INDEX embeddings_vector_idx ON embeddings
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 10)
    """
  end

  def down do
    drop_if_exists index(:embeddings, [:user_id])
    drop_if_exists index(:embeddings, [:source_type, :source_id])

    drop_if_exists index(:embeddings, [:user_id, :source_type, :source_id],
                     name: :embeddings_user_source_unique
                   )

    execute "DROP INDEX IF EXISTS embeddings_vector_idx"
    drop_if_exists table(:embeddings)
  end
end
