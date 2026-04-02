# better-me — project context

## what this is
A mobile-first personal OS for Divij. Tracks daily todos, gym workouts, body metrics,
nutrition/recipes, habits/streaks, journaling, and AI-powered insights over personal data.
Built for personal use first. Not a SaaS product.

## stack decisions

### Phoenix + Ecto (no Ash)
Plain Phoenix API (JSON mode) + Ecto + PostgreSQL. Ash was considered and rejected —
too much learning curve for a personal project with no team. Plain contexts + changesets
move faster and are easier to debug. Ash becomes relevant if the resource count grows
beyond 15 and an auto-generated API is needed.

### React Native (Expo)
Mobile-first. Expo gives cross-platform iOS + Android without going fully native.
Phoenix serves a JSON API; React Native consumes it.

LiveView is acceptable for Phase 1 — LiveView apps run in any mobile browser, so
the personal daily-driver UI can be built with LiveView without a separate React
Native project. React Native enters in Phase 2+ when native device features are
needed (push notifications, offline, sensors).

### Oban
Background jobs: morning digest, habit reminders, streak calculations, embedding jobs.
Standard Oban — no agentic behaviour here, just reliable scheduled work.

### Go microservice
Single bounded service for nutrition/macro calculations. Reasons:
- CPU-bound math (TDEE, macro splits, BMR) is a natural fit for Go
- Self-contained — no shared state with Phoenix
- Learning vehicle for Go without abandoning Elixir
- Ships as a static binary, called over internal HTTP from Phoenix
- If Go knowledge is never needed, this service can be rewritten in Elixir with no
  architectural impact

### pgvector
Vector similarity search inside the existing PostgreSQL instance. Powers the AI insights
phase. Embeddings table stores vectors for journal entries, workout notes, meal logs.
No separate vector DB — keeps the infrastructure simple.

### Jido (Phase 3 only)
Agent framework on top of OTP. NOT used for CRUD, scheduled jobs, or single LLM calls.
Used only where the LLM needs to decide what to query next — insight agent, meal planner,
habit coach. Jido actions wrap existing Ecto context functions. No data layer changes
when Jido is introduced.

### LLM API
Anthropic (Claude) or OpenAI via req_llm. Direct API calls in Phase 3. No LangChain
or high-level wrappers — keeps the stack transparent and debuggable.

---

## domain model

```
users
  todos          (title, category, due_date, completed, priority, repeat)
  habits         (name, category, target_frequency)
    habit_logs   (date, completed, note)
  workouts       (date, type, duration, notes)
    exercises    (name, sets, reps, weight, rpe)
  body_metrics   (date, weight, body_fat_pct, measurements jsonb)
  recipes        (title, ingredients jsonb, macros jsonb, tags)
    meal_logs    (date, recipe_id, servings, meal_type)
  journal_entries(date, content, mood, energy_level)
  embeddings     (content, source_type, source_id, vector)
```

---

## build phases

### phase 1 — daily driver (weeks 1–4)
Goal: app usable for yourself. Full stack wired end to end.

- Week 1: Phoenix API + Expo skeleton + one working endpoint (habits CRUD)
- Week 2: Habits + streak calculation
- Week 3: Todos (with categories) + body metrics
- Week 4: Gym tracking (workouts → exercises → sets/reps/weight, PR detection)

Start with Habits. It is the smallest complete vertical slice — one resource,
one screen, one streak calculation. Everything else is a variation on that pattern.

### phase 2 — nutrition + Go (weeks 5–8)
- Go microservice: POST /calculate-macros, POST /calculate-tdee
- Recipes CRUD with ingredients and macros
- Meal logging (one-tap from recipe)
- Daily macro progress
- Push notifications via Expo Push API

### phase 3 — AI insights (weeks 9–12)
- pgvector extension + embeddings table
- Oban job: embed all existing data on write
- RAG pipeline: embed question → similarity search → LLM call
- Jido introduced here for insight agent, meal planner, habit coach
- Example queries the agent handles:
  - "Why did my energy crash Thursday?"
  - "What did I eat on my best training days?"
  - "Suggest a meal for today based on my macro target and past preferences"

### phase 4 — analytics (weeks 13–16)
- Body weight trend + 7-day moving average
- Workout volume per week per muscle group
- Habit completion heatmap
- Macro adherence % over time
- Mood/energy vs sleep/nutrition correlation

---

## key architectural rules

1. Jido wraps Ecto, not the other way around. Data layer never changes when agents
   are introduced.
2. Go microservice is stateless. Phoenix owns all persistent state.
3. One PostgreSQL instance for everything — relational data + pgvector. No separate
   vector DB.
4. Oban for all async work. No raw Task.async in production paths.
5. Phase 1 ships with zero AI. Agents require good data to reason over — build the
   data layer first.

---

## concurrency model reference

| need | tool |
|---|---|
| scheduled/background jobs | Oban |
| parallel data fetching | Task.async_stream |
| long-running stateful agent | Jido AgentServer |
| real-time push to mobile | Phoenix Channels + Expo Push |
| CPU-bound computation | Go microservice |

---

## go learning path (parallel track)
Week 1: Go tour (tour.golang.org), structs, interfaces, error handling pattern
Week 2: net/http or Gin, JSON encode/decode, write the macro calculator, unit tests,
        build binary, call from Phoenix

Go is a secondary tool. Elixir remains primary. Go enters only for the nutrition
microservice and any future CLI tooling or infrastructure scripts.

---

## what RAG is (for reference)
Retrieval-Augmented Generation. Gives the LLM access to personal data without
retraining it.

Phase 1 — indexing: chunk personal data → embedding model → store vectors in pgvector
Phase 2 — query: embed user question → similarity search → retrieve top N chunks →
          stuff into LLM prompt → LLM answers grounded in real data

The LLM never saw the personal data in training. It reads it at query time.

---

## what agents vs workflows means here

Workflow: code controls the flow. LLM fills slots at fixed points.
  Examples: morning digest (Oban), workout auto-tagging, weekly summary

Agent: LLM controls the flow. Decides which tools to call and in what order.
  Examples: insight agent, meal planner, habit coach

Test: "Could I draw a complete flowchart before the LLM runs?"
  Yes → workflow. No → agent.

Use workflows for Phase 1–2. Agents enter in Phase 3 only where dynamic
tool selection is genuinely needed.
