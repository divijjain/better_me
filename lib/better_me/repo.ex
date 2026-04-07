defmodule BetterMe.Repo do
  use Ecto.Repo,
    otp_app: :better_me,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    {:ok,
     Keyword.update(config, :extensions, Pgvector.extensions(), &(Pgvector.extensions() ++ &1))}
  end
end
