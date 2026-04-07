defmodule BetterMe.Embeddings.Schema.Embedding do
  use Ecto.Schema
  import Ecto.Changeset

  # source_type values: "journal_entry" | "meal_log" | "workout"
  @valid_source_types ~w(journal_entry meal_log workout)

  schema "embeddings" do
    field :source_type, :string
    field :source_id, :integer
    field :content, :string
    field :embedding, Pgvector.Ecto.Vector

    belongs_to :user, BetterMe.Accounts.User

    timestamps(updated_at: false, type: :utc_datetime)
  end

  def changeset(embedding, attrs) do
    embedding
    |> cast(attrs, [:user_id, :source_type, :source_id, :content, :embedding])
    |> validate_required([:user_id, :source_type, :source_id, :content])
    |> validate_inclusion(:source_type, @valid_source_types)
  end
end
