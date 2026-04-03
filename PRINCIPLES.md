# better_me — Elixir design principles

These are the agreed design principles for this codebase.
Reference this before writing any new module.

---

## 1. domain-driven boundaries

### principle
Each domain is a self-contained context. Nothing outside the context
touches its schemas directly. All access goes through the context module.

### rules
- One context per domain: Habits, Todos, Workouts, Health, Nutrition, Journal
- Contexts are the public API. Schemas are private implementation detail.
- No cross-context schema imports. If Nutrition needs user data, it calls
  Accounts.get_user/1, not %Accounts.User{} directly.
- Cross-context communication via return values, never shared Ecto queries.

### structure
```
lib/better_me/
  habits/
    schema/
      habit.ex          # schema — private to context
      habit_log.ex      # schema — private to context
    actions/
      log_habit.ex      # coordination logic with side effects
    streak.ex           # pure business logic module
  habits.ex             # context — public API

  todos/
    schema/
      todo.ex
  todos.ex

  workouts/
    schema/
      workout.ex
      exercise.ex
  workouts.ex

  health/
    schema/
      body_metric.ex
  health.ex

  nutrition/
    schema/
      recipe.ex
      meal_log.ex
  nutrition.ex

  journal/
    schema/
      entry.ex
  journal.ex
```

### good
```elixir
# caller knows nothing about the schema
{:ok, habit} = BetterMe.Habits.create_habit(user_id, attrs)
streak = BetterMe.Habits.current_streak(habit.id)
```

### bad
```elixir
# leaking schema knowledge outside the context
alias BetterMe.Habits.Habit
%Habit{} |> Habit.changeset(attrs) |> Repo.insert()
```

---

## 2. three-layer internal structure

### principle
Every context is split into three internal layers. The public API file
(`habits.ex`) delegates everything — it contains no logic. All Repo calls
live in `repository.ex`. Coordination logic and side effects live in
`actions/*.ex`. Pure business logic lives in dedicated modules (e.g. `streak.ex`).

```
public API  →  habits.ex          defdelegate only, no logic
repo layer  →  habits/repository.ex   all Repo.* calls, query composition
action layer → habits/actions/*.ex    coordination, side effects, multi-step ops
pure logic  →  habits/streak.ex       no DB, no side effects
schemas     →  habits/schema/*.ex     Ecto schemas and changesets
```

### rules
- `habits.ex` contains only `defdelegate` — nothing else. Ever.
- `repository.ex` is the only file that calls `Repo.*` directly
- Action modules call `Repository.*` and other actions — never `Repo.*` directly
- Action modules are private — never called from outside the context
- Pure logic modules (streak calc, macro math) have no DB or side-effect dependencies
- Keep action modules focused: if it grows beyond ~30 lines, split it

### structure
```
lib/better_me/
  habits/
    schema/
      habit.ex            # Ecto schema + changesets
      habit_log.ex        # Ecto schema + changesets
    actions/
      log_habit.ex        # logs habit, enforces one-per-day constraint
      list_with_meta.ex   # bulk loads habits + streak + today status (2 queries)
    repository.ex         # all Repo calls — get, list, insert, update, delete
    streak.ex             # pure streak calculation, no DB
  habits.ex               # public API — defdelegate only
```

Note: action modules here are plain Elixir modules, not Jido Actions. Jido Actions
(Phase 3) are a separate concept — they wrap context functions for LLM agent use.

### good — public API is a pure index
```elixir
defmodule BetterMe.Habits do
  alias BetterMe.Habits.Repository
  alias BetterMe.Habits.Actions.{LogHabit, ListWithMeta}

  defdelegate list_habits(user_id, opts \\ []),    to: Repository
  defdelegate list_habits_with_meta(user_id),      to: ListWithMeta, as: :run
  defdelegate get_habit(id, user_id),              to: Repository
  defdelegate get_habit!(id, user_id),             to: Repository
  defdelegate create_habit(user_id, attrs),        to: Repository
  defdelegate update_habit(habit, attrs),          to: Repository
  defdelegate delete_habit(habit),                 to: Repository
  defdelegate new_habit(),                         to: Repository
  defdelegate change_habit(habit, attrs \\ %{}),   to: Repository
  defdelegate log_habit(habit_id, attrs),          to: LogHabit, as: :run
  defdelegate current_streak(habit_id, user_id),  to: Repository
  defdelegate recent_logs(habit_id, user_id, days \\ 30), to: Repository
  defdelegate logged_today?(habit_id, user_id),   to: Repository
end
```

