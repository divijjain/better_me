# Health Domain

## Tables

### `body_metrics`
Body composition — one row per `(user_id, date)`, upsert on conflict.

| Column | Type | Notes |
|--------|------|-------|
| `weight` | float | kg |
| `body_fat_pct` | float | percentage |

### `activity_logs`
Daily activity summary — one row per `(user_id, date)`, upsert on conflict.

| Column | Type | Source |
|--------|------|--------|
| `steps` | integer | HealthKit `getStepCount` / Health Connect `Steps` |
| `active_kcal` | float | HealthKit `getActiveEnergyBurned` / Health Connect `ActiveCaloriesBurned` |
| `resting_hr_bpm` | integer | HealthKit `getRestingHeartRate` / Health Connect `RestingHeartRate` |
| `sleep_minutes` | integer | HealthKit `getSleepSamples` / Health Connect `SleepSession` |

## Why two tables (not one with JSONB)

`body_metrics` and `activity_logs` were separated because:

- **Different concerns** — body composition (weight, fat %) is measured occasionally; daily activity (steps, sleep) is synced every day from a wearable. Same table conflates them.
- **Type safety** — JSONB `measurements` column had no column-level types. A typo in a key name silently loses data.
- **Queryability** — `WHERE steps > 10000` is a plain index scan. `WHERE (measurements->>'steps')::int > 10000` is a cast + seq scan.
- **Consistency** — every other domain uses typed columns (`habit_logs`, `exercise_sets`, `meal_logs`). JSONB was an outlier.

The JSONB `measurements` column was backfilled and then dropped in migration `20260417060943`.

## Upsert behaviour

Both tables use `on_conflict: {:replace, [...]}` with `conflict_target: [:user_id, :date]`.

This means syncing twice on the same day replaces the row with the latest values — safe and idempotent. The HealthKit sync always collects all data types in one call per day, so a second sync for the same date gets the most up-to-date numbers.

## API endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/health/metrics` | List body metrics (default last 90) |
| `POST` | `/api/health/metrics` | Log / upsert body metric |
| `DELETE` | `/api/health/metrics/:id` | Delete a body metric entry |
| `GET` | `/api/health/activity` | List activity logs (default last 90) |
| `POST` | `/api/health/activity` | Log / upsert activity for a date |

## Real-time (Phoenix Channel)

Topic: `health:<user_id>`

| Event | Trigger | Payload |
|-------|---------|---------|
| `metric_logged` | `LogMetric` action | `%{metric: %{id, date, weight, body_fat_pct}}` |
| `activity_logged` | `LogActivity` action | `%{activity: %{id, date, steps, active_kcal, resting_hr_bpm, sleep_minutes}}` |

## Mobile sync flow

`lib/healthkit.ts` → `syncHealth()` makes **two separate POST calls**:

1. Weight → `POST /api/health/metrics`
2. Activity (steps, kcal, HR, sleep) → `POST /api/health/activity`

iOS sleep gotcha: `getSleepSamples` returns `value` as either `"ASLEEP"` (string) or `3` (number) depending on the library version. Filter handles both: `s.value === "ASLEEP" || s.value === 3`.

Android gotcha: `aggregateRecord` throws (does not return null/empty) when no records exist for the time window. Wrap every call in `safeAggregate` (try/catch returning null).
