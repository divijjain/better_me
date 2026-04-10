defmodule BetterMeWeb.JournalLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Journals

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {entry, action} = load_entry(params, user_id)
    changeset = Journals.change_entry(entry)

    {:ok,
     socket
     |> assign(
       action: action,
       entry: entry,
       user_id: user_id,
       tags_input: tags_to_string(entry.tags)
     )
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "New Entry", else: "Edit Entry"}
        back_path={~p"/journal"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
          <.input field={@form[:date]} type="date" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Mood <span class="text-gray-400 font-normal">(optional)</span>
          </label>
          <% current_mood = to_string(Phoenix.HTML.Form.input_value(@form, :mood)) %>
          <div class="flex gap-3">
            <label
              :for={mood <- [1, 2, 3, 4, 5]}
              :key={mood}
              class={[
                "flex flex-1 cursor-pointer items-center justify-center rounded-lg border py-2 text-xl transition",
                if(to_string(mood) == current_mood,
                  do: "border-indigo-400 bg-indigo-50",
                  else: "border-gray-200 bg-white hover:bg-gray-50"
                )
              ]}
            >
              <input
                type="radio"
                name="journal_entry[mood]"
                value={mood}
                checked={to_string(mood) == current_mood}
                class="sr-only"
              />
              {mood_emoji(mood)}
            </label>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Entry</label>
          <.input
            field={@form[:body]}
            type="textarea"
            placeholder="How was your day? What's on your mind?"
            rows="6"
            class="w-full"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Tags <span class="text-gray-400 font-normal">(optional, comma-separated)</span>
          </label>
          <input
            type="text"
            name="tags_input"
            value={@tags_input}
            placeholder="e.g. gym, focus, sleep"
            phx-debounce="300"
            class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <.form_actions action={@action} cancel_path={~p"/journal"} on_delete="delete" />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", params, socket) do
    entry_params = build_params(params)

    changeset =
      socket.assigns.entry
      |> Journals.change_entry(entry_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:tags_input, params["tags_input"] || "")
     |> assign_form(changeset)}
  end

  def handle_event("save", params, socket) do
    entry_params = build_params(params)

    case socket.assigns.action do
      :new -> create_entry(socket, entry_params)
      :edit -> update_entry(socket, entry_params)
    end
  end

  def handle_event("delete", _params, socket) do
    case Journals.delete_entry(socket.assigns.entry) do
      {:ok, _} -> {:noreply, push_navigate(socket, to: ~p"/journal")}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not delete entry")}
    end
  end

  defp create_entry(socket, params) do
    case Journals.create_entry(socket.assigns.user_id, params) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Entry saved") |> push_navigate(to: ~p"/journal")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_entry(socket, params) do
    case Journals.update_entry(socket.assigns.entry, params) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Entry updated") |> push_navigate(to: ~p"/journal")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_entry(%{"id" => id}, user_id), do: {Journals.get_entry!(id, user_id), :edit}
  defp load_entry(_params, _user_id), do: {Journals.new_entry(), :new}

  defp build_params(params) do
    tags =
      (params["tags_input"] || "")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    entry_params = params["journal_entry"] || %{}
    Map.put(entry_params, "tags", tags)
  end

  defp tags_to_string([]), do: ""
  defp tags_to_string(tags), do: Enum.join(tags, ", ")

  defp mood_emoji(1), do: "😞"
  defp mood_emoji(2), do: "😕"
  defp mood_emoji(3), do: "😐"
  defp mood_emoji(4), do: "🙂"
  defp mood_emoji(5), do: "😄"

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
end