### good — repository owns all Repo calls
```elixir
defmodule BetterMe.Habits.Repository do
  import Ecto.Query
  alias BetterMe.Repo
  alias BetterMe.Habits.{Streak}
  alias BetterMe.Habits.Schema.{Habit, HabitLog}

  def list_habits(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    Habit |> where(user_id: ^user_id, active: true) |> limit(^limit) |> Repo.all()
  end

  def get_habit(id, user_id) do
    case Repo.get_by(Habit, id: id, user_id: user_id) do
      nil   -> {:error, :not_found}
      habit -> {:ok, habit}
    end
  end
  # ... all other Repo calls
end
```

### good — action coordinates repository calls
```elixir
defmodule BetterMe.Habits.Actions.ListWithMeta do
  alias BetterMe.Habits.Repository
  alias BetterMe.Habits.Streak

  def run(user_id) do
    habits     = Repository.list_habits(user_id)
    habit_ids  = Enum.map(habits, & &1.id)
    streak_map = Repository.streak_map_for(habit_ids)
    logged_set = Repository.logged_today_set_for(habit_ids)

    Enum.map(habits, fn habit ->
      habit
      |> Map.put(:streak, Map.get(streak_map, habit.id, []) |> Streak.calculate())
      |> Map.put(:logged_today, MapSet.member?(logged_set, habit.id))
    end)
  end
end
```

### bad — context mixes query logic, coordination, and public API
```elixir
defmodule BetterMe.Habits do
  # doing too much — query logic, coordination, and public API all in one place
  def list_habits_with_meta(user_id) do
    habits = Habit |> where(user_id: ^user_id) |> Repo.all()  # Repo call in context
    Enum.map(habits, fn habit ->
      Map.put(habit, :streak, current_streak(habit.id))        # N+1 hidden here
    end)
  end
end
```

### when to use each layer
| Scenario | Layer |
|---|---|
| Simple CRUD, single Repo call | `repository.ex` + delegate |
| Multi-step with side effects (jobs, notifications) | `actions/*.ex` |
| Crosses multiple repo calls + needs coordination | `actions/*.ex` |
| Pure calculation, no DB | dedicated module (e.g. `streak.ex`) |

### the strict boundary rule

Keep the boundaries absolute. This is what makes the design work:

**`repository.ex` only touches `Repo.*`**
No coordination, no side effects, no calling other contexts. If a function
in repository.ex needs to call another function in repository.ex to work,
that is a sign it belongs in an action module instead.

**`actions/*.ex` never calls `Repo.*` directly**
Actions coordinate — they call `Repository.*` functions and other actions.
If an action is calling `Repo.insert` directly, the insert logic belongs
in repository.ex and the action should call that instead.

**Anything that bridges two repository calls belongs in an action module**
This is the most common judgement call. The test:
> "Does this function need results from one query to decide what to do next?"

If yes — it is coordination, it belongs in an action. `list_habits_with_meta`
is the canonical example: it calls `list_habits`, then uses the result to call
`streak_map_for` and `logged_today_set_for`. That sequencing is coordination,
not a query — so it lives in `Actions.ListWithMeta`, not `repository.ex`.

**When unsure, ask:**
- Does it call `Repo.*`? → repository
- Does it sequence multiple repository calls? → action
- Does it have side effects (Oban jobs, emails, notifications)? → action
- Does it do pure math or data transformation with no I/O? → dedicated module

### size as a signal
- Action module growing past ~30 lines → split into two actions
- `repository.ex` growing past ~150 lines → extract a query helper module
- If you find yourself writing logic inside `repository.ex` to decide *which*
  query to run based on previous results — move it to an action

---

## 3. context design

### principle
The public context file (`habits.ex`) is a pure delegation index — nothing else.
All logic is pushed into the three internal layers: repository, actions, pure modules.
The context file should be scannable in seconds and never need to change for
implementation reasons — only when the public API surface changes.

