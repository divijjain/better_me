defmodule BetterMe.Todos.Schema.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :category, Ecto.Enum, values: [:work, :personal, :health, :learning, :misc]
    field :priority, Ecto.Enum, values: [:low, :medium, :high], default: :medium
    field :due_date, :date
    field :completed, :boolean, default: false
    field :repeat, Ecto.Enum, values: [:none, :daily, :weekly, :monthly], default: :none

    belongs_to :user, BetterMe.Accounts.User

    timestamps()
  end

  def create_changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :category, :priority, :due_date, :completed, :repeat, :user_id])
    |> validate_required([:title, :category, :user_id])
    |> validate_length(:title, min: 1, max: 200)
  end

  def update_changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :category, :priority, :due_date, :completed, :repeat])
    |> validate_required([:title, :category])
    |> validate_length(:title, min: 1, max: 200)
  end
end
