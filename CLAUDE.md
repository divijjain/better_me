# better-me — AI context file
# paste this at the start of any new conversation to restore context

## project
Mobile-first personal OS. Elixir/Phoenix backend, React Native (Expo) frontend.
Personal use. Not a SaaS product.

## stack
- Phoenix (JSON API + LiveView) + Ecto + PostgreSQL
- React Native + Expo (native app — `better_me_mobile/` repo, Expo Router v6)
- Oban (background jobs)
- Go microservice (macro/nutrition calculations only)
- pgvector (AI phase, same Postgres instance)
- No Jido — insight feature is a plain Elixir workflow (see rules below)
- LLM: Anthropic/OpenAI via req_llm
- Phoenix Channels — real-time push to mobile (workout, health, habits topics)

## no Ash
Plain contexts + changesets. Ash was considered and rejected — too much overhead
for a personal project. Revisit if resource count grows past 15.

## domain
users → todos, habits (+ habit_logs), workouts (+ exercises + exercise_sets + routine_templates),
        body_metrics (weight, body_fat_pct, measurements JSONB — steps/active_kcal/resting_hr/sleep),
        ingredients, recipes (+ recipe_ingredients + meal_logs),
        user_profiles, journal_entries, embeddings

## phases
1. Daily driver (habits, todos, body metrics, gym) — plain Phoenix + Ecto
2. Nutrition + user profiles + Go microservice
3. AI insights — RAG (pgvector) + plain Elixir insight workflow + journal entries
4. Analytics dashboards
5. Native integrations — React Native + Expo, Apple Health (HealthKit via react-native-health), Android Health Connect (replaces deprecated Google Fit, SDK-only via Expo)

## current phase
Phases 1–5 in progress. Native app feature-complete for core flows.
- Phase 1 complete: Habits, Todos, Body Metrics, Gym tracking.
- Phase 2 complete: Ingredients, Recipes, Meal logs, User Profiles (TDEE/macro targets).
- Phase 3 complete: Journal entries, pgvector + EmbedJob, InsightWorkflow (RAG), Insights chat UI.
- Phase 4 complete: Analytics dashboard (CSS bar charts — weight, workouts, calories, mood, habits).
- Phase 5 active: React Native + Expo app (`better_me_mobile/`). Core screens done. HealthKit sync live.
- Deployed: Fly.io (bom region). CI/CD via GitHub Actions. See FLY_DEPLOYMENT.md.

## mobile app (better_me_mobile)
Separate repo at `../better_me_mobile`. Expo Router v6, TypeScript.

**Tab nav:** Habits | Food | Gym | Body | More
**Screens:**
- Habits: list (tap to edit), new, edit/delete ([id])
- Todos: list, new, edit/delete ([id])
- Workouts: list, new, detail with live exercise logging ([id] via Phoenix Channel)
- Health (Body Stats): list with delete, log manually, sync from Apple Health / Android Health Connect
- Nutrition: daily summary with meal logging
- Journal: list, new, edit/delete ([id])
- Insights: AI chat (RAG)
- More: nav hub → Dashboard, Tasks, Journal, AI Insights + Sign out

**Key libs:** `react-native-health` (iOS HealthKit), `react-native-health-connect` (Android),
`@tanstack/react-query`, `phoenix` (JS socket), `expo-secure-store`, `expo-router`

**API:** all calls go to `/api/*` on the Phoenix backend with Bearer token auth.
**Real-time:** Phoenix Channels — `workout:<id>`, `health:<user_id>`, `habits:<user_id>`

**HealthKit sync** (`lib/healthkit.ts` → `syncHealth()`):
Reads in parallel: weight, steps, active kcal, resting HR, sleep minutes.
Posts one `logMetric` call per day. Stored in `body_metrics.measurements` JSONB.
Note: `measurements` JSONB is pragmatic but lacks column-level type safety — consider
a dedicated `activity_logs` table if steps/sleep trends or analytics are needed.

**Auth flow:** Google OAuth on web → token stored in SecureStore → sent as Bearer on every API call.

## rules
- No Jido. Insight feature is a plain Elixir workflow — code controls the steps.
- Go microservice is stateless. Phoenix owns all state.
- Oban for all async. No raw Task.async in production.
- Phase 1 has zero AI. Build data layer first.
- Start every feature as a workflow. Upgrade to agent only if LLM needs
  to decide what to query next.

## key concepts
RAG: embed data → store in pgvector → at query time, embed question →
     similarity search → retrieved chunks → LLM prompt → grounded answer

Workflow vs agent: workflow = code controls flow, LLM fills a slot at the end.
     agent = LLM controls flow, decides which tools to call next.
     InsightWorkflow is a workflow: always embed → search journals → search nutrition
     → search workouts → send to Claude. Steps never change, so no agent needed.
     Upgrade to Jido only if the LLM needs to decide dynamically what to query.

## go context
Learning Go in parallel. Two-week ramp:
Week 1: Go tour, structs, interfaces, error handling
Week 2: net/http, JSON, macro calculator endpoint, binary → called from Phoenix
Go is secondary. Elixir is primary.

## what to ask claude
- "implement [feature] for Phase 1 following the context above"
- "write the Ecto schema and context for [resource]"
- "write the Expo screen for [feature]"
- "help me write the Go macro calculator endpoint"
- "build the InsightWorkflow (plain Elixir, no Jido)"
- "add [feature] to the mobile app matching the web version"
- "add a Phoenix Channel for [resource] with real-time push to mobile"