### rules
- `habits.ex` contains only `defdelegate` — no `import`, no `alias`, no logic
- All `Repo.*` calls live exclusively in `repository.ex`
- Actions coordinate repository calls and side effects — never call `Repo.*` directly
- Repository and action functions always scope to `user_id` — never fetch data without it
- Pure logic (streak calc, macro math) lives in its own module with no DB dependency
- Avoid god repositories. If `repository.ex` exceeds ~150 lines, extract query helpers

### function naming conventions
These names appear in the public API (`habits.ex`) and are implemented in `repository.ex`
or an action module. The caller never knows or cares which layer handles it.

```elixir
list_habits(user_id, opts \\ [])       # returns list, never raises
get_habit(id, user_id)                 # returns {:ok, habit} | {:error, :not_found}
get_habit!(id, user_id)                # returns habit | raises — only in LiveView assigns
create_habit(user_id, attrs)           # returns {:ok, habit} | {:error, changeset}
update_habit(habit, attrs)             # returns {:ok, habit} | {:error, changeset}
delete_habit(habit)                    # returns {:ok, habit} | {:error, reason}
log_habit(habit_id, attrs)             # domain verb — delegates to action module
current_streak(habit_id, user_id)      # scoped query — implemented in repository
list_habits_with_meta(user_id)         # coordination — delegates to action module
```

### always scope to user — enforced in repository
```elixir
# good — user_id scoped in repository, safe
def get_habit(id, user_id) do
  case Repo.get_by(Habit, id: id, user_id: user_id) do
    nil   -> {:error, :not_found}
    habit -> {:ok, habit}
  end
end

# bad — anyone can fetch any habit by id
def get_habit(id), do: Repo.get!(Habit, id)
```

---

## 4. schema + changeset patterns

### principle
Schemas define shape. Changesets define rules. Keep them separate
and composable. One changeset per action when actions have different rules.

### rules
- Use plain integer primary keys — phx.gen.auth generates integer-keyed tables and
  mixing binary_id causes foreign key type mismatches that are hard to debug
- Embed metadata as :map for flexible fields (measurements, tags, macros)
  rather than normalising into extra tables prematurely
- Use Ecto.Enum for fields with a fixed set of values
- Never put authorization logic in a changeset
- Multiple changesets per schema when different actions have different rules

### integer primary keys — default, no config needed
Plain integers are the Ecto default. Do not set `migration_primary_key` in config.
Do not set `@primary_key` or `@foreign_key_type` in schemas unless you have a
specific reason — letting Ecto default to `:id` keeps everything consistent with
phx.gen.auth generated tables.

### multiple changesets for different actions
```elixir
defmodule BetterMe.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "habits" do
    field :name,      :string
    field :category,  Ecto.Enum,
      values: [:health, :fitness, :personal, :learning, :work, :misc]
    field :frequency, Ecto.Enum,
      values: [:daily, :weekly, :monthly],
      default: :daily
    field :active,    :boolean, default: true
    belongs_to :user, BetterMe.Accounts.User
    has_many   :logs, BetterMe.Habits.HabitLog
    timestamps()
  end

  # used for create
  def create_changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :category, :frequency])
    |> validate_required([:name, :category])
    |> validate_length(:name, min: 1, max: 100)
  end

  # used for update — name and category can change, frequency cannot
  def update_changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :category, :active])
    |> validate_required([:name, :category])
    |> validate_length(:name, min: 1, max: 100)
  end
end
```

### embed flexible data as map
```elixir
# body_metric.ex — measurements vary per person
schema "body_metrics" do
  field :date,         :date
  field :weight,       :float
  field :body_fat_pct, :float
  field :measurements, :map, default: %{}
  # measurements stores: %{"chest" => 100, "waist" => 82, "hips" => 95}
  belongs_to :user, BetterMe.Accounts.User
  timestamps()
end
```

---

## 5. error handling

### principle
Errors are data. Use tagged tuples consistently. Never use exceptions
for control flow. Exceptions are for truly unexpected failures only.

### rules
- All context functions return {:ok, result} | {:error, reason}
- Reason is a changeset (validation failure), atom (:not_found,
  :unauthorized), or string (external service error)
