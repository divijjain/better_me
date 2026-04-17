defmodule BetterMe.HealthTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Health
  alias BetterMe.Health.Schema.BodyMetric

  import BetterMe.Factory

  setup do
    %{user: insert(:user)}
  end

  describe "log_metric/2" do
    test "creates a body metric with valid attrs", %{user: user} do
      assert {:ok, metric} =
               Health.log_metric(user.id, %{date: Date.utc_today(), weight: 80.0})

      assert metric.weight == 80.0
      assert metric.date == Date.utc_today()
      assert metric.user_id == user.id
    end

    test "returns error when date is missing", %{user: user} do
      assert {:error, changeset} = Health.log_metric(user.id, %{weight: 80.0})
      assert %{date: [_]} = errors_on(changeset)
    end

    test "allows body_fat_pct", %{user: user} do
      attrs = %{
        date: Date.utc_today(),
        weight: 78.5,
        body_fat_pct: 18.0
      }

      assert {:ok, metric} = Health.log_metric(user.id, attrs)
      assert metric.body_fat_pct == 18.0
    end

    test "upserts on duplicate date", %{user: user} do
      date = Date.utc_today()
      assert {:ok, _} = Health.log_metric(user.id, %{date: date, weight: 75.0})
      assert {:ok, metric} = Health.log_metric(user.id, %{date: date, weight: 76.0})
      assert metric.weight == 76.0
    end
  end

  describe "list_metrics/1" do
    test "returns metrics for the user", %{user: user} do
      metric = insert(:body_metric, user: user)
      metrics = Health.list_metrics(user.id)
      assert Enum.any?(metrics, &(&1.id == metric.id))
    end

    test "does not return metrics from other users", %{user: user} do
      insert(:body_metric, user: insert(:user))
      metrics = Health.list_metrics(user.id)
      assert Enum.all?(metrics, &(&1.user_id == user.id))
    end
  end

  describe "get_metric/2" do
    test "returns {:ok, metric} for valid owner", %{user: user} do
      metric = insert(:body_metric, user: user)
      assert {:ok, found} = Health.get_metric(metric.id, user.id)
      assert found.id == metric.id
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      metric = insert(:body_metric, user: insert(:user))
      assert {:error, :not_found} = Health.get_metric(metric.id, user.id)
    end

    test "returns {:error, :not_found} for nonexistent id", %{user: user} do
      assert {:error, :not_found} = Health.get_metric(0, user.id)
    end
  end

  describe "update_metric/2" do
    test "updates weight", %{user: user} do
      metric = insert(:body_metric, user: user)
      assert {:ok, updated} = Health.update_metric(metric, %{weight: 72.0})
      assert updated.weight == 72.0
    end
  end

  describe "delete_metric/1" do
    test "deletes the metric", %{user: user} do
      metric = insert(:body_metric, user: user)
      assert {:ok, _} = Health.delete_metric(metric)
      assert {:error, :not_found} = Health.get_metric(metric.id, user.id)
    end
  end

  describe "weight_trend/2" do
    test "returns empty list when no metrics", %{user: user} do
      assert Health.weight_trend(user.id) == []
    end

    test "returns trend data with date and weight", %{user: user} do
      insert(:body_metric, user: user, date: Date.utc_today(), weight: 80.0)
      trend = Health.weight_trend(user.id)
      assert [%{date: _, weight: 80.0}] = trend
    end

    test "does not include metrics outside the window", %{user: user} do
      insert(:body_metric, user: user, date: Date.add(Date.utc_today(), -60), weight: 90.0)
      assert Health.weight_trend(user.id, 30) == []
    end
  end

  # ---------------------------------------------------------------------------
  # Changesets
  # ---------------------------------------------------------------------------

  describe "BodyMetric.create_changeset/2" do
    test "invalid when weight is zero" do
      user = insert(:user)

      cs =
        BodyMetric.create_changeset(%BodyMetric{}, %{
          date: Date.utc_today(),
          weight: 0.0,
          user_id: user.id
        })

      assert %{weight: [_]} = errors_on(cs)
    end

    test "invalid when weight is negative" do
      user = insert(:user)

      cs =
        BodyMetric.create_changeset(%BodyMetric{}, %{
          date: Date.utc_today(),
          weight: -1.0,
          user_id: user.id
        })

      assert %{weight: [_]} = errors_on(cs)
    end

    test "invalid when body_fat_pct is negative" do
      user = insert(:user)

      cs =
        BodyMetric.create_changeset(%BodyMetric{}, %{
          date: Date.utc_today(),
          weight: 75.0,
          user_id: user.id,
          body_fat_pct: -1.0
        })

      assert %{body_fat_pct: [_]} = errors_on(cs)
    end

    test "invalid when body_fat_pct is 100 or more" do
      user = insert(:user)

      cs =
        BodyMetric.create_changeset(%BodyMetric{}, %{
          date: Date.utc_today(),
          weight: 75.0,
          user_id: user.id,
          body_fat_pct: 100.0
        })

      assert %{body_fat_pct: [_]} = errors_on(cs)
    end

    test "valid with body_fat_pct at boundary (0)" do
      user = insert(:user)

      cs =
        BodyMetric.create_changeset(%BodyMetric{}, %{
          date: Date.utc_today(),
          weight: 75.0,
          user_id: user.id,
          body_fat_pct: 0.0
        })

      assert cs.valid?
    end
  end

  describe "BodyMetric.update_changeset/2" do
    test "invalid when date is removed" do
      metric = insert(:body_metric)
      cs = BodyMetric.update_changeset(metric, %{date: nil})
      assert %{date: [_]} = errors_on(cs)
    end
  end
end
