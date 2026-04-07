defmodule BetterMe.Anthropic.Chat do
  @moduledoc """
  Calls the Anthropic Messages API to generate a grounded insight answer.

  Used exclusively by InsightWorkflow — receives retrieved RAG chunks as context
  and returns Claude's answer.
  """

  @api_url "https://api.anthropic.com/v1/messages"
  @model "claude-haiku-4-5-20251001"
  @max_tokens 1024

  @system_prompt """
  You are a personal health and wellness assistant. You have access to the user's
  actual journal entries, nutrition logs, and workout records. Answer the user's
  question using only the data provided — do not guess or make up information.
  Be concise and specific. If the data doesn't contain enough information to
  answer confidently, say so.
  """

  @doc """
  Send a question and retrieved context chunks to Claude.
  Returns {:ok, answer_string} | {:error, reason}.
  """
  def ask(question, chunks) when is_binary(question) and is_list(chunks) do
    api_key = Application.get_env(:better_me, :anthropic)[:api_key]

    if is_nil(api_key) || api_key == "" do
      {:error, :missing_api_key}
    else
      context = build_context(chunks)

      user_message = """
      Here is relevant data from my personal logs:

      #{context}

      My question: #{question}
      """

      body = %{
        model: @model,
        max_tokens: @max_tokens,
        system: @system_prompt,
        messages: [%{role: "user", content: user_message}]
      }

      case Req.post(@api_url,
             json: body,
             headers: [
               {"x-api-key", api_key},
               {"anthropic-version", "2023-06-01"}
             ],
             receive_timeout: 60_000
           ) do
        {:ok, %{status: 200, body: %{"content" => [%{"text" => text} | _]}}} ->
          {:ok, text}

        {:ok, %{status: status, body: body}} ->
          {:error, {status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp build_context(chunks) do
    chunks
    |> Enum.with_index(1)
    |> Enum.map(fn {chunk, i} ->
      "[#{i}] (#{chunk.source_type})\n#{chunk.content}"
    end)
    |> Enum.join("\n\n")
  end
end
