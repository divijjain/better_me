defmodule BetterMe.OpenAI.Embeddings do
  @moduledoc """
  Calls the OpenAI embeddings API to embed text into a 1536-dimensional vector
  for semantic similarity search via pgvector.

  ## Model choice: text-embedding-3-small

  We chose `text-embedding-3-small` over alternatives for the following reasons:

  - **Battle-tested** — the most widely used embedding model in production RAG
    systems. Well documented, stable API, predictable behaviour.
  - **Right size** — 1536 dimensions is the sweet spot: meaningfully more
    expressive than 768-dim models, without the cost of 3072-dim large variants.
  - **Cost** — $0.02 per 1M tokens. At personal-app scale (hundreds of journal
    entries, meal logs, workouts) this rounds to fractions of a cent per month.
  - **Speed** — faster than `text-embedding-3-large` with minimal quality drop
    for retrieval tasks of this nature (short personal logs, not legal documents).

  ## Switching models later

  If you want to switch to a different provider or model (Voyage, Ollama, etc.),
  update this module. **Important:** changing the model invalidates all existing
  embeddings — the vector spaces are incompatible. You must re-embed all records
  by running a backfill task after switching:

      mix run priv/repo/tasks/backfill_embeddings.exs

  Do not mix vectors from different models in the same embeddings table.
  """

  @openai_url "https://api.openai.com/v1/embeddings"
  @model "text-embedding-3-small"

  @doc """
  Embeds a single string. Returns {:ok, %Pgvector{}} | {:error, reason}.
  """
  def embed(text) when is_binary(text) do
    api_key = Application.get_env(:better_me, :openai)[:api_key]

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      body = %{input: text, model: @model}

      case Req.post(@openai_url,
             json: body,
             headers: [{"Authorization", "Bearer #{api_key}"}],
             receive_timeout: 30_000
           ) do
        {:ok, %{status: 200, body: %{"data" => [%{"embedding" => vector} | _]}}} ->
          {:ok, Pgvector.new(vector)}

        {:ok, %{status: status, body: body}} ->
          {:error, {status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
