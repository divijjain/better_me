defmodule BetterMe.Health do
  alias BetterMe.Health.Actions.LogActivity
  alias BetterMe.Health.Actions.LogMetric
  alias BetterMe.Health.Repository

  # Body metrics
  defdelegate list_metrics(user_id, opts \\ []), to: Repository
  defdelegate get_metric(id, user_id), to: Repository
  defdelegate get_metric!(id, user_id), to: Repository
  defdelegate new_metric(), to: Repository
  defdelegate log_metric(user_id, attrs), to: LogMetric, as: :run
  defdelegate update_metric(metric, attrs), to: Repository
  defdelegate delete_metric(metric), to: Repository
  defdelegate change_metric(metric, attrs \\ %{}), to: Repository
  defdelegate weight_trend(user_id, days \\ 30), to: Repository

  # Activity logs
  defdelegate list_activity(user_id, opts \\ []), to: Repository
  defdelegate get_activity_for_date(user_id, date), to: Repository
  defdelegate log_activity(user_id, attrs), to: LogActivity, as: :run
end
