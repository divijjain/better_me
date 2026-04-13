defmodule BetterMe.Health.Repository do
  import Ecto.Query

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
      on_conflict: {:replace, [:weight, :body_fat_pct, :measurements, :updated_at]},
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
