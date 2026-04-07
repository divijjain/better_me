defmodule BetterMe.Journals.Schema.JournalEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "journal_entries" do
    field :date, :date
    field :body, :string
    field :mood, :integer
    field :tags, {:array, :string}, default: []

    belongs_to :user, BetterMe.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:date, :body, :mood, :tags])
    |> validate_required([:date, :body])
    |> validate_length(:body, min: 1)
    |> validate_number(:mood, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> unique_constraint([:user_id, :date],
      name: :journal_entries_user_date_unique,
      message: "already have an entry for this date"
    )
  end
end
