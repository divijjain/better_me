defmodule BetterMe.Embeddings do
  alias BetterMe.Embeddings.Repository

  defdelegate upsert(user_id, source_type, source_id, content, vector), to: Repository
  defdelegate delete(source_type, source_id), to: Repository

  defdelegate similarity_search(user_id, query_vector, source_types \\ nil, limit \\ 5),
    to: Repository
end
