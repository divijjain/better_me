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
- Routine templates — save and reuse workout structures

### phase 2 — nutrition (complete)

**Ingredients**
- Food database with macros per 100g: calories, protein, carbs, fat, fiber, sugar, glycemic index, sodium
- Vegetarian / non-vegetarian flag
- Categorised (protein, vegetable, fruit, grain, dairy, legume, seafood, etc.) and brand-aware
- 98 ingredients pre-seeded across fruits, vegetables, proteins, grains, dairy, legumes, millets, and pulses
- Collapsible category groups with search and color-coded macro display

**Recipes**
- Build recipes by selecting ingredients and specifying quantity in grams
- Macros auto-calculated from ingredient data — no manual entry
- Tag recipes (e.g. lunch, high-protein, meal-prep)

**Daily Nutrition Log**
- Log meals by type (breakfast, lunch, dinner, snack) for any date
- Multiple entries per meal type supported
- Per-meal and daily macro totals (kcal, protein, carbs, fat)
- Navigate back through previous days
- Progress bars vs daily targets when a profile is set up

**User Profile & Macro Targets**
- Set height, weight, age, gender, and activity level
- TDEE calculated using Mifflin-St Jeor BMR formula
- Configure macro split (protein %, carbs %, fat auto-derived)
- Daily targets shown as progress bars on the nutrition log

### phase 3 — AI insights (complete)

**Journal**
- Daily mood (1–5 emoji picker), free-form notes, tags
- Full CRUD with date-locked entries (one per day)

**Embedding pipeline**
- Oban background job embeds journal entries, meal logs, and workouts into pgvector on create/update
- OpenAI `text-embedding-3-small` — 1536-dim vectors, stored in Postgres alongside original text
- Cosine similarity search via ivfflat index

**Insight chat**
- Natural language interface at `/insights`
- Fixed-step RAG workflow: embed question → similarity search across all domains → Claude answers
- Grounded in real personal data — no hallucination

### phase 4 — analytics (complete)

**CSS bar charts — no JS charting library**
- Body weight trend — last 30 days
- Workout frequency — sessions per week over 8 weeks
- Workout type breakdown — last 30 days
- Daily calorie totals — last 14 days
- Average mood per week — from journal entries
- Habit completion rates — % per habit over 30 days

### phase 5 — native integrations (planned)

- React Native + Expo app for native device features
- Apple Health (HealthKit) — sync weight, workouts, calories burned, steps (requires Expo)
- Android Health Connect — replacement for deprecated Google Fit, SDK-only, requires Expo

## stack

| Layer | Technology |
|---|---|
| Backend | Elixir / Phoenix (LiveView + JSON API) |
| Database | PostgreSQL + Ecto |
| Background jobs | Oban |
| AI / vector search | pgvector (Phase 3) |
| Embedding model | OpenAI `text-embedding-3-small` (Phase 3) |
| Chat model | Anthropic `claude-haiku-4-5-20251001` (Phase 3) |
| Frontend (Phase 1–2) | Phoenix LiveView — runs in mobile browser |
| Frontend (Phase 3+) | React Native + Expo — native features |

## getting started

```bash
cp .env.example .env   # copy env template, then fill in API keys
mix setup              # install deps, create DB, run migrations, seed
mix phx.server         # start the server at http://localhost:4000
```

Seed credentials:
- `divij@better.me` / `betterme2026!`
- `test@better.me` / `betterme2026!`

### environment variables

| Variable | Required | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | Phase 3 only | Embedding model (`text-embedding-3-small`) |
| `ANTHROPIC_API_KEY` | Phase 3 only | Claude for insight answers |

Phases 1 and 2 work without any API keys. Keys are only needed once you use the AI insights feature.

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
    profiles/         schema/, repository.ex, tdee.ex
    journals/         schema/, actions/, repository.ex
    embeddings/       schema/, jobs/, repository.ex
    insights/         insight_workflow.ex
    anthropic/        chat.ex
    openai/           embeddings.ex
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
      profile/        index.ex
      journal/        index.ex  form.ex
      insights/       index.ex
      analytics/      index.ex
    components/
      core_components.ex    # Phoenix primitives
      ui_components.ex      # app-specific components
    router.ex

