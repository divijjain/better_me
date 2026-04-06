defmodule BetterMeWeb.IngredientsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  def mount(_params, _session, socket) do
    ingredients = Nutrition.list_ingredients()

    {:ok,
     assign(socket, ingredients: ingredients, query: "", open: MapSet.new())
     |> apply_filter("")}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="flex items-center justify-between mb-2">
        <h1 class="text-2xl font-bold text-gray-900">Nutrition</h1>
        <.link
          navigate={~p"/ingredients/new"}
          class="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> New
        </.link>
      </div>
      <.nutrition_tabs active={:ingredients} />

      <form phx-change="search" class="mb-4">
        <input
          type="text"
          name="query"
          value={@query}
          placeholder="Search ingredients…"
          phx-debounce="200"
          class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
        />
      </form>

      <.empty_state :if={@grouped == %{}} message="No ingredients yet. Add your first one!" />

      <div class="space-y-2">
        <div
          :for={{category, ingredients} <- Enum.sort_by(@grouped, fn {cat, _} -> to_string(cat) end)}
          :key={category}
        >
          <button
            phx-click="toggle"
            phx-value-category={category}
            class="w-full flex items-center justify-between rounded-xl border border-gray-200 bg-white px-4 py-3 shadow-sm hover:bg-gray-50 transition"
          >
            <div class="flex items-center gap-2">
              <span class="font-semibold text-gray-800 capitalize">{category}</span>
              <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-500">
                {length(ingredients)}
              </span>
            </div>
            <.icon
              name={
                if MapSet.member?(@open, category), do: "hero-chevron-up", else: "hero-chevron-down"
              }
              class="h-4 w-4 text-gray-400"
            />
          </button>

          <ul :if={MapSet.member?(@open, category)} class="mt-1 space-y-1 pl-1">
            <li
              :for={ingredient <- ingredients}
              :key={ingredient.id}
              class="flex items-center justify-between rounded-lg border border-gray-100 bg-white px-4 py-2.5 shadow-sm"
            >
              <div>
                <div class="flex items-center gap-2">
                  <p class="font-medium text-gray-900 text-sm">{ingredient.name}</p>
                  <span :if={ingredient.brand} class="text-xs text-gray-400">
                    ({ingredient.brand})
                  </span>
                  <span
                    :if={ingredient.is_vegetarian}
                    class="rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700"
                  >
                    veg
                  </span>
                  <span
                    :if={!ingredient.is_vegetarian}
                    class="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700"
                  >
                    non-veg
                  </span>
                </div>
                <div class="mt-1.5 flex flex-wrap gap-x-3 gap-y-1">
                  <span class="text-xs font-semibold text-gray-700">
                    {ingredient.calories_per_100g} kcal
                  </span>
                  <span class="text-xs text-rose-500">{ingredient.protein_per_100g}g protein</span>
                  <span class="text-xs text-amber-500">{ingredient.carbs_per_100g}g carbs</span>
                  <span class="text-xs text-emerald-500">{ingredient.fat_per_100g}g fat</span>
                  <span class="text-xs text-gray-400">{ingredient.fiber_per_100g}g fiber</span>
                  <span class="text-xs text-gray-400">{ingredient.sugar_per_100g}g sugar</span>
                  <span :if={ingredient.glycemic_index} class="text-xs text-purple-400">
                    GI {ingredient.glycemic_index}
                  </span>
                  <span :if={ingredient.sodium_mg_per_100g} class="text-xs text-gray-400">
                    {ingredient.sodium_mg_per_100g}mg sodium
                  </span>
                </div>
              </div>
              <.edit_link path={~p"/ingredients/#{ingredient.id}/edit"} />
            </li>
          </ul>
        </div>
      </div>
    </.page_container>
    """
  end

  def handle_event("toggle", %{"category" => category}, socket) do
    cat = String.to_existing_atom(category)
    open = socket.assigns.open

    open =
      if MapSet.member?(open, cat),
        do: MapSet.delete(open, cat),
        else: MapSet.put(open, cat)

    {:noreply, assign(socket, :open, open)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, socket |> assign(:query, query) |> apply_filter(query)}
  end

  defp apply_filter(socket, query) do
    filtered =
      if String.trim(query) == "" do
        socket.assigns.ingredients
      else
        q = String.downcase(query)

        Enum.filter(socket.assigns.ingredients, fn i ->
          String.contains?(String.downcase(i.name), q)
        end)
      end

    open =
      if String.trim(query) != "" do
        filtered |> Enum.map(& &1.category) |> MapSet.new()
      else
        socket.assigns.open
      end

    assign(socket, grouped: Enum.group_by(filtered, & &1.category), open: open)
  end
end
