defmodule BetterMe.Repo.Migrations.AddOauthToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :provider, :string, null: true
      add :provider_uid, :string, null: true
    end

    create unique_index(:users, [:provider, :provider_uid])
  end
end
