defmodule BetterMe.Journals do
  alias BetterMe.Journals.Actions.{CreateEntry, DeleteEntry, UpdateEntry}
  alias BetterMe.Journals.Repository

  defdelegate list_entries(user_id), to: Repository
  defdelegate get_entry(id, user_id), to: Repository
  defdelegate get_entry!(id, user_id), to: Repository
  defdelegate get_entry_for_date(user_id, date), to: Repository
  defdelegate new_entry(date \\ Date.utc_today()), to: Repository
  defdelegate change_entry(entry, attrs \\ %{}), to: Repository

  defdelegate create_entry(user_id, attrs), to: CreateEntry, as: :run
  defdelegate update_entry(entry, attrs), to: UpdateEntry, as: :run
  defdelegate delete_entry(entry), to: DeleteEntry, as: :run
  defdelegate mood_trend(user_id, weeks \\ 8), to: Repository
end
