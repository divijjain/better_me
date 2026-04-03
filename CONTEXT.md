# better-me — session context snapshot
# Read this at the start of every new conversation instead of exploring the codebase.

## current state
Phase 1 — Week 3 complete. Habits + Todos + Body Metrics all working.
Next: Week 4 — Gym tracking (workouts → exercises → sets/reps/weight, PR detection).

## what is built and working
- Auth: magic link + password login via phx.gen.auth (plain integer IDs everywhere)
- Habits: CRUD, streak calculation, 30-day calendar, one-tap log, show page with stats
- Todos: CRUD, priority (low/medium/high), category, due date, repeat, pending/done filter, one-tap complete
- Body Metrics: CRUD, weight + body fat %, unique per user per day
- Bottom nav bar: Habits / Todos / Health tabs (fixed, mobile-first)
- UI components extracted to `ui_components.ex`
- Credo configured and passing (`mix credo --strict`)

## key file map
```
lib/better_me/
  habits.ex                          # public API — defdelegate only
  habits/
    repository.ex                    # all Repo calls
    streak.ex                        # pure streak calc
    schema/habit.ex                  # Ecto schema
    schema/habit_log.ex
    actions/log_habit.ex
    actions/list_with_meta.ex        # bulk load habits+streak+today (2 queries)
    actions/current_streak.ex
    actions/recent_logs.ex
    actions/logged_today.ex
    actions/habit_stats.ex           # show page stats (streak + calendar)

  todos.ex                           # public API — defdelegate only
  todos/
    repository.ex
    schema/todo.ex

  health.ex                          # public API — defdelegate only
  health/
    repository.ex
    schema/body_metric.ex

  accounts.ex                        # phx.gen.auth generated + register_user added
  accounts/user.ex

lib/better_me_web/
  router.ex                          # all routes in live_session :authenticated
  user_auth.ex                       # on_mount :require_authenticated
  components/
    core_components.ex               # Phoenix primitives (input, flash, icon)
    ui_components.ex                 # app components (page_header, form_header, etc.)
    layouts/root.html.heex           # bottom nav, top auth bar, data-theme="light"
  live/
    habits/index.ex show.ex form.ex
    todos/index.ex form.ex
    health/index.ex form.ex

priv/repo/
  migrations/
    20260402105243_create_users_auth_tables.exs
    20260402105329_create_habits.exs
    20260402233816_create_todos.exs
    20260402234051_create_body_metrics.exs
  seeds.exs                          # divij@better.me / betterme2026!
```

## architecture rules (summary — full detail in PRINCIPLES.md)
- Three layers per context: `context.ex` (defdelegate only) → `repository.ex` (all Repo.*) → `actions/*.ex` (coordination)
- Actions never call Repo.* directly. Repository never coordinates.
- Schemas live in `context/schema/schema_name.ex`, private to their context.
- All context functions scoped to user_id — never fetch without it.
- `%Struct{user_id: user_id}` before cast — never `Map.put(attrs, :user_id, ...)` on string-keyed maps.
- LiveViews use `<.page_container>`, `<.page_header>`, `<.form_header>`, `<.form_actions>`, `<.empty_state>`, `<.edit_link>` from `ui_components.ex`.
- Plain Tailwind only — no daisyUI classes on form elements.
- `:key={item.id}` on every `:for` loop.

## decisions made (non-obvious)
- Plain integer PKs everywhere — UUID caused type mismatches with phx.gen.auth
- LiveView for Phase 1 mobile UI (runs in mobile browser, no React Native needed yet)
- Plain Tailwind + Heroicons — no component library (daisyUI present but locked to light theme, its classes avoided on form elements)
- `data-theme="light"` hardcoded on `<html>` — dark mode disabled (was making inputs invisible)
- `precommit` alias: `mix compile --warnings-as-errors && mix deps.unlock --unused && mix format && mix credo --strict && mix test`

## seed credentials
Email: divij@better.me / Password: betterme2026!
Email: test@better.me  / Password: betterme2026!

## week 4 plan (next session)
Gym tracking:
- `workouts` schema: date, type (strength/cardio/flexibility), duration, notes, user_id
- `exercises` schema: workout_id, name, sets, reps, weight, rpe
- PR detection: track personal best per exercise (max weight × reps)
- LiveView: workout list, workout detail (exercise log), create workout + add exercises
- Follow same three-layer pattern as habits/todos/health
