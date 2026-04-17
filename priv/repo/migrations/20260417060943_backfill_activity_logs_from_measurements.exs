defmodule BetterMe.Repo.Migrations.BackfillActivityLogsFromMeasurements do
  use Ecto.Migration

  def up do
    # Copy any existing measurements JSONB data into the new typed activity_logs table.
    # Uses INSERT ... ON CONFLICT DO NOTHING — safe to re-run.
    execute("""
    INSERT INTO activity_logs (user_id, date, steps, active_kcal, resting_hr_bpm, sleep_minutes, inserted_at, updated_at)
    SELECT
      user_id,
      date,
      (measurements->>'steps')::integer,
      (measurements->>'active_kcal')::float,
      (measurements->>'resting_hr_bpm')::integer,
      (measurements->>'sleep_minutes')::integer,
      NOW(),
      NOW()
    FROM body_metrics
    WHERE measurements IS NOT NULL
      AND measurements != '{}'::jsonb
      AND (
        measurements ? 'steps'
        OR measurements ? 'active_kcal'
        OR measurements ? 'resting_hr_bpm'
        OR measurements ? 'sleep_minutes'
      )
    ON CONFLICT (user_id, date) DO NOTHING
    """)

    # Drop the measurements column — data now lives in activity_logs
    alter table(:body_metrics) do
      remove :measurements
    end
  end

  def down do
    alter table(:body_metrics) do
      add :measurements, :map, default: %{}
    end

    # Restore data from activity_logs back into measurements JSONB
    execute("""
    UPDATE body_metrics bm
    SET measurements = jsonb_strip_nulls(jsonb_build_object(
      'steps', al.steps,
      'active_kcal', al.active_kcal,
      'resting_hr_bpm', al.resting_hr_bpm,
      'sleep_minutes', al.sleep_minutes
    ))
    FROM activity_logs al
    WHERE bm.user_id = al.user_id AND bm.date = al.date
    """)
  end
end