- Use `with` for multi-step operations — fail fast, one error path
- Bang functions (get_habit!) only in LiveView assigns where a missing
  record should crash the process and show a 404 — never in business logic
- Never rescue in context functions — let it crash, let OTP handle it

### with for multi-step operations
```elixir
def log_and_notify(user_id, habit_id, attrs) do
  with {:ok, habit}  <- get_habit(habit_id, user_id),
       {:ok, log}    <- log_habit(habit.id, attrs),
       {:ok, _notif} <- Notifications.send_streak_alert(user_id, habit) do
    {:ok, log}
  end
  # any step returning {:error, reason} short-circuits here
  # no else clause needed unless you want to transform errors
end
```

### transforming errors when needed
```elixir
def log_and_notify(user_id, habit_id, attrs) do
  with {:ok, habit} <- get_habit(habit_id, user_id),
       {:ok, log}   <- log_habit(habit.id, attrs) do
    {:ok, log}
  else
    {:error, :not_found}  -> {:error, :habit_not_found}
    {:error, %Ecto.Changeset{} = cs} -> {:error, cs}
  end
end
```

### LiveView error handling
```elixir
# in LiveView — bang is acceptable, renders 404 on miss
def handle_params(%{"id" => id}, _url, socket) do
  habit = Habits.get_habit!(id, socket.assigns.current_user.id)
  {:noreply, assign(socket, :habit, habit)}
end

# in context — never bang
def get_habit(id, user_id) do
  case Repo.get_by(Habit, id: id, user_id: user_id) do
    nil   -> {:error, :not_found}
    habit -> {:ok, habit}
  end
end
```

---

## 6. performance + query patterns

### principle
Fetch only what you need. Avoid N+1 queries. Let the database do
the work — not Elixir.

