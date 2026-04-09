defmodule BetterMe.AccountsTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Accounts
  alias BetterMe.Accounts.{User, UserToken}

  import BetterMe.AccountsFixtures

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(0) end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})
      assert %{email: ["can't be blank"], password: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email format" do
      {:error, changeset} =
        Accounts.register_user(%{email: "not-valid", password: "hello world!"})

      assert %{email: [_]} = errors_on(changeset)
    end

    test "validates password length" do
      {:error, changeset} =
        Accounts.register_user(%{email: unique_user_email(), password: "short"})

      assert %{password: [_]} = errors_on(changeset)
    end

    test "validates uniqueness of email" do
      user = user_fixture()

      {:error, changeset} =
        Accounts.register_user(%{email: user.email, password: valid_user_password()})

      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "registers user with hashed password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(%{email: email, password: valid_user_password()})
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end
  end

  describe "generate_user_session_token/1" do
    test "generates a token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert is_binary(token)
    end
  end

  describe "get_user_by_session_token/1" do
    test "returns user for valid token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert {fetched_user, _} = Accounts.get_user_by_session_token(token)
      assert fetched_user.id == user.id
    end

    test "returns nil for invalid token" do
      assert nil == Accounts.get_user_by_session_token("invalid")
    end

    test "returns nil for expired token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      {1, nil} =
        BetterMe.Repo.update_all(
          from(t in UserToken, where: t.token == ^token),
          set: [inserted_at: ~U[2000-01-01 00:00:00Z]]
        )

      assert nil == Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert :ok = Accounts.delete_user_session_token(token)
      assert nil == Accounts.get_user_by_session_token(token)
    end
  end

  describe "sudo_mode?/2" do
    test "returns false when authenticated_at is nil" do
      user = user_fixture()
      refute Accounts.sudo_mode?(user)
    end

    test "returns true when authenticated recently" do
      user = %{user_fixture() | authenticated_at: DateTime.utc_now(:second)}
      assert Accounts.sudo_mode?(user)
    end

    test "returns false when authenticated too long ago" do
      user = %{user_fixture() | authenticated_at: ~U[2000-01-01 00:00:00Z]}
      refute Accounts.sudo_mode?(user)
    end
  end
end
