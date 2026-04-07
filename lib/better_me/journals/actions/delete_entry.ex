defmodule BetterMe.Journals.Actions.DeleteEntry do
  alias BetterMe.Embeddings
  alias BetterMe.Journals.Repository

  def run(entry) do
    case Repository.delete_entry(entry) do
      {:ok, _} = result ->
        Embeddings.delete("journal_entry", entry.id)
        result

      error ->
        error
    end
  end
end
