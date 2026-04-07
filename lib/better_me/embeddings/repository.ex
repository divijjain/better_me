defmodule BetterMe.Embeddings.Repository do
  import Ecto.Query

  alias BetterMe.Embeddings.Schema.Embedding
  alias BetterMe.Repo

  def upsert(user_id, source_type, source_id, content, vector) do
    attrs = %{
      user_id: user_id,
      source_type: source_type,
      source_id: source_id,
      content: content,
      embedding: vector
    }

    %Embedding{}
    |> Embedding.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:content, :embedding, :inserted_at]},
      conflict_target: [:user_id, :source_type, :source_id]
    )
  end

  def delete(source_type, source_id) do
    Repo.delete_all(
      from e in Embedding,
        where: e.source_type == ^source_type and e.source_id == ^source_id
    )
  end

  # Cosine similarity search — returns top-k most similar embeddings for a user.
  # The query vector should be a Pgvector.Ecto.Vector or a list of floats.
  def similarity_search(user_id, query_vector, source_types \\ nil, limit \\ 5) do
    base =
      from e in Embedding,
        where: e.user_id == ^user_id,
        order_by: fragment("embedding <=> ?", ^query_vector),
        limit: ^limit,
        select: %{
          id: e.id,
          source_type: e.source_type,
          source_id: e.source_id,
          content: e.content,
          distance: fragment("embedding <=> ?", ^query_vector)
        }

    query =
      if source_types do
        where(base, [e], e.source_type in ^source_types)
      else
        base
      end

    Repo.all(query)
  end
end
