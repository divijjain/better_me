# better_me

A mobile-first personal OS for tracking the things that matter — habits, workouts, nutrition, body metrics, and todos — with AI-powered insights planned for a later phase. Built for personal use, not as a SaaS product.

## objective

Most health and productivity apps do one thing. better_me is a single place that connects all the dots: did you sleep well, train hard, eat right, and stay consistent? Over time it will surface patterns and insights across all these domains using AI — but the foundation is clean, reliable data capture.

## features

### phase 1 — daily driver (complete)

**Habits**
- Create habits with category (health, fitness, personal, learning, work) and frequency (daily, weekly)
- One-tap log for today
- Current and longest streak tracking
- 30-day calendar view per habit

**Todos**
- Full CRUD with priority (low / medium / high), category, due date, and repeat
- One-tap complete
- Filter by pending / done

**Body Metrics**
- Log weight and body fat % — one entry per day
- Full history with edit/delete

**Gym Tracking**
- Log workouts by type (strength, cardio, flexibility, sport, other) with duration and notes
- Add exercises with sets, reps, weight, and RPE
- Automatic PR detection — marks a new personal record when weight exceeds previous best for that exercise

### phase 2 — nutrition (in progress)

**Ingredients**
- Food database with macros per 100g (calories, protein, carbs, fat)
- Categorised (protein, vegetable, fruit, grain, dairy, etc.) and brand-aware
- Shared across all recipes

**Recipes**
- Build recipes by selecting ingredients and specifying quantity in grams
- Macros auto-calculated from ingredient data — no manual entry
- Tag recipes (e.g. lunch, high-protein, meal-prep)

**Daily Nutrition Log**
- Log meals by type (breakfast, lunch, dinner, snack) for any date
- Multiple entries per meal type supported
- Per-meal and daily macro totals (kcal, protein, carbs, fat)
- Navigate back through previous days

### phase 3 — AI insights (planned)

- RAG-powered insight agent using pgvector — embeds journal, habits, workouts, and nutrition into a searchable vector store
- Natural language queries: "why did my energy drop last week?"
- Jido agents for habit coaching and meal planning
- Oban background jobs for weekly digests and streak alerts

### phase 4 — analytics (planned)

- Cross-domain dashboards — correlate sleep, training, nutrition, and habit consistency
- Trend charts and personal bests over time

## stack

| Layer | Technology |
|---|---|
| Backend | Elixir / Phoenix (LiveView + JSON API) |
| Database | PostgreSQL + Ecto |
| Background jobs | Oban |
| Nutrition calculations | Go microservice (stateless, called from Phoenix) |
| AI / vector search | pgvector + Jido (Phase 3) |
| Frontend (Phase 1) | Phoenix LiveView — runs in mobile browser |
| Frontend (Phase 2+) | React Native + Expo — native features |

## getting started

```bash
mix setup         # install deps, create DB, run migrations, seed
mix phx.server    # start the server at http://localhost:4000
```

Seed credentials:
- `divij@better.me` / `betterme2026!`
- `test@better.me` / `betterme2026!`

## development

```bash
iex -S mix phx.server   # start with interactive shell
mix test                 # run tests
mix precommit            # compile + format + credo + test — run before every commit
```

Dev tools (local only):
- Mailbox preview: `http://localhost:4000/dev/mailbox`
- LiveDashboard: `http://localhost:4000/dev/dashboard`

## architecture

Each domain follows a strict three-layer structure:

```
context.ex          # public API — defdelegate only, no logic
repository.ex       # all Repo.* calls — queries, inserts, updates
actions/*.ex        # coordination logic — sequences repository calls, handles side effects
schema/*.ex         # Ecto schemas and changesets — private to the context
```

Key rules:
- `repository.ex` is the only file that calls `Repo.*` directly
- Actions coordinate repository calls — never call `Repo.*` directly
- All context functions are scoped to `user_id` — never fetch data without it
- Errors are data: `{:ok, result} | {:error, reason}` everywhere

See [PRINCIPLES.md](PRINCIPLES.md) for the full design guide.

## project structure

```
lib/
  better_me/
    habits/           schema/, actions/, repository.ex, streak.ex
    todos/            schema/, repository.ex
    health/           schema/, repository.ex
    workouts/         schema/, actions/, repository.ex
    nutrition/        schema/, actions/, repository.ex, macros.ex
    accounts/         phx.gen.auth generated
  better_me_web/
    live/
      habits/         index.ex  show.ex  form.ex
      todos/          index.ex  form.ex
      health/         index.ex  form.ex
      workouts/       index.ex  show.ex  form.ex
      nutrition/      index.ex
      recipes/        index.ex  show.ex  form.ex
      ingredients/    index.ex  form.ex
    components/
      core_components.ex    # Phoenix primitives
      ui_components.ex      # app-specific components
    router.ex
```

## build phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Habits, todos, body metrics, gym tracking | complete |
| 2 | Nutrition + Go microservice | in progress |
| 3 | AI insights — RAG + Jido agents | planned |
| 4 | Analytics dashboards | planned |

## key commands

| Command | What it does |
|---|---|
| `mix ecto.reset` | Drop, recreate, and seed the database |
| `mix ecto.migrate` | Run pending migrations |
| `mix ecto.gen.migration name` | Generate a new migration |
| `mix precommit` | Full check: compile + format + credo + test |
