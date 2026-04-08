defmodule BetterMeWeb.IngredientsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  @max_compare 4

  def mount(_params, _session, socket) do
    ingredients = Nutrition.list_ingredients()

    all_categories =
      ingredients |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort_by(&to_string/1)

    {:ok,
     assign(socket,
       ingredients: ingredients,
       all_categories: all_categories,
       query: "",
       veg_filter: :all,
       category_filter: nil,
       open: MapSet.new(),
       comparing: [],
       max_compare: @max_compare
     )
     |> apply_filter()}
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

      <form phx-change="search" class="mb-3">
        <input
          type="text"
          name="query"
          value={@query}
          placeholder="Search ingredients…"
          phx-debounce="200"
          class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
        />
      </form>

      <%!-- Filter bar --%>
      <div class="flex gap-2 overflow-x-auto pb-3 scrollbar-hide">
        <%!-- Veg toggle --%>
        <button
          phx-click="set_veg_filter"
          phx-value-filter="all"
          class={[
            "flex-shrink-0 rounded-full px-3 py-1 text-xs font-medium border transition",
            @veg_filter == :all && "bg-gray-800 text-white border-gray-800",
            @veg_filter != :all && "bg-white text-gray-600 border-gray-200 hover:border-gray-400"
          ]}
        >
          All
        </button>
        <button
          phx-click="set_veg_filter"
          phx-value-filter="veg"
          class={[
            "flex-shrink-0 rounded-full px-3 py-1 text-xs font-medium border transition",
            @veg_filter == :veg && "bg-green-600 text-white border-green-600",
            @veg_filter != :veg && "bg-white text-gray-600 border-gray-200 hover:border-gray-400"
          ]}
        >
          🌿 Veg
        </button>
        <button
          phx-click="set_veg_filter"
          phx-value-filter="non_veg"
          class={[
            "flex-shrink-0 rounded-full px-3 py-1 text-xs font-medium border transition",
            @veg_filter == :non_veg && "bg-red-600 text-white border-red-600",
            @veg_filter != :non_veg && "bg-white text-gray-600 border-gray-200 hover:border-gray-400"
          ]}
        >
          🍗 Non-veg
        </button>

        <%!-- Divider --%>
        <div class="flex-shrink-0 w-px bg-gray-200 mx-1" />

        <%!-- Category pills --%>
        <button
          :for={cat <- @all_categories}
          :key={cat}
          phx-click="set_category_filter"
          phx-value-category={cat}
          class={[
            "flex-shrink-0 rounded-full px-3 py-1 text-xs font-medium border capitalize transition",
            @category_filter == cat && "bg-indigo-600 text-white border-indigo-600",
            @category_filter != cat && "bg-white text-gray-600 border-gray-200 hover:border-gray-400"
          ]}
        >
          {cat}
        </button>
      </div>

      <.empty_state :if={@grouped == %{}} message="No ingredients match the current filters." />

      <div class={["space-y-2", @comparing != [] && "pb-64"]}>
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
              class={[
                "flex items-center justify-between rounded-lg border bg-white px-4 py-2.5 shadow-sm",
                comparing?(ingredient, @comparing) && "border-indigo-300 bg-indigo-50",
                !comparing?(ingredient, @comparing) && "border-gray-100"
              ]}
            >
              <div class="flex items-start gap-3 flex-1 min-w-0">
                <input
                  type="checkbox"
                  checked={comparing?(ingredient, @comparing)}
                  disabled={!comparing?(ingredient, @comparing) && length(@comparing) >= @max_compare}
                  phx-click="toggle_compare"
                  phx-value-id={ingredient.id}
                  class="mt-1 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 disabled:opacity-40 cursor-pointer disabled:cursor-not-allowed flex-shrink-0"
                />
                <div class="min-w-0">
                  <div class="flex items-center gap-2 flex-wrap">
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
                  <div class="mt-1.5">
                    <p class="text-xs text-gray-400 mb-1">per 100g</p>
                    <div class="flex flex-wrap gap-x-3 gap-y-1">
                      <span class="text-xs font-semibold text-gray-700">
                        {ingredient.calories_per_100g} kcal
                      </span>
                      <span class="text-xs text-rose-500">
                        Protein {ingredient.protein_per_100g}g
                      </span>
                      <span class="text-xs text-amber-500">
                        Carbs {ingredient.carbs_per_100g}g
                      </span>
                      <span class="text-xs text-emerald-500">
                        Fat {ingredient.fat_per_100g}g
                      </span>
                      <span class="text-xs text-gray-400">
                        Fiber {ingredient.fiber_per_100g}g
                      </span>
                      <span class="text-xs text-pink-400">
                        Sugar {ingredient.sugar_per_100g}g
                      </span>
                      <span :if={ingredient.glycemic_index} class="text-xs text-purple-400">
                        GI {ingredient.glycemic_index}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              <.edit_link path={~p"/ingredients/#{ingredient.id}/edit"} />
            </li>
          </ul>
        </div>
      </div>
    </.page_container>

    <%!-- Comparison panel — outside page_container so fixed positioning works --%>
    <div
      :if={@comparing != []}
      class="fixed left-0 right-0 z-[60] bg-white border-t-2 border-indigo-100 shadow-2xl"
      style="bottom: 56px;"
    >
      <div class="max-w-2xl mx-auto px-4 pt-3 pb-4">
        <%!-- Header --%>
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-2">
            <.icon name="hero-scale" class="h-4 w-4 text-indigo-500" />
            <span class="text-sm font-semibold text-gray-800">Compare</span>
            <span class="rounded-full bg-indigo-100 px-2 py-0.5 text-xs font-medium text-indigo-600">
              {length(@comparing)} / {@max_compare}
            </span>
          </div>
          <button
            phx-click="clear_compare"
            class="text-xs text-gray-400 hover:text-red-500 transition flex items-center gap-1"
          >
            <.icon name="hero-x-mark" class="h-3 w-3" /> Clear all
          </button>
        </div>

        <%!-- Cards row --%>
        <div class="flex gap-3 overflow-x-auto">
          <.compare_card :for={ing <- @comparing} ingredient={ing} comparing={@comparing} />
        </div>

        <%!-- Legend --%>
        <p class="text-xs text-gray-400 mt-3 text-center">
          Bar width shows relative value among selected.
          <span class="text-indigo-500 font-medium">Indigo</span>
          = best for that nutrient.
        </p>
      </div>
    </div>
    """
  end

  attr :ingredient, :map, required: true
  attr :comparing, :list, required: true

  defp compare_card(assigns) do
    ing = assigns.ingredient
    all = assigns.comparing

    macros = [
      %{
        label: "Calories",
        field: :calories_per_100g,
        unit: "kcal",
        color: "bg-orange-400",
        goal: :low
      },
      %{label: "Protein", field: :protein_per_100g, unit: "g", color: "bg-rose-400", goal: :high},
      %{label: "Carbs", field: :carbs_per_100g, unit: "g", color: "bg-amber-400", goal: :low},
      %{label: "Fat", field: :fat_per_100g, unit: "g", color: "bg-emerald-400", goal: :low},
      %{label: "Fiber", field: :fiber_per_100g, unit: "g", color: "bg-blue-400", goal: :high},
      %{label: "Sugar", field: :sugar_per_100g, unit: "g", color: "bg-pink-400", goal: :low},
      %{label: "GI", field: :glycemic_index, unit: "", color: "bg-purple-400", goal: :low}
    ]

    rows =
      Enum.map(macros, fn m ->
        raw = Map.get(ing, m.field)
        val = raw || 0
        all_vals = Enum.map(all, &(Map.get(&1, m.field) || 0))
        max_val = Enum.max(all_vals, fn -> 1 end)
        pct = if max_val > 0, do: round(val / max_val * 100), else: 0

        best_val = best_val(all_vals, m.goal)

        is_best = val == best_val and length(all) > 1 and Enum.any?(all_vals, &(&1 > 0))
        display = if is_nil(raw), do: "—", else: "#{val}#{m.unit}"
        Map.merge(m, %{val: val, pct: pct, is_best: is_best, display: display})
      end)

    assigns = assign(assigns, ing: ing, rows: rows)

    ~H"""
    <div class="flex-shrink-0 w-44 rounded-xl border border-gray-200 bg-gray-50 p-3 relative">
      <%!-- Remove button --%>
      <button
        phx-click="toggle_compare"
        phx-value-id={@ing.id}
        class="absolute top-2 right-2 text-gray-300 hover:text-gray-600"
      >
        <.icon name="hero-x-mark" class="h-3.5 w-3.5" />
      </button>

      <%!-- Name --%>
      <p class="text-xs font-bold text-gray-800 pr-4 mb-0.5 leading-tight">{@ing.name}</p>
      <span
        :if={@ing.is_vegetarian}
        class="inline-block rounded-full bg-green-100 px-1.5 py-0.5 text-xs font-medium text-green-700 mb-2"
      >
        veg
      </span>
      <span
        :if={!@ing.is_vegetarian}
        class="inline-block rounded-full bg-red-100 px-1.5 py-0.5 text-xs font-medium text-red-700 mb-2"
      >
        non-veg
      </span>

      <%!-- Macro bars --%>
      <div class="space-y-2 mt-1">
        <div :for={row <- @rows} :key={row.label}>
          <div class="flex justify-between items-center mb-0.5">
            <span class={[
              "text-xs font-medium",
              row.is_best && "text-indigo-600",
              !row.is_best && "text-gray-500"
            ]}>
              {row.label}
            </span>
            <span class={[
              "text-xs font-semibold",
              row.is_best && "text-indigo-600",
              !row.is_best && "text-gray-700"
            ]}>
              {row.display}
            </span>
          </div>
          <div class="h-1.5 w-full rounded-full bg-gray-200 overflow-hidden">
            <div
              class={[
                "h-full rounded-full transition-all",
                row.is_best && "bg-indigo-500",
                !row.is_best && row.color
              ]}
              style={"width: #{row.pct}%"}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp best_val(vals, :high), do: Enum.max(vals, fn -> nil end)
  defp best_val(vals, :low), do: Enum.min(vals, fn -> nil end)

  defp comparing?(ingredient, comparing) do
    Enum.any?(comparing, &(&1.id == ingredient.id))
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
    {:noreply, socket |> assign(:query, query) |> apply_filter()}
  end

  def handle_event("set_veg_filter", %{"filter" => filter}, socket) do
    veg_filter = String.to_existing_atom(filter)
    {:noreply, socket |> assign(:veg_filter, veg_filter) |> apply_filter()}
  end

  def handle_event("set_category_filter", %{"category" => cat}, socket) do
    current = socket.assigns.category_filter
    category = String.to_existing_atom(cat)
    # tap again to deselect
    new_filter = if current == category, do: nil, else: category
    {:noreply, socket |> assign(:category_filter, new_filter) |> apply_filter()}
  end

  def handle_event("toggle_compare", %{"id" => id}, socket) do
    id = String.to_integer(id)
    comparing = socket.assigns.comparing

    comparing =
      if Enum.any?(comparing, &(&1.id == id)) do
        Enum.reject(comparing, &(&1.id == id))
      else
        if length(comparing) < @max_compare do
          ingredient = Enum.find(socket.assigns.ingredients, &(&1.id == id))
          comparing ++ [ingredient]
        else
          comparing
        end
      end

    {:noreply, assign(socket, :comparing, comparing)}
  end

  def handle_event("clear_compare", _params, socket) do
    {:noreply, assign(socket, :comparing, [])}
  end

  defp apply_filter(socket) do
    query = socket.assigns.query
    veg_filter = socket.assigns.veg_filter
    category_filter = socket.assigns.category_filter

    filtered =
      socket.assigns.ingredients
      |> filter_by_query(query)
      |> filter_by_veg(veg_filter)
      |> filter_by_category(category_filter)

    auto_open = String.trim(query) != "" or category_filter != nil

    open =
      if auto_open,
        do: filtered |> Enum.map(& &1.category) |> MapSet.new(),
        else: socket.assigns.open

    assign(socket, grouped: Enum.group_by(filtered, & &1.category), open: open)
  end

  defp filter_by_query(ingredients, query) do
    if String.trim(query) == "" do
      ingredients
    else
      q = String.downcase(query)
      Enum.filter(ingredients, &String.contains?(String.downcase(&1.name), q))
    end
  end

  defp filter_by_veg(ingredients, :veg), do: Enum.filter(ingredients, & &1.is_vegetarian)
  defp filter_by_veg(ingredients, :non_veg), do: Enum.filter(ingredients, &(!&1.is_vegetarian))
  defp filter_by_veg(ingredients, :all), do: ingredients

  defp filter_by_category(ingredients, nil), do: ingredients
  defp filter_by_category(ingredients, cat), do: Enum.filter(ingredients, &(&1.category == cat))
end
