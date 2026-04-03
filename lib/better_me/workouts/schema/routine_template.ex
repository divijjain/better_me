defmodule BetterMe.Workouts.Schema.RoutineTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_templates" do
    field :name, :string
    field :is_active, :boolean, default: true

    belongs_to :user, BetterMe.Accounts.User

    has_many :days, BetterMe.Workouts.Schema.RoutineDay,
      foreign_key: :routine_template_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :is_active, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 100)
  end
end
