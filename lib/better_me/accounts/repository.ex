defmodule BetterMe.Accounts.Repository do
  import Ecto.Changeset, only: [change: 2]

  alias BetterMe.Accounts.User
  alias BetterMe.Repo

  def get_by_provider(provider, provider_uid) do
    Repo.get_by(User, provider: provider, provider_uid: provider_uid)
  end

  def get_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def link_provider(user, provider, provider_uid) do
    user
    |> change(provider: provider, provider_uid: provider_uid)
    |> Repo.update()
  end

  def create_oauth_user(attrs) do
    %User{}
    |> User.oauth_changeset(attrs)
    |> Repo.insert()
  end
end
