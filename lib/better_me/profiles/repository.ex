defmodule BetterMe.Profiles.Repository do
  alias BetterMe.Profiles.Schema.UserProfile
  alias BetterMe.Repo

  def get_profile(user_id) do
    case Repo.get_by(UserProfile, user_id: user_id) do
      nil -> {:error, :not_found}
      profile -> {:ok, profile}
    end
  end

  def save_profile(user_id, attrs) do
    case Repo.get_by(UserProfile, user_id: user_id) do
      nil -> insert_profile(user_id, attrs)
      profile -> update_profile(profile, attrs)
    end
  end

  def change_profile(profile, attrs \\ %{}) do
    UserProfile.changeset(profile, attrs)
  end

  def new_profile, do: %UserProfile{}

  def activity_levels, do: UserProfile.activity_levels()
  def genders, do: UserProfile.genders()

  defp insert_profile(user_id, attrs) do
    %UserProfile{user_id: user_id}
    |> UserProfile.changeset(attrs)
    |> Repo.insert()
  end

  defp update_profile(profile, attrs) do
    profile
    |> UserProfile.changeset(attrs)
    |> Repo.update()
  end
end
