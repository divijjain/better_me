defmodule BetterMeWeb.InsightsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Insights.InsightWorkflow

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Insights")
     |> assign(:messages, [])
     |> assign(:loading, false)
     |> assign(:question, "")}
  end

  @impl true
  def handle_event("ask", %{"question" => question}, socket) do
    question = String.trim(question)

    if question == "" do
      {:noreply, socket}
    else
      user_id = socket.assigns.current_scope.user.id

      messages = socket.assigns.messages ++ [%{role: :user, text: question}]

      send(self(), {:run_insight, user_id, question})

      {:noreply,
       socket
       |> assign(:messages, messages)
       |> assign(:loading, true)
       |> assign(:question, "")}
    end
  end

  @impl true
  def handle_info({:run_insight, user_id, question}, socket) do
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
      <h1 class="text-xl font-bold text-gray-900 mb-4">Insights</h1>

      <%!-- Message thread --%>
      <div
        id="messages"
        class="flex-1 overflow-y-auto space-y-4 mb-4"
      >
        <%= if @messages == [] do %>
          <div class="text-center text-gray-400 text-sm mt-16">
            <p class="text-4xl mb-3">🤔</p>
            <p>Ask anything about your data.</p>
            <p class="mt-1">e.g. "Why was my energy low last week?"</p>
          </div>
        <% end %>

        <%= for {msg, i} <- Enum.with_index(@messages) do %>
          <div
            id={"msg-#{i}"}
            class={[
              "rounded-2xl px-4 py-3 text-sm leading-relaxed max-w-[85%]",
              msg.role == :user && "ml-auto bg-indigo-600 text-white",
              msg.role == :assistant && "bg-white border border-gray-200 text-gray-800 shadow-sm",
              msg.role == :error && "bg-red-50 border border-red-200 text-red-700"
            ]}
          >
            <%= if msg.role == :error do %>
              <span class="font-medium">Error: </span>
            <% end %>
            {msg.text}
          </div>
        <% end %>

        <%= if @loading do %>
          <div id="loading" class="flex items-center gap-2 text-gray-400 text-sm">
            <span class="animate-pulse">●</span>
            <span class="animate-pulse delay-75">●</span>
            <span class="animate-pulse delay-150">●</span>
          </div>
        <% end %>
      </div>

      <%!-- Input --%>
      <form phx-submit="ask" class="flex gap-2">
        <input
          type="text"
          name="question"
          value={@question}
          placeholder="Ask about your habits, nutrition, workouts…"
          autocomplete="off"
          class="flex-1 rounded-full border border-gray-300 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          disabled={@loading}
        />
        <button
          type="submit"
          disabled={@loading}
          class="rounded-full bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
        >
          Ask
        </button>
      </form>
    </div>
    """
  end
end
