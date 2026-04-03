# better-me — session context snapshot
# Read this at the start of every new conversation instead of exploring the codebase.

## current state
Phase 1 — ALL WEEKS COMPLETE. Habits + Todos + Body Metrics + Gym tracking all working.
Next: Phase 2 — Nutrition + Go microservice.

## fitness data sync (future — Phase 2)
Apple Health: no server API, data is on-device only.
  → react-native-health in Expo app → POST to Phoenix API
Google Fit: has OAuth2 REST API, can sync server-side via Oban job, or via react-native-google-fit.
Both platforms feed the same Phoenix workout/body_metrics endpoints — no special handling needed in Phoenix.

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

## what is built — gym tracking (week 4)
- `workouts` schema: date, type (strength/cardio/flexibility/sport/other), duration, notes
- `exercises` schema: workout_id, name, sets, reps, weight, rpe, is_pr
- PR detection: `actions/detect_pr.ex` — compares weight against previous best per exercise name per user, marks `is_pr: true`
- `actions/add_exercise.ex` — adds exercise then runs PR detection, returns `:pr | :no_pr`
- LiveViews: `/workouts` list, `/workouts/:id` show with inline add-exercise form + PR badge 🏆, `/workouts/new` + `/workouts/:id/edit` forms
- Gym tab added to bottom nav

Key files:
  lib/better_me/workouts.ex                          # public API
  lib/better_me/workouts/repository.ex               # all Repo calls
  lib/better_me/workouts/schema/workout.ex
  lib/better_me/workouts/schema/exercise.ex
  lib/better_me/workouts/actions/detect_pr.ex
  lib/better_me/workouts/actions/add_exercise.ex
  lib/better_me_web/live/workouts/index.ex show.ex form.ex

## what is built — nutrition (phase 2, in progress)
Data model decision: ingredients are a first-class table (not jsonb) — select from existing
ingredients when building a recipe, macros computed from quantity_grams × macros_per_100g.

```
ingredients        — food items with macros per 100g (shared, no user_id)
recipes            — title, tags[], user_id
recipe_ingredients — recipe_id + ingredient_id + quantity_grams (join table)
meal_logs          — date, recipe_id, servings, meal_type, user_id
```

Key files:
  lib/better_me/nutrition.ex                                   # public API — defdelegate only
  lib/better_me/nutrition/repository.ex                        # all Repo calls
  lib/better_me/nutrition/macros.ex                            # pure macro calc (no DB)
  lib/better_me/nutrition/schema/ingredient.ex
  lib/better_me/nutrition/schema/recipe.ex
  lib/better_me/nutrition/schema/recipe_ingredient.ex
  lib/better_me/nutrition/schema/meal_log.ex
  priv/repo/migrations/20260403110000_create_ingredients.exs
  priv/repo/migrations/20260403110001_create_recipes.exs
  priv/repo/migrations/20260403110002_create_recipe_ingredients.exs
  priv/repo/migrations/20260403110003_create_meal_logs.exs

## phase 2 remaining
- LiveViews: /ingredients, /recipes CRUD, /nutrition daily view
- Go microservice: POST /calculate-tdee (macro targets)
- Daily macro progress view (totals vs targets)
- Push notifications via Expo Push API
