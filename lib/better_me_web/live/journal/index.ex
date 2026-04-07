defmodule BetterMeWeb.JournalLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Journals

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    entries = Journals.list_entries(user_id)
    {:ok, assign(socket, entries: entries, user_id: user_id)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Journal" new_path={~p"/journal/new"} new_label="Write" />

      <.empty_state :if={@entries == []} message="No entries yet. Write your first one!" />

      <ul class="space-y-3">
        <li
          :for={entry <- @entries}
          :key={entry.id}
          class="rounded-xl border border-gray-200 bg-white px-4 py-3 shadow-sm"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <p class="text-sm font-semibold text-gray-900">
                  {Calendar.strftime(entry.date, "%b %-d, %Y")}
                </p>
                <span :if={entry.mood} class="text-base leading-none">
                  {mood_emoji(entry.mood)}
                </span>
              </div>
              <p class="text-sm text-gray-600 line-clamp-2">{entry.body}</p>
              <div :if={entry.tags != []} class="mt-2 flex flex-wrap gap-1">
                <span
                  :for={tag <- entry.tags}
                  class="rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-600"
                >
                  #{tag}
                </span>
              </div>
            </div>
            <.edit_link path={~p"/journal/#{entry.id}/edit"} />
          </div>
        </li>
      </ul>
    </.page_container>
    """
  end

  defp mood_emoji(1), do: "😞"
  defp mood_emoji(2), do: "😕"
  defp mood_emoji(3), do: "😐"
  defp mood_emoji(4), do: "🙂"
  defp mood_emoji(5), do: "😄"
  defp mood_emoji(_), do: ""
end
