defmodule BetterMeWeb.RecipesLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, assign(socket, recipes: Nutrition.list_recipes(user_id))}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="flex items-center justify-between mb-2">
        <h1 class="text-2xl font-bold text-gray-900">Nutrition</h1>
        <.link
          navigate={~p"/recipes/new"}
          class="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> New
        </.link>
      </div>
      <.nutrition_tabs active={:recipes} />

      <.empty_state :if={@recipes == []} message="No recipes yet. Add your first one!" />

      <ul class="space-y-3">
        <li
          :for={recipe <- @recipes}
          :key={recipe.id}
          class="relative flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-sm hover:bg-gray-50 transition"
        >
          <.link navigate={~p"/recipes/#{recipe.id}"} class="absolute inset-0"></.link>
          <div class="pointer-events-none">
            <p class="font-medium text-gray-900">{recipe.title}</p>
            <p :if={recipe.tags != []} class="text-xs text-gray-400">
              {Enum.join(recipe.tags, " · ")}
            </p>
          </div>
          <.edit_link path={~p"/recipes/#{recipe.id}/edit"} />
        </li>
      </ul>
    </.page_container>
    """
  end
end
