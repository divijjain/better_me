defmodule BetterMe.Repo do
  use Ecto.Repo,
    otp_app: :better_me,
    adapter: Ecto.Adapters.Postgres
end
