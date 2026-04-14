defmodule BetterMeWeb.InsightsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Insights.InsightWorkflow
  alias BetterMeWeb.Plugs.RateLimit
  alias PlugAttack.Storage.Ets, as: PlugAttackEts

  # Max AI queries per user per day
  @daily_limit 20

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:ok,
     socket
     |> assign(:page_title, "Insights")
     |> assign(:messages, [])
     |> assign(:loading, false)
     |> assign(:question, "")
     |> assign(:queries_today, queries_today(user_id))
     |> assign(:daily_limit, @daily_limit)}
  end

  @impl true
  def handle_event("ask", %{"question" => question}, socket) do
    question = String.trim(question)
    user_id = socket.assigns.current_scope.user.id

    cond do
      question == "" ->
        {:noreply, socket}

      socket.assigns.queries_today >= @daily_limit ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Daily limit of #{@daily_limit} questions reached. Try again tomorrow."
         )}

      true ->
        messages = socket.assigns.messages ++ [%{role: :user, text: question}]
        send(self(), {:run_insight, user_id, question})

        {:noreply,
         socket
         |> assign(:messages, messages)
         |> assign(:loading, true)
         |> assign(:question, "")
         |> assign(:queries_today, socket.assigns.queries_today + 1)}
    end
  end

  @impl true
  def handle_info({:run_insight, user_id, question}, socket) do
    increment_queries(user_id)

    message =
      case InsightWorkflow.run(user_id, question) do
        {:ok, answer} -> %{role: :assistant, text: answer}
        {:error, reason} -> %{role: :error, text: inspect(reason)}
      end

    {:noreply,
     socket
     |> assign(:messages, socket.assigns.messages ++ [message])
     |> assign(:loading, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-6 flex flex-col h-[calc(100vh-8rem)]">
      <div class="flex items-center justify-between mb-4">
        <h1 class="text-xl font-bold text-gray-900">Insights</h1>
        <span class={[
          "text-xs font-medium px-2 py-1 rounded-full",
          @queries_today >= @daily_limit && "bg-red-100 text-red-600",
          @queries_today < @daily_limit && "bg-gray-100 text-gray-500"
        ]}>
          {@queries_today} / {@daily_limit} today
        </span>
      </div>

      <%!-- Message thread --%>
      <div id="messages" class="flex-1 overflow-y-auto space-y-4 mb-4">
        <div :if={@messages == []} class="text-center text-gray-400 text-sm mt-16">
          <p class="text-4xl mb-3">🤔</p>
          <p>Ask anything about your data.</p>
          <p class="mt-1">e.g. "Why was my energy low last week?"</p>
        </div>

        <div
          :for={{msg, i} <- Enum.with_index(@messages)}
          :key={i}
          id={"msg-#{i}"}
          class={[
            "rounded-2xl px-4 py-3 text-sm leading-relaxed max-w-[85%]",
            msg.role == :user && "ml-auto bg-teal-600 text-white",
            msg.role == :assistant && "bg-white border border-gray-200 text-gray-800 shadow-sm",
            msg.role == :error && "bg-red-50 border border-red-200 text-red-700"
          ]}
        >
          <span :if={msg.role == :error} class="font-medium">Error: </span>
          {msg.text}
        </div>

        <div :if={@loading} id="loading" class="flex items-center gap-2 text-gray-400 text-sm">
          <span class="animate-pulse">●</span>
          <span class="animate-pulse delay-75">●</span>
          <span class="animate-pulse delay-150">●</span>
        </div>
      </div>

      <%!-- Input --%>
      <form phx-submit="ask" class="flex gap-2">
        <input
          type="text"
          name="question"
          value={@question}
          placeholder="Ask about your habits, nutrition, workouts…"
          autocomplete="off"
          class="flex-1 rounded-full border border-gray-300 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
          disabled={@loading}
        />
        <button
          type="submit"
          disabled={@loading}
          class="rounded-full bg-teal-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-teal-700 disabled:opacity-50"
        >
          Ask
        </button>
      </form>
    </div>
    """
  end

  defp queries_today(user_id) do
    key = "insight:#{user_id}:#{Date.utc_today()}"
    period = 24 * 60 * 60 * 1_000

    case PlugAttackEts.increment(RateLimit.Storage, key, period, 0) do
      {count, _} -> max(count - 1, 0)
      _ -> 0
    end
  end

  defp increment_queries(user_id) do
    key = "insight:#{user_id}:#{Date.utc_today()}"
    period = 24 * 60 * 60 * 1_000
    PlugAttackEts.increment(RateLimit.Storage, key, period, 1)
  end
end
