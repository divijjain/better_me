defmodule BetterMe.Insights.InsightWorkflow do
  @moduledoc """
  Fixed-step RAG workflow for answering natural language questions about the
  user's personal data.

  Steps (always in this order — code controls the flow, not the LLM):
    1. Embed the question via OpenAI
    2. Similarity search journals, nutrition, and workouts in pgvector
    3. Send retrieved chunks + question to Claude
    4. Return the answer

  This is intentionally a workflow, not a Jido agent. The retrieval steps never
  change based on the question — we always search all three domains and let Claude
  decide what's relevant from the chunks. Upgrade to an agent only if the LLM
  needs to decide dynamically which domains to query.
  """

  alias BetterMe.Anthropic.Chat
  alias BetterMe.Embeddings.Repository, as: EmbeddingsRepo
  alias BetterMe.OpenAI.Embeddings, as: EmbeddingsAPI

  @source_types ~w(journal_entry meal_log workout)
  @chunks_per_type 3

  @doc """
  Run the insight workflow for a user's question.
  Returns {:ok, answer} | {:error, reason}.
  """
  def run(user_id, question) when is_integer(user_id) and is_binary(question) do
    with {:ok, query_vector} <- EmbeddingsAPI.embed(question),
         chunks <- retrieve(user_id, query_vector) do
      Chat.ask(question, chunks)
    end
  end

  # Retrieve top chunks across all source types.
  defp retrieve(user_id, query_vector) do
    EmbeddingsRepo.similarity_search(
      user_id,
      query_vector,
      @source_types,
      @chunks_per_type * length(@source_types)
    )
  end
end
