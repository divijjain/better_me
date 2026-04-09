defmodule BetterMe.AccountsFixtures do
  @moduledoc """
  Test helpers for creating entities via the Accounts context.
  """

  alias BetterMe.Accounts
  alias BetterMe.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    email = Map.get(attrs, :email, unique_user_email())
    password = Map.get(attrs, :password, valid_user_password())

    {:ok, user} = Accounts.register_user(%{email: email, password: password})
    user
  end

  def oauth_user_fixture(attrs \\ []) do
    attrs = Enum.into(attrs, %{})
    email = Map.get(attrs, :email, unique_user_email())
    provider = Map.get(attrs, :provider, "google")
    provider_uid = Map.get(attrs, :provider_uid, "uid_#{System.unique_integer()}")

    {:ok, user} = Accounts.find_or_create_by_oauth(provider, provider_uid, email)
    user
  end

  def user_scope_fixture(user \\ nil) do
    user = user || user_fixture()
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end
end
