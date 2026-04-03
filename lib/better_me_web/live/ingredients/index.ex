defmodule BetterMeWeb.IngredientsLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  def mount(_params, _session, socket) do
    {:ok, assign(socket, ingredients: Nutrition.list_ingredients())}
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

      <.empty_state :if={@ingredients == []} message="No ingredients yet. Add your first one!" />

      <ul class="space-y-3">
        <li
          :for={ingredient <- @ingredients}
          :key={ingredient.id}
          class="flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm"
        >
          <div>
            <div class="flex items-center gap-2">
              <p class="font-medium text-gray-900">{ingredient.name}</p>
              <span :if={ingredient.brand} class="text-xs text-gray-400">({ingredient.brand})</span>
              <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-500 capitalize">
                {ingredient.category}
              </span>
            </div>
            <p class="text-xs text-gray-400 mt-0.5">
              {ingredient.calories_per_100g} kcal · {ingredient.protein_per_100g}g protein · {ingredient.carbs_per_100g}g carbs · {ingredient.fat_per_100g}g fat
            </p>
          </div>
          <.edit_link path={~p"/ingredients/#{ingredient.id}/edit"} />
        </li>
      </ul>
    </.page_container>
    """
  end
end
