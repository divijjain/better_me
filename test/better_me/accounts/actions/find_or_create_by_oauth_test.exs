defmodule BetterMe.Accounts.Actions.FindOrCreateByOauthTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Accounts
  alias BetterMe.Accounts.Actions.FindOrCreateByOauth

  import BetterMe.AccountsFixtures

  describe "run/3 — new user" do
    test "creates a new confirmed user" do
      email = unique_user_email()

      assert {:ok, user} = FindOrCreateByOauth.run("google", "uid_new_123", email)
      assert user.email == email
      assert user.provider == "google"
      assert user.provider_uid == "uid_new_123"
      assert user.confirmed_at != nil
      assert is_nil(user.hashed_password)
    end

    test "returns the existing user when called again with same provider_uid but different email" do
      email = unique_user_email()
      {:ok, original} = FindOrCreateByOauth.run("google", "uid_dup", email)

      # uid match takes priority — returns original user, ignores the new email
      assert {:ok, found} = FindOrCreateByOauth.run("google", "uid_dup", unique_user_email())
      assert found.id == original.id
    end
  end

  describe "run/3 — existing OAuth user" do
    test "returns existing user when provider + uid match" do
      {:ok, existing} = FindOrCreateByOauth.run("google", "uid_existing", unique_user_email())

      assert {:ok, found} = FindOrCreateByOauth.run("google", "uid_existing", existing.email)
      assert found.id == existing.id
    end

    test "does not create duplicate users on repeated calls" do
      email = unique_user_email()
      {:ok, first} = FindOrCreateByOauth.run("google", "uid_repeat", email)
      {:ok, second} = FindOrCreateByOauth.run("google", "uid_repeat", email)

      assert first.id == second.id
    end
  end

  describe "run/3 — linking existing email/password account" do
    test "links Google provider to an existing password account" do
      user = user_fixture()
      assert is_nil(user.provider)

      assert {:ok, linked} = FindOrCreateByOauth.run("google", "uid_link_123", user.email)
      assert linked.id == user.id
      assert linked.provider == "google"
      assert linked.provider_uid == "uid_link_123"
    end

    test "existing user can still be found by provider after linking" do
      user = user_fixture()
      {:ok, _linked} = FindOrCreateByOauth.run("google", "uid_after_link", user.email)

      assert {:ok, found} = FindOrCreateByOauth.run("google", "uid_after_link", user.email)
      assert found.id == user.id
    end
  end

  describe "run/3 — accounts context delegation" do
    test "Accounts.find_or_create_by_oauth delegates correctly" do
      email = unique_user_email()
      assert {:ok, user} = Accounts.find_or_create_by_oauth("google", "uid_delegate", email)
      assert user.email == email
      assert user.provider == "google"
    end
  end
end