### rules
- Never load associations you don't use
- Preload explicitly — never rely on lazy loading (it doesn't exist in Ecto)
- Use Ecto.Query for filtering, sorting, limiting — not Enum after the fact
- Always add indexes on foreign keys and frequently filtered columns
- Use select to limit columns on large tables
- Paginate all list queries — never fetch unbounded lists

### explicit preloading
```elixir
# good — preload only when the caller needs logs
def list_habits_with_recent_logs(user_id) do
  Habit
  |> where(user_id: ^user_id, active: true)
  |> preload([h], logs: ^recent_logs_query())
  |> Repo.all()
end

defp recent_logs_query do
  since = Date.add(Date.utc_today(), -7)
  from l in HabitLog, where: l.date >= ^since, order_by: [desc: l.date]
end

# bad — loads all logs for all habits, always
def list_habits(user_id) do
  Habit |> where(user_id: ^user_id) |> preload(:logs) |> Repo.all()
end
```

### filter in the query, not in Elixir
```elixir
# good — database does the work
def list_todos(user_id, opts \\ []) do
  done     = Keyword.get(opts, :done, false)
  category = Keyword.get(opts, :category)

  Todo
  |> where(user_id: ^user_id, done: ^done)
  |> maybe_where_category(category)
  |> order_by([t], [asc: t.priority, asc: t.due_date])
  |> limit(100)
  |> Repo.all()
end

defp maybe_where_category(q, nil), do: q
defp maybe_where_category(q, cat), do: where(q, category: ^cat)

# bad — fetches everything, filters in memory
def list_todos(user_id) do
  Todo
  |> where(user_id: ^user_id)
  |> Repo.all()
  |> Enum.filter(&(&1.done == false))
end
```

### index every foreign key + filter column
```elixir
# in every migration
create index(:habits,     [:user_id])
create index(:habit_logs, [:habit_id])
create index(:habit_logs, [:habit_id, :date])  # compound — used in streak query
create index(:todos,      [:user_id, :done])   # compound — used in list_todos
create index(:workouts,   [:user_id, :date])
```

---

## 7. LiveView structure

### principle
LiveView modules are thin. They handle events and assign state.
All business logic lives in contexts — LiveView just calls them.

### rules
- One LiveView per page, not per component
- Extract reusable UI into function components (not LiveComponents
  unless independent server state is needed)
- Use LiveComponents only for forms with their own changeset lifecycle
- Keep handle_event callbacks to 3–5 lines — delegate to context immediately
- Assign minimal state — only what the template actually renders
- Use handle_params for URL-driven state (filters, selected item)
- Streams for large lists — don't assign a list of 1000 items to socket

### LiveView module structure (consistent order)
```elixir
defmodule BetterMeWeb.HabitsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Habits

  # 1. mount
  def mount(_params, _session, socket) do
    {:ok, assign(socket, habits: [], streak_map: %{})}
  end

  # 2. handle_params (URL-driven state)
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # 3. render (or use template file)
  def render(assigns) do
    ~H"""
    ...
    """
  end

  # 4. handle_event (thin — delegate to context)
  def handle_event("complete_habit", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    habit   = Habits.get_habit!(id, user_id)

    case Habits.log_habit(habit.id, %{date: Date.utc_today(), completed: true}) do
      {:ok, _log} ->
        {:noreply, reload_habits(socket)}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not log habit")}
    end
  end

  # 5. private helpers
  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Habits")
  end

  defp reload_habits(socket) do
    user_id = socket.assigns.current_user.id
    habits  = Habits.list_habits(user_id)
    assign(socket, :habits, habits)
  end
end
```

### form components with their own changeset
```elixir
defmodule BetterMeWeb.HabitsLive.FormComponent do
  use BetterMeWeb, :live_component

  alias BetterMe.Habits

  def update(%{habit: habit} = assigns, socket) do
    changeset = Habits.change_habit(habit)
    {:ok, socket |> assign(assigns) |> assign_form(changeset)}
  end

  def handle_event("validate", %{"habit" => params}, socket) do
    changeset =
      socket.assigns.habit
      |> Habits.change_habit(params)
      |> Map.put(:action, :validate)
    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"habit" => params}, socket) do
    save_habit(socket, socket.assigns.action, params)
  end

  defp save_habit(socket, :new, params) do
    user_id = socket.assigns.current_user.id
    case Habits.create_habit(user_id, params) do
      {:ok, _habit} ->
        {:noreply, socket |> put_flash(:info, "Habit created") |> push_navigate(to: ~p"/habits")}
      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
```

---

## 8. testing approach

### principle
Test contexts, not implementation. LiveView tests for user-facing
behaviour. No testing of private functions or internal schema details.

### rules
- Context tests are the most important — they test your domain logic
- Use ExUnit, no extra testing libraries needed for Phase 1
- One test file per context module
- Factories via ex_machina or simple helper functions — no fixtures
- Test the happy path and the two most likely failure paths
- LiveView tests for critical user flows only — not every click
- No mocking in Phase 1 — test against the real DB with Sandbox

### context test structure
```elixir
defmodule BetterMe.HabitsTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Habits

  # group by function
  describe "create_habit/2" do
    test "creates with valid attrs" do
      user = user_fixture()
      assert {:ok, habit} = Habits.create_habit(user.id, %{
        name: "Morning run",
        category: "fitness"
      })
      assert habit.name == "Morning run"
      assert habit.user_id == user.id
    end

    test "returns error with missing name" do
      user = user_fixture()
      assert {:error, changeset} = Habits.create_habit(user.id, %{category: "fitness"})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error with invalid category" do
      user = user_fixture()
      assert {:error, changeset} = Habits.create_habit(user.id, %{
        name: "Run",
        category: "invalid_category"
      })
      assert %{category: [_]} = errors_on(changeset)
    end
  end

  describe "current_streak/1" do
    test "returns 0 with no logs" do
      user  = user_fixture()
      {:ok, habit} = Habits.create_habit(user.id, %{name: "Run", category: "fitness"})
      assert Habits.current_streak(habit.id) == 0
    end

    test "returns correct streak for consecutive days" do
      user  = user_fixture()
      {:ok, habit} = Habits.create_habit(user.id, %{name: "Run", category: "fitness"})
      today     = Date.utc_today()
      yesterday = Date.add(today, -1)

      Habits.log_habit(habit.id, %{date: today,     completed: true})
      Habits.log_habit(habit.id, %{date: yesterday, completed: true})

      assert Habits.current_streak(habit.id) == 2
    end

    test "resets streak on missed day" do
      user  = user_fixture()
      {:ok, habit} = Habits.create_habit(user.id, %{name: "Run", category: "fitness"})
      today       = Date.utc_today()
      two_days_ago = Date.add(today, -2)

      Habits.log_habit(habit.id, %{date: today,        completed: true})
      Habits.log_habit(habit.id, %{date: two_days_ago, completed: true})

      assert Habits.current_streak(habit.id) == 1
    end
  end
end
```

### test helpers — keep in test/support/helpers.ex
```elixir
defmodule BetterMe.TestHelpers do
  alias BetterMe.{Accounts, Habits, Todos}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} = attrs
      |> Enum.into(%{email: "user#{System.unique_integer()}@test.com", password: "password123"})
      |> Accounts.register_user()
    user
  end

  def habit_fixture(user_id, attrs \\ %{}) do
    {:ok, habit} = attrs
      |> Enum.into(%{name: "Test habit", category: "fitness"})
      |> then(&Habits.create_habit(user_id, &1))
    habit
  end
end
```

---

## 9. elixir fundamentals

### immutability & pipelines
All data is immutable. Functions return new values, never mutate in place.
Use `|>` to express data transformation as a pipeline — one operation flowing into the next.

```elixir
# good
user
|> cast(attrs, [:name, :email])
|> validate_required([:name, :email])
|> unique_constraint(:email)

# bad
changeset = cast(user, attrs, [:name, :email])
changeset = validate_required(changeset, [:name, :email])
changeset = unique_constraint(changeset, :email)
```

### pattern matching over conditionals
Match on function arguments directly. Use multiple function clauses for different
cases rather than branching inside one function body.

```elixir
# good
def streak_message(0), do: "Start your streak today!"
def streak_message(1), do: "1 day — keep going!"
def streak_message(n), do: "#{n} days — great work!"

# bad
def streak_message(n) do
  if n == 0 do
    "Start your streak today!"
  else
    ...
  end
end
```

### let it crash
Don't defensively catch every error. If something unexpected happens, let the
process crash. OTP supervisors restart crashed processes — that is the recovery
mechanism, not try/rescue. Reserve `rescue` for external boundaries (HTTP calls,
file I/O).

```elixir
# good — unexpected DB failure crashes the process, supervisor restarts it
def create_habit(user_id, attrs) do
  %Habit{}
  |> Habit.create_changeset(Map.put(attrs, :user_id, user_id))
  |> Repo.insert()
end

# bad — swallowing unexpected errors silently
def create_habit(user_id, attrs) do
  try do
    %Habit{} |> Habit.create_changeset(attrs) |> Repo.insert()
  rescue
    _ -> {:error, :unknown}
  end
end
```

### tagged tuples & with
`{:ok, result}` and `{:error, reason}` everywhere. No naked returns, no
exceptions for control flow. `with` chains these — any `{:error, _}` short-circuits.

```elixir
# good
def log_and_update_streak(user_id, habit_id, attrs) do
  with {:ok, habit}  <- get_habit(habit_id, user_id),
       {:ok, log}    <- log_habit(habit.id, attrs),
       {:ok, streak} <- recalculate_streak(habit.id) do
    {:ok, %{log: log, streak: streak}}
  end
end
```

### processes & message passing
Concurrency via lightweight processes, not threads. Each process has its own heap.
No shared mutable state — processes communicate only by sending messages.

| need | tool |
|---|---|
| stateful long-running process | GenServer |
| one-off async work | Task |
| simple shared state | Agent |
| scheduled/background jobs | Oban (in this project) |

### recursion & Enum
No `for` loops. Iteration is via `Enum` (eager) or `Stream` (lazy).

```elixir
# good
habit_ids |> Enum.map(&recalculate_streak/1)
logs      |> Enum.filter(&(&1.completed == true)) |> Enum.count()

# for large/lazy sequences — Stream avoids loading everything into memory
entries
|> Stream.filter(&(&1.mood >= 4))
|> Stream.map(&embed_entry/1)
|> Enum.to_list()
```

### behaviours & protocols for polymorphism
No classes or inheritance. Use `@behaviour` for defining contracts a module must
implement, and `Protocol` for polymorphism across data types.

```elixir
# behaviour — all notifiers must implement notify/2
defmodule BetterMe.Notifier do
  @callback notify(user :: map(), message :: String.t()) :: :ok | {:error, term()}
end

defmodule BetterMe.PushNotifier do
  @behaviour BetterMe.Notifier
  def notify(user, message), do: # Expo push implementation
end
```

### naming conventions
- `snake_case` for variables, functions, modules files
- `PascalCase` for module names (`BetterMe.Habits`)
- `?` suffix for predicates: `valid?/1`, `completed?/1`
- `!` suffix for raise-on-failure variants: `get_habit!/2` — only in LiveView assigns
- Function arity matters: `create/1` and `create/2` are distinct functions

---

## 10. UI components + Tailwind

### principle
Repeated UI patterns become function components. Raw HTML is written once.
`core_components.ex` holds low-level primitives (input, flash, icon).
`ui_components.ex` holds app-specific patterns (page_header, form_header, etc.).

### two component files — different responsibilities

```
lib/better_me_web/components/
  core_components.ex   # Phoenix primitives — input, select, textarea, flash, icon
  ui_components.ex     # App UI patterns — page_header, form_header, empty_state, etc.
```

`core_components.ex` is generated by Phoenix and should change rarely.
`ui_components.ex` is where app-specific components live. Both are auto-imported
everywhere via `better_me_web.ex`.

### rules
- **Function components for repeated UI** — if the same HTML block appears in 2+
  places, extract it. Use `attr` declarations to define the contract.
- **LiveComponents only for independent server state** — a form with its own
  changeset lifecycle is the canonical use case. Pure visual repetition never
  needs a LiveComponent.
- **`attr` declarations are required** — always declare attrs with types and
  defaults. Phoenix validates them at compile time and they serve as documentation.
- **`:key` on every `:for` loop** — LiveView uses it to track DOM nodes and
  avoid unnecessary re-renders. Always add `:key={item.id}`.
- **No inline conditionals beyond 2 branches** — extract to a private function.
  `priority_class/1` is the correct pattern. Keeps templates readable.
- **Labels belong in `<.input>`** — the `<.input>` component supports a `label`
  attr. Don't wrap it in a `<div>` with a separate `<label>` outside.
- **Don't mix daisyUI classes with plain Tailwind** — they override each other.
  This project uses plain Tailwind everywhere. Never use `input`, `btn`, `select`,
  `fieldset` daisyUI classes on form elements.

### function component structure
```elixir
# Always declare attrs before the function
attr :title,    :string, required: true
attr :new_path, :string, default: nil

def page_header(assigns) do
  ~H"""
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-bold text-gray-900">{@title}</h1>
    ...
  </div>
  """
end
```

### what lives in ui_components.ex (current)
| Component | Purpose |
|---|---|
| `<.page_container>` | `max-w-xl` wrapper on every page |
| `<.page_header>` | Title + "New" button used on list pages |
| `<.form_header>` | Back arrow + title used on form pages |
| `<.form_actions>` | Submit / Cancel / Delete button row |
| `<.empty_state>` | Centered message when a list is empty |
| `<.edit_link>` | Pencil icon link used in list rows |

### Tailwind mobile-first layout rules
- `max-w-xl mx-auto` on every page wrapper — constrains width so desktop
  looks like a phone layout (mobile-first personal app)
- `pb-20` on the main content area when logged in — leaves room for the fixed
  bottom nav bar
- Fixed bottom nav uses `fixed bottom-0 left-0 right-0 z-50` — always visible
- Don't use `container` from Tailwind — it adds breakpoint-specific max-widths
  that conflict with the single `max-w-xl` constraint

---

## summary — the checklist

Before merging any new module, verify:

- [ ] Schema is private to its context directory
- [ ] Context functions are scoped to user_id
- [ ] All functions return {:ok, _} | {:error, _} (no naked returns)
- [ ] No bare Repo calls outside a context module
- [ ] Queries filter/sort in SQL, not in Enum
- [ ] Foreign key indexes exist in the migration
- [ ] LiveView handle_event delegates to context within 5 lines
- [ ] At least one test for create, one for a failure case
- [ ] Repeated HTML extracted to ui_components.ex, not duplicated
- [ ] Every `:for` loop has `:key={item.id}`
- [ ] No daisyUI classes on form elements (input, btn, select, fieldset)
- [ ] `attr` declarations present on every function component
