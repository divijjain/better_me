defmodule BetterMe.Profiles do
  alias BetterMe.Profiles.{Repository, TDEE}

  defdelegate get_profile(user_id),              to: Repository
  defdelegate save_profile(user_id, attrs),      to: Repository
  defdelegate change_profile(profile, attrs \\ %{}), to: Repository
  defdelegate new_profile(),                     to: Repository
  defdelegate activity_levels(),                 to: Repository
  defdelegate genders(),                         to: Repository
  defdelegate calculate_targets(profile),        to: TDEE, as: :calculate
end
