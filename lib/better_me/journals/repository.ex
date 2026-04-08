defmodule BetterMe.Journals.Repository do
  import Ecto.Query

  alias BetterMe.Journals.Schema.JournalEntry
  alias BetterMe.Repo

  def list_entries(user_id) do
    JournalEntry
    |> where(user_id: ^user_id)
    |> order_by([e], desc: e.date)
    |> Repo.all()
  end

  def get_entry(id, user_id) do
    case Repo.get_by(JournalEntry, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  def get_entry!(id, user_id) do
    case get_entry(id, user_id) do
      {:ok, entry} -> entry
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: JournalEntry
    end
  end

  def get_entry_for_date(user_id, date) do
    case Repo.get_by(JournalEntry, user_id: user_id, date: date) do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  def new_entry(date \\ Date.utc_today()), do: %JournalEntry{date: date}

  def create_entry(user_id, attrs) do
    %JournalEntry{user_id: user_id}
    |> JournalEntry.changeset(attrs)
    |> Repo.insert()
  end

  def update_entry(entry, attrs) do
    entry
    |> JournalEntry.changeset(attrs)
    |> Repo.update()
  end

  def delete_entry(entry) do
    Repo.delete(entry)
  end

  def change_entry(entry, attrs \\ %{}) do
    JournalEntry.changeset(entry, attrs)
  end

  def mood_trend(user_id, weeks \\ 8) do
    since = Date.add(Date.utc_today(), -(weeks * 7))

    Repo.all(
      from j in JournalEntry,
        where: j.user_id == ^user_id and j.date >= ^since and not is_nil(j.mood),
        group_by: fragment("date_trunc('week', ?::timestamp)", j.date),
        order_by: fragment("date_trunc('week', ?::timestamp)", j.date),
        select: %{
          week: fragment("date_trunc('week', ?::timestamp)::date", j.date),
          avg_mood: fragment("round(avg(?)::numeric, 1)", j.mood)
        }
    )
  end
end
