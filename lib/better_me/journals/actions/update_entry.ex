defmodule BetterMe.Journals.Actions.UpdateEntry do
  alias BetterMe.Embeddings.Jobs.EmbedJob
  alias BetterMe.Journals.Repository

  def run(entry, attrs) do
    case Repository.update_entry(entry, attrs) do
      {:ok, updated} = result ->
        EmbedJob.enqueue(updated.user_id, "journal_entry", updated.id)
        result

      error ->
        error
    end
  end
end
