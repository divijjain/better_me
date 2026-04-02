# better-me — AI context file
# paste this at the start of any new conversation to restore context

## project
Mobile-first personal OS. Elixir/Phoenix backend, React Native (Expo) frontend.
Personal use. Not a SaaS product.

## stack
- Phoenix (JSON API + LiveView) + Ecto + PostgreSQL
- React Native + Expo (Phase 2+ for native features; LiveView covers Phase 1 mobile UI)
- Oban (background jobs)
- Go microservice (macro/nutrition calculations only)
- pgvector (AI phase, same Postgres instance)
- Jido (Phase 3 only — AI agents)
- LLM: Anthropic/OpenAI via req_llm

## no Ash
Plain contexts + changesets. Ash was considered and rejected — too much overhead
for a personal project. Revisit if resource count grows past 15.

## domain
users → todos, habits (+ habit_logs), workouts (+ exercises), body_metrics,
        recipes (+ meal_logs), journal_entries, embeddings

## phases
1. Daily driver (habits, todos, body metrics, gym) — plain Phoenix + Ecto
2. Nutrition + Go microservice
3. AI insights — RAG (pgvector) + Jido agents
4. Analytics dashboards

## current phase
Phase 1 — Week 2: Habits + streak calculation complete. Next: Todos + body metrics (Week 3)

## rules
- Jido wraps Ecto, never replaces it. Data layer unchanged when agents enter.
- Go microservice is stateless. Phoenix owns all state.
- Oban for all async. No raw Task.async in production.
- Phase 1 has zero AI. Build data layer first.
- Start every feature as a workflow. Upgrade to agent only if LLM needs
  to decide what to query next.

## key concepts
RAG: embed data → store in pgvector → at query time, embed question →
     similarity search → retrieved chunks → LLM prompt → grounded answer

Agent vs workflow: workflow = code controls flow, LLM fills slots.
     agent = LLM controls flow, decides which tools to call.
     Agents only in Phase 3: insight agent, meal planner, habit coach.

Jido in this project: Jido Actions wrap existing Ecto context functions.
     InsightAgent calls QueryWorkouts, QueryNutrition, QueryJournal, CallLLM
     as actions. The agent decides the order. No data layer changes.

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
- "scaffold the Jido insight agent using existing context functions"
