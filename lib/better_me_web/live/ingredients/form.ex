defmodule BetterMeWeb.IngredientsLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  def mount(params, _session, socket) do
    {ingredient, action} = load_ingredient(params)
    changeset = Nutrition.change_ingredient(ingredient)

    {:ok,
     socket
     |> assign(action: action, ingredient: ingredient, categories: category_options())
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "New Ingredient", else: "Edit Ingredient"}
        back_path={~p"/ingredients"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
          <.input field={@form[:name]} type="text" placeholder="e.g. Chicken Breast" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Brand <span class="text-gray-400 font-normal">(optional)</span>
          </label>
          <.input field={@form[:brand]} type="text" placeholder="e.g. Warburtons" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
          <.input field={@form[:category]} type="select" options={@categories} class="w-full" />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Calories / 100g</label>
            <.input field={@form[:calories_per_100g]} type="number" step="0.1" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Protein / 100g</label>
            <.input field={@form[:protein_per_100g]} type="number" step="0.1" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Carbs / 100g</label>
            <.input field={@form[:carbs_per_100g]} type="number" step="0.1" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Fat / 100g</label>
            <.input field={@form[:fat_per_100g]} type="number" step="0.1" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Fiber / 100g</label>
            <.input field={@form[:fiber_per_100g]} type="number" step="0.1" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Sugar / 100g</label>
            <.input field={@form[:sugar_per_100g]} type="number" step="0.1" class="w-full" />
          </div>
        </div>

        <.form_actions action={@action} cancel_path={~p"/ingredients"} on_delete="delete" />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", %{"ingredient" => params}, socket) do
    changeset =
      socket.assigns.ingredient
      |> Nutrition.change_ingredient(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ingredient" => params}, socket) do
    case socket.assigns.action do
      :new -> create_ingredient(socket, params)
      :edit -> update_ingredient(socket, params)
    end
  end

  def handle_event("delete", _params, socket) do
    case Nutrition.delete_ingredient(socket.assigns.ingredient) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/ingredients")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete — ingredient is used in a recipe")}
    end
  end

  defp create_ingredient(socket, params) do
    case Nutrition.create_ingredient(params) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Ingredient created") |> push_navigate(to: ~p"/ingredients")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_ingredient(socket, params) do
    case Nutrition.update_ingredient(socket.assigns.ingredient, params) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Ingredient updated") |> push_navigate(to: ~p"/ingredients")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_ingredient(%{"id" => id}) do
    {Nutrition.get_ingredient!(id), :edit}
  end

  defp load_ingredient(_params) do
    {Nutrition.new_ingredient(), :new}
  end

  defp category_options do
    Nutrition.ingredient_categories()
    |> Enum.map(fn cat -> {cat |> to_string() |> String.capitalize(), cat} end)
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
