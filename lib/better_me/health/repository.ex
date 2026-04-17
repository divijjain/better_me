defmodule BetterMe.Health.Repository do
  import Ecto.Query

  alias BetterMe.Health.Schema.ActivityLog
  alias BetterMe.Health.Schema.BodyMetric
  alias BetterMe.Repo

  def list_metrics(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 90)

    BodyMetric
    |> where(user_id: ^user_id)
    |> order_by([m], desc: m.date)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_metric(id, user_id) do
    case Repo.get_by(BodyMetric, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      metric -> {:ok, metric}
    end
  end

  def get_metric!(id, user_id) do
    case get_metric(id, user_id) do
      {:ok, metric} -> metric
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: BodyMetric
    end
  end

  def new_metric, do: %BodyMetric{date: Date.utc_today()}

  def log_metric(user_id, attrs) do
    %BodyMetric{user_id: user_id}
    |> BodyMetric.create_changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:weight, :body_fat_pct, :updated_at]},
      conflict_target: [:user_id, :date]
    )
  end

  def update_metric(metric, attrs) do
    metric
    |> BodyMetric.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_metric(metric) do
    Repo.delete(metric)
  end

  def change_metric(metric, attrs \\ %{}) do
    BodyMetric.update_changeset(metric, attrs)
  end

  # --- Activity Logs ---

  def list_activity(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 90)
    date_from = Keyword.get(opts, :date_from)
    date_to = Keyword.get(opts, :date_to)

    ActivityLog
    |> where(user_id: ^user_id)
    |> then(fn q -> if date_from, do: where(q, [a], a.date >= ^date_from), else: q end)
    |> then(fn q -> if date_to, do: where(q, [a], a.date <= ^date_to), else: q end)
    |> order_by([a], desc: a.date)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_activity_for_date(user_id, date) do
    case Repo.get_by(ActivityLog, user_id: user_id, date: date) do
      nil -> {:error, :not_found}
      log -> {:ok, log}
    end
  end

  def log_activity(user_id, attrs) do
    %ActivityLog{user_id: user_id}
    |> ActivityLog.changeset(attrs)
    |> Repo.insert(
      on_conflict:
        {:replace, [:steps, :active_kcal, :resting_hr_bpm, :sleep_minutes, :updated_at]},
      conflict_target: [:user_id, :date]
    )
  end

  def activity_for_date(user_id, date) do
    case Repo.get_by(ActivityLog, user_id: user_id, date: date) do
      nil -> nil
      log -> log
    end
  end

  def steps_trend(user_id, days \\ 30) do
    since = Date.add(Date.utc_today(), -days)

    Repo.all(
      from a in ActivityLog,
        where: a.user_id == ^user_id and a.date >= ^since and not is_nil(a.steps),
        order_by: [asc: a.date],
        select: %{date: a.date, steps: a.steps}
    )
  end

  def sleep_trend(user_id, days \\ 30) do
    since = Date.add(Date.utc_today(), -days)

    Repo.all(
      from a in ActivityLog,
        where: a.user_id == ^user_id and a.date >= ^since and not is_nil(a.sleep_minutes),
        order_by: [asc: a.date],
        select: %{date: a.date, sleep_minutes: a.sleep_minutes}
    )
  end

  def resting_hr_trend(user_id, days \\ 30) do
    since = Date.add(Date.utc_today(), -days)

    Repo.all(
      from a in ActivityLog,
        where: a.user_id == ^user_id and a.date >= ^since and not is_nil(a.resting_hr_bpm),
        order_by: [asc: a.date],
        select: %{date: a.date, resting_hr_bpm: a.resting_hr_bpm}
    )
  end

  # --- Body Metrics ---

  def weight_trend(user_id, days \\ 30) do
    since = Date.add(Date.utc_today(), -days)

    Repo.all(
      from m in BodyMetric,
        where: m.user_id == ^user_id and m.date >= ^since and not is_nil(m.weight),
        order_by: [asc: m.date],
        select: %{date: m.date, weight: m.weight}
    )
  end
end
