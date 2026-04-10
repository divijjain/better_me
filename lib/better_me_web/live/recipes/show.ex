defmodule BetterMeWeb.RecipesLive.Show do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition
  alias BetterMe.Nutrition.Macros

  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    recipe = Nutrition.get_recipe!(id, user_id)
    macros = Macros.for_recipe(recipe.recipe_ingredients)

    {:ok,
     socket
     |> assign(recipe: recipe, macros: macros, user_id: user_id)
     |> assign(grouped_ingredients: grouped_ingredients())}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="mb-6 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <.link navigate={~p"/recipes"} class="text-gray-400 hover:text-gray-600">
            <.icon name="hero-arrow-left" class="h-5 w-5" />
          </.link>
          <h1 class="text-2xl font-bold text-gray-900">{@recipe.title}</h1>
        </div>
        <.edit_link path={~p"/recipes/#{@recipe.id}/edit"} />
      </div>

      <%!-- Tags --%>
      <div :if={@recipe.tags != []} class="mb-4 flex flex-wrap gap-2">
        <span
          :for={tag <- @recipe.tags}
          :key={tag}
          class="rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-600"
        >
          {tag}
        </span>
      </div>

      <%!-- Macro summary --%>
      <div class="mb-6">
        <.macro_grid
          calories={@macros.calories}
          protein={@macros.protein}
          carbs={@macros.carbs}
          fat={@macros.fat}
        />
      </div>

      <%!-- Ingredients list --%>
      <h2 class="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">Ingredients</h2>

      <.empty_state
        :if={@recipe.recipe_ingredients == []}
        message="No ingredients yet. Add one below."
      />

      <ul class="mb-6 space-y-2">
        <li
          :for={ri <- @recipe.recipe_ingredients}
          :key={ri.id}
          class="flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-2 shadow-sm"
        >
          <div>
            <span class="font-medium text-gray-900">{ri.ingredient.name}</span>
            <span class="ml-2 text-sm text-gray-400">{ri.quantity_grams}g</span>
          </div>
          <button
            phx-click="remove_ingredient"
            phx-value-id={ri.id}
            class="text-gray-300 hover:text-red-400"
            data-confirm="Remove this ingredient?"
          >
            <.icon name="hero-x-mark" class="h-4 w-4" />
          </button>
        </li>
      </ul>

      <%!-- Add ingredient form --%>
      <div class="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
        <h3 class="mb-3 text-sm font-semibold text-gray-700">Add Ingredient</h3>
        <form phx-submit="add_ingredient" class="flex items-end gap-2">
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-600 mb-1">Ingredient</label>
            <select
              name="ingredient_id"
              class="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            >
              <option value="">Select…</option>
              <optgroup
                :for={{category, ingredients} <- @grouped_ingredients}
                :key={category}
                label={category |> to_string() |> String.capitalize()}
              >
                <option :for={ing <- ingredients} :key={ing.id} value={ing.id}>
                  {if ing.brand, do: "#{ing.name} (#{ing.brand})", else: ing.name}
                </option>
              </optgroup>
            </select>
          </div>
          <div class="w-24">
            <label class="block text-xs font-medium text-gray-600 mb-1">Grams</label>
            <input
              type="number"
              name="quantity_grams"
              min="0.1"
              step="0.1"
              placeholder="100"
              class="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>
          <button
            type="submit"
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
          >
            Add
          </button>
        </form>
      </div>
    </.page_container>
    """
  end

  def handle_event("add_ingredient", %{"ingredient_id" => "", "quantity_grams" => _}, socket) do
    {:noreply, put_flash(socket, :error, "Please select an ingredient")}
  end

  def handle_event(
        "add_ingredient",
        %{"ingredient_id" => ing_id, "quantity_grams" => qty},
        socket
      ) do
    {quantity, _} = Float.parse(qty)

    attrs = %{
      recipe_id: socket.assigns.recipe.id,
      ingredient_id: String.to_integer(ing_id),
      quantity_grams: quantity
    }

    case Nutrition.add_recipe_ingredient(attrs) do
      {:ok, _} -> {:noreply, reload(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not add ingredient")}
    end
  end

  def handle_event("remove_ingredient", %{"id" => id}, socket) do
    with {:ok, ri} <- Nutrition.get_recipe_ingredient(id),
         {:ok, _} <- Nutrition.remove_recipe_ingredient(ri) do
      {:noreply, reload(socket)}
    else
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not remove ingredient")}
    end
  end

  defp reload(socket) do
    recipe = Nutrition.get_recipe!(socket.assigns.recipe.id, socket.assigns.user_id)
    macros = Macros.for_recipe(recipe.recipe_ingredients)
    assign(socket, recipe: recipe, macros: macros)
  end

  defp grouped_ingredients do
    Nutrition.list_ingredients()
    |> Enum.group_by(& &1.category)
  end
end
