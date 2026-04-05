# better-me — session context snapshot
# Read this at the start of every new conversation instead of exploring the codebase.

## current state
Phase 2 — In progress.
Phase 1 complete: Habits, Todos, Body Metrics, Gym tracking.
Phase 2 partial: Ingredients + Recipes CRUD done. Nutrition daily log LiveView in progress.
User Profiles (TDEE/macro targets) built — schema, TDEE calc, LiveView all done.
Next: wire macro targets into the nutrition daily view, Go microservice (optional).

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
- Gym tracking: workouts + exercises + exercise_sets + routine_templates, PR detection
- Ingredients: CRUD, macros per 100g, category + brand fields
- Recipes: CRUD, tag support, recipe_ingredients join table with quantity_grams
- Meal Logs: log recipe + servings + meal_type per day
- Nutrition daily view: in progress — daily macro totals vs targets
- User Profiles: height/weight/age/gender/activity level, macro split %, TDEE calc (Mifflin-St Jeor)
- Bottom nav bar: Habits / Todos / Health / Gym tabs (fixed, mobile-first)
- UI components extracted to `ui_components.ex`
- Credo configured and passing (`mix credo --strict`)

## key file map
```
lib/better_me/
  habits.ex / habits/                # CRUD, streak, habit_logs
  todos.ex / todos/                  # CRUD, priority/category/due date
  health.ex / health/                # body metrics (weight, body fat %)
  workouts.ex / workouts/            # workouts + exercises + exercise_sets + routine_templates
    actions/detect_pr.ex             # PR detection per exercise name per user
    actions/add_exercise.ex          # add exercise + run PR detection
  nutrition.ex / nutrition/          # ingredients, recipes, recipe_ingredients, meal_logs
    macros.ex                        # pure macro calc (no DB): qty × per_100g / 100
    schema/ingredient.ex             # name, calories/protein/carbs/fat per 100g, category, brand
    schema/recipe.ex                 # title, tags[], user_id
    schema/recipe_ingredient.ex      # recipe_id, ingredient_id, quantity_grams
    schema/meal_log.ex               # date, recipe_id, servings, meal_type, user_id
  profiles.ex / profiles/            # user profile + TDEE/macro targets
    tdee.ex                          # pure TDEE calc — Mifflin-St Jeor BMR
    repository.ex                    # upsert profile by user_id
    schema/user_profile.ex           # height, weight, age, gender, activity_level,
                                     # protein_pct, carbs_pct (fat derived as remainder)
  accounts.ex / accounts/            # phx.gen.auth + register_user

lib/better_me_web/
  router.ex                          # all routes in live_session :authenticated
  components/
    core_components.ex               # Phoenix primitives
    ui_components.ex                 # page_header, form_header, form_actions, etc.
    layouts/root.html.heex           # bottom nav, auth bar, data-theme="light"
  live/
    habits/index.ex show.ex form.ex
    todos/index.ex form.ex
    health/index.ex form.ex
    workouts/index.ex show.ex form.ex
    ingredients/index.ex form.ex
    recipes/index.ex show.ex form.ex
    nutrition/index.ex               # daily macro log (in progress)
    profile/index.ex                 # user profile + macro targets form

priv/repo/migrations/
  20260402105243_create_users_auth_tables.exs
  20260402105329_create_habits.exs
  20260402233816_create_todos.exs
  20260402234051_create_body_metrics.exs
  20260403032129_create_workouts.exs
  20260403032130_create_exercises.exs
  20260403100000_create_routine_templates.exs
  20260403100001_add_routine_day_to_workouts.exs
  20260403100002_create_exercise_sets.exs
  20260403100003_add_substitutions_to_routine_exercises.exs
  20260403110000_create_ingredients.exs
  20260403110001_create_recipes.exs
  20260403110002_create_recipe_ingredients.exs
  20260403110003_create_meal_logs.exs
  20260403120000_add_category_and_brand_to_ingredients.exs
  20260405100000_create_user_profiles.exs
seeds.exs                            # divij@better.me / betterme2026!
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

## phase 2 remaining
- Finish nutrition daily view: wire macro targets from profile into progress bars
- Go microservice: POST /calculate-tdee (optional — TDEE already done in Elixir)
- Push notifications via Expo Push API (Phase 2+)