priv/repo/
  seeds.exs                 # orchestrator — delegates to seeds/
  seeds/
    users.exs
    habits.exs
    routine_template.exs
    ingredients.exs                  # fruits & vegetables (35 items)
    ingredients_proteins.exs         # meat, seafood, eggs, dairy, plant proteins (23 items)
    ingredients_grains.exs           # grains, pasta, bread (18 items)
    ingredients_millets_pulses.exs   # millets & Indian pulses/dals (22 items)
```

## build phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Habits, todos, body metrics, gym tracking | complete |
| 2 | Nutrition — ingredients, recipes, meal logs, user profile | complete |
| 3 | AI insights — journal, RAG, insight workflow, chat UI | complete |
| 4 | Analytics dashboards — body weight, workouts, calories, mood, habits | complete |
| 5 | Native integrations — Apple Health, Google Fit | planned |

## AI architecture

### how embeddings work

When you write a journal entry, log a meal, or create a workout, better_me converts that text into a vector — a list of numbers that represents the *meaning* of the content. These vectors are stored in Postgres using pgvector alongside the original text.

```
User writes journal entry
        ↓
Saved to DB → EmbedJob enqueued (Oban, async)
        ↓
EmbedJob fetches text → calls OpenAI text-embedding-3-small → gets vector [0.1, 0.4, ...]
        ↓
Upserted into embeddings table
```

The same happens for meal logs and workouts. Embeddings run in the background via Oban so they never block the user.

### what is stored

```
source_type     source_id   content                                  embedding
journal_entry   42          Date: 2026-04-01 / Mood: 2 / Felt sluggish, skipped gym   [0.1, 0.4, ...]
meal_log        17          Date: 2026-04-01 / Meal: lunch / Recipe: Chicken Rice Bowl [0.3, 0.2, ...]
workout         8           Date: 2026-03-30 / Type: strength / Duration: 60 min       [0.6, 0.1, ...]
```

### how a query works (RAG)

```
User asks: "why was my energy low last week?"
        ↓
Question is embedded → vector [0.2, 0.5, ...]
        ↓
pgvector finds the 5 closest vectors (cosine similarity)
returns: journal entry (mood 2), meal log (pizza, high carbs), skipped workout
        ↓
Those records are sent to Claude as context
        ↓
Claude reads your actual data and answers:
"On April 1st you logged mood 2 and skipped your workout.
 The night before you had a high-carb dinner which may
 have affected your energy the next morning."
```

This is RAG (Retrieval Augmented Generation) — Claude is grounded in your real data, not guessing.

### system architecture

```
LiveView Chat UI (/insights)
        ↓
InsightWorkflow (plain Elixir) — fixed steps, no LLM routing
        ↓
QueryJournal / QueryNutrition / QueryWorkouts — similarity search
        ↓
Embeddings.Repository — pgvector <=> cosine distance, top-5 results
        ↓
PostgreSQL + pgvector — embeddings table with ivfflat index
        ↓
