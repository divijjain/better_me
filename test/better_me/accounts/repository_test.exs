defmodule BetterMe.Accounts.RepositoryTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Accounts.Repository

  import BetterMe.AccountsFixtures

  describe "get_by_provider/2" do
    test "returns nil when no match" do
      assert is_nil(Repository.get_by_provider("google", "nonexistent"))
    end

    test "returns user when provider + uid match" do
      user = oauth_user_fixture(provider: "google", provider_uid: "uid_repo_1")
      found = Repository.get_by_provider("google", "uid_repo_1")
      assert found.id == user.id
    end

    test "returns nil when provider matches but uid does not" do
      oauth_user_fixture(provider: "google", provider_uid: "uid_repo_2")
      assert is_nil(Repository.get_by_provider("google", "wrong_uid"))
    end
  end

  describe "get_by_email/1" do
    test "returns nil when email not found" do
      assert is_nil(Repository.get_by_email("notfound@example.com"))
    end

    test "returns user when email matches" do
      user = user_fixture()
      found = Repository.get_by_email(user.email)
      assert found.id == user.id
    end
  end

  describe "link_provider/3" do
    test "sets provider and provider_uid on existing user" do
      user = user_fixture()
      assert is_nil(user.provider)

      assert {:ok, updated} = Repository.link_provider(user, "google", "uid_linked")
      assert updated.provider == "google"
      assert updated.provider_uid == "uid_linked"
    end
  end

  describe "create_oauth_user/1" do
    test "creates a new confirmed user" do
      email = unique_user_email()

      assert {:ok, user} =
               Repository.create_oauth_user(%{
                 email: email,
                 provider: "google",
                 provider_uid: "uid_create_#{System.unique_integer()}"
               })

      assert user.email == email
      assert user.confirmed_at != nil
      assert is_nil(user.hashed_password)
    end

    test "returns error on invalid email" do
      assert {:error, changeset} =
               Repository.create_oauth_user(%{
                 email: "not-an-email",
                 provider: "google",
                 provider_uid: "uid_bad_email"
               })

      assert %{email: [_ | _]} = errors_on(changeset)
    end

    test "returns error on duplicate email" do
      user = user_fixture()

      assert {:error, changeset} =
               Repository.create_oauth_user(%{
                 email: user.email,
                 provider: "google",
                 provider_uid: "uid_dup_email"
               })

      assert %{email: [_ | _]} = errors_on(changeset)
    end
  end
end
