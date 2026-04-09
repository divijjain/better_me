defmodule BetterMe.JournalsTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Journals
  alias BetterMe.Journals.Schema.JournalEntry

  import BetterMe.Factory

  setup do
    %{user: insert(:user)}
  end

  describe "create_entry/2" do
    test "creates an entry with valid attrs", %{user: user} do
      attrs = %{date: Date.utc_today(), body: "Good day", mood: 4}
      assert {:ok, entry} = Journals.create_entry(user.id, attrs)
      assert entry.body == "Good day"
      assert entry.mood == 4
      assert entry.date == Date.utc_today()
      assert entry.user_id == user.id
    end

    test "returns error when body is missing", %{user: user} do
      assert {:error, changeset} =
               Journals.create_entry(user.id, %{date: Date.utc_today()})

      assert %{body: [_]} = errors_on(changeset)
    end

    test "returns error when date is missing", %{user: user} do
      assert {:error, changeset} = Journals.create_entry(user.id, %{body: "Something"})
      assert %{date: [_]} = errors_on(changeset)
    end

    test "returns error for out-of-range mood", %{user: user} do
      attrs = %{date: Date.utc_today(), body: "Ok", mood: 6}
      assert {:error, changeset} = Journals.create_entry(user.id, attrs)
      assert %{mood: [_]} = errors_on(changeset)
    end

    test "returns error for duplicate date", %{user: user} do
      date = Date.utc_today()
      assert {:ok, _} = Journals.create_entry(user.id, %{date: date, body: "First"})

      assert {:error, changeset} =
               Journals.create_entry(user.id, %{date: date, body: "Second"})

      assert changeset.valid? == false
    end

    test "allows tags", %{user: user} do
      attrs = %{date: Date.utc_today(), body: "Tagged", tags: ["health", "focus"]}
      assert {:ok, entry} = Journals.create_entry(user.id, attrs)
      assert entry.tags == ["health", "focus"]
    end
  end

  describe "list_entries/1" do
    test "returns entries for the user ordered by date desc", %{user: user} do
      yesterday = Date.add(Date.utc_today(), -1)
      today = Date.utc_today()

      {:ok, e1} = Journals.create_entry(user.id, %{date: yesterday, body: "Yesterday"})
      {:ok, e2} = Journals.create_entry(user.id, %{date: today, body: "Today"})

      [first, second] = Journals.list_entries(user.id)
      assert first.id == e2.id
      assert second.id == e1.id
    end

    test "does not return entries from other users", %{user: user} do
      insert(:journal_entry, user: insert(:user))
      entries = Journals.list_entries(user.id)
      assert Enum.all?(entries, &(&1.user_id == user.id))
    end
  end

  describe "get_entry/2" do
    test "returns {:ok, entry} for valid owner", %{user: user} do
      entry = insert(:journal_entry, user: user)
      assert {:ok, found} = Journals.get_entry(entry.id, user.id)
      assert found.id == entry.id
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      entry = insert(:journal_entry, user: insert(:user))
      assert {:error, :not_found} = Journals.get_entry(entry.id, user.id)
    end

    test "returns {:error, :not_found} for nonexistent id", %{user: user} do
      assert {:error, :not_found} = Journals.get_entry(0, user.id)
    end
  end

  describe "get_entry_for_date/2" do
    test "returns entry for the given date", %{user: user} do
      date = Date.utc_today()
      entry = insert(:journal_entry, user: user, date: date)
      assert {:ok, found} = Journals.get_entry_for_date(user.id, date)
      assert found.id == entry.id
    end

    test "returns {:error, :not_found} when no entry for date", %{user: user} do
      assert {:error, :not_found} = Journals.get_entry_for_date(user.id, ~D[2000-01-01])
    end
  end

  describe "update_entry/2" do
    test "updates the body", %{user: user} do
      entry = insert(:journal_entry, user: user)
      assert {:ok, updated} = Journals.update_entry(entry, %{body: "Updated content"})
      assert updated.body == "Updated content"
    end

    test "updates the mood", %{user: user} do
      entry = insert(:journal_entry, user: user, mood: 3)
      assert {:ok, updated} = Journals.update_entry(entry, %{mood: 5})
      assert updated.mood == 5
    end
  end

  describe "delete_entry/1" do
    test "deletes the entry", %{user: user} do
      entry = insert(:journal_entry, user: user)
      assert {:ok, _} = Journals.delete_entry(entry)
      assert {:error, :not_found} = Journals.get_entry(entry.id, user.id)
    end
  end

  describe "mood_trend/2" do
    test "returns empty list when no entries", %{user: user} do
      assert Journals.mood_trend(user.id) == []
    end

    test "returns weekly averaged mood data", %{user: user} do
      insert(:journal_entry, user: user, date: Date.utc_today(), mood: 4)
      trend = Journals.mood_trend(user.id)
      assert [%{week: _, avg_mood: _}] = trend
    end
  end

  # ---------------------------------------------------------------------------
  # Changesets
  # ---------------------------------------------------------------------------

  describe "JournalEntry changeset" do
    test "invalid when mood is below 1" do
      user = insert(:user)

      cs =
        JournalEntry.changeset(%JournalEntry{}, %{
          date: Date.utc_today(),
          body: "Ok",
          mood: 0,
          user_id: user.id
        })

      assert %{mood: [_]} = errors_on(cs)
    end

    test "invalid when mood is above 5" do
      user = insert(:user)

      cs =
        JournalEntry.changeset(%JournalEntry{}, %{
          date: Date.utc_today(),
          body: "Ok",
          mood: 6,
          user_id: user.id
        })

      assert %{mood: [_]} = errors_on(cs)
    end

    test "valid mood at boundaries (1 and 5)" do
      user = insert(:user)

      for mood <- [1, 5] do
        cs =
          JournalEntry.changeset(%JournalEntry{}, %{
            date: Date.utc_today(),
            body: "Ok",
            mood: mood,
            user_id: user.id
          })

        assert cs.valid?, "expected valid for mood #{mood}"
      end
    end

    test "valid without mood (optional)" do
      user = insert(:user)

      cs =
        JournalEntry.changeset(%JournalEntry{}, %{
          date: Date.utc_today(),
          body: "Ok",
          user_id: user.id
        })

      assert cs.valid?
    end

    test "invalid when body is empty string" do
      user = insert(:user)

      cs =
        JournalEntry.changeset(%JournalEntry{}, %{
          date: Date.utc_today(),
          body: "",
          user_id: user.id
        })

      assert %{body: [_]} = errors_on(cs)
    end
  end
end
