defmodule BetterMe.Health do
  alias BetterMe.Health.Repository

  defdelegate list_metrics(user_id, opts \\ []), to: Repository
  defdelegate get_metric(id, user_id), to: Repository
  defdelegate get_metric!(id, user_id), to: Repository
  defdelegate new_metric(), to: Repository
  defdelegate log_metric(user_id, attrs), to: Repository
  defdelegate update_metric(metric, attrs), to: Repository
  defdelegate delete_metric(metric), to: Repository
  defdelegate change_metric(metric, attrs \\ %{}), to: Repository
end