Claude (Anthropic) — generates answer grounded in retrieved data
```

### why Jido is not used right now

The insight feature is a **fixed-step workflow**, not an LLM-controlled agent. Every question goes through the same sequence:

1. Embed the question
2. Search journals for relevant entries
3. Search nutrition logs for relevant meals
4. Search workouts for relevant sessions
5. Send all retrieved chunks to Claude with the question
6. Return Claude's answer

Because the steps never change and the LLM doesn't need to decide *what to query next*, there's no benefit to Jido. Adding it would mean learning a new framework and wiring Action modules for zero real gain.

**Workflow vs agent — the distinction that matters:**

| | Workflow | Agent |
|---|---|---|
| Who controls flow | Code | LLM |
| Steps | Fixed, always the same | Dynamic, LLM picks tools |
| Use case | Structured RAG query | Multi-turn, proactive coaching |
| Complexity | Low | High |

The PRINCIPLES.md rule: *"Start every feature as a workflow. Upgrade to agent only if the LLM needs to decide what to query next."*

**When Jido would make sense:**
- The LLM needs to decide dynamically whether to look at habits vs nutrition vs workouts based on the question
- Multi-turn conversations where context from previous turns changes what to query
- Proactive coaching — agent wakes up, checks data, decides what insight to surface without being asked

These are Phase 4+ concerns. For now, a plain Elixir workflow is the right call.

### questions this enables

- "Why did my energy drop last week?" — journals + nutrition
- "What do I eat on my best training days?" — meals + workouts
- "Which habits correlate with my best moods?" — habits + journals
- "Am I making progress on strength?" — workouts over time
- "What's my typical Monday diet?" — meal logs

### components

| Component | Purpose | Status |
|---|---|---|
| pgvector extension + embeddings table | Vector storage in Postgres | Done |
| EmbedJob (Oban worker) | Async embedding pipeline | Done |
| Hooks in journal / meal log / workout | Auto-embed on create/update | Done |
| OpenAI text-embedding-3-small | Embedding model (see choice rationale below) | Done |
| InsightWorkflow (plain Elixir) | Fixed-step RAG: embed → search → Claude | Done |
| Chat UI (/insights) | Natural language interface | Done |

### models used

#### embedding model — `text-embedding-3-small` (OpenAI)

Converts text (journal entries, meal logs, workouts, and questions) into 1536-dimensional vectors stored in pgvector.

| Property | Detail |
|---|---|
| Provider | OpenAI |
| Model | `text-embedding-3-small` |
| Dimensions | 1536 |
| Cost | $0.02 / 1M tokens (~fractions of a cent/month at personal scale) |
| Key | `OPENAI_API_KEY` |

Why this model:
- **Battle-tested** — most widely used embedding model in production RAG systems
- **Right size** — 1536 dims is the sweet spot between quality and cost
- **Speed** — faster than `text-embedding-3-large` with minimal quality drop for short personal logs

**Switching models:** changing the embedding model invalidates all existing vectors — vector spaces from different models are incompatible. If you switch, run a backfill to re-embed all records. Never mix vectors from different models in the same table.

#### chat model — `claude-haiku-4-5-20251001` (Anthropic)

Reads the retrieved chunks and generates a grounded answer to the user's question.

| Property | Detail |
|---|---|
| Provider | Anthropic |
| Model | `claude-haiku-4-5-20251001` |
| Input cost | $0.80 / 1M tokens |
| Output cost | $4.00 / 1M tokens |
| Per query (est.) | ~$0.0005 (500 tokens in, 200 out) |
| Key | `ANTHROPIC_API_KEY` |

Why Haiku over Sonnet/Opus:
- Personal-use queries are simple retrieval + summarisation — Haiku handles them well
- ~10x cheaper than Sonnet for identical RAG tasks
- Fast response time for a chat-like UI

Upgrade to `claude-sonnet-4-6` in `lib/better_me/anthropic/chat.ex` if answer quality needs improvement.

Set both keys in your `.env` file (see `.env.example`).

### why each piece exists

| Piece | Why |
|---|---|
| Oban job | Embedding is slow (~200ms) — run async so the user isn't waiting |
| pgvector | Postgres extension — no separate vector DB needed |
| ivfflat index | Makes similarity search fast as data grows |
| content column | Stores original text so Claude can read it without joining back |
| source_type + source_id | Traces back to the original record |
| InsightWorkflow | Fixed steps: embed question → search all domains → Claude answers |
| RAG | Grounds Claude in real data — prevents hallucination |

## key commands

| Command | What it does |
|---|---|
| `mix ecto.reset` | Drop, recreate, and seed the database |
| `mix ecto.migrate` | Run pending migrations |
| `mix run priv/repo/seeds.exs` | Re-seed (idempotent — safe to run anytime) |
| `mix ecto.gen.migration name` | Generate a new migration |
| `mix precommit` | Full check: compile + format + credo + test |
