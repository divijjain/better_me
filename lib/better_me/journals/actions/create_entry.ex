defmodule BetterMe.Journals.Actions.CreateEntry do
  alias BetterMe.Embeddings.Jobs.EmbedJob
  alias BetterMe.Journals.Repository

  def run(user_id, attrs) do
    case Repository.create_entry(user_id, attrs) do
      {:ok, entry} = result ->
        EmbedJob.enqueue(user_id, "journal_entry", entry.id)
        result

      error ->
        error
    end
  end
end
