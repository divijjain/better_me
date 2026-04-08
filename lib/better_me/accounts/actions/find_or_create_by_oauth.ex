defmodule BetterMe.Accounts.Actions.FindOrCreateByOauth do
  @moduledoc """
  Finds an existing user by OAuth provider + uid, or by email (to link an
  existing email account), or creates a new user.

  Sequences two repository lookups to decide which path to take — coordination
  logic that belongs in an action, not the repository.
  """

  alias BetterMe.Accounts.Repository

  def run(provider, provider_uid, email) do
    case Repository.get_by_provider(provider, provider_uid) do
      %_{} = user -> {:ok, user}
      nil -> upsert_by_email(provider, provider_uid, email)
    end
  end

  defp upsert_by_email(provider, provider_uid, email) do
    case Repository.get_by_email(email) do
      %_{} = existing ->
        Repository.link_provider(existing, provider, provider_uid)

      nil ->
        Repository.create_oauth_user(%{
          email: email,
          provider: provider,
          provider_uid: provider_uid
        })
    end
  end
end
