defmodule BetterMeWeb.RecipesLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {recipe, action} = load_recipe(params, user_id)
    changeset = Nutrition.change_recipe(recipe)

    {:ok,
     socket
     |> assign(action: action, recipe: recipe, user_id: user_id)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "New Recipe", else: "Edit Recipe"}
        back_path={~p"/recipes"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
          <.input field={@form[:title]} type="text" placeholder="e.g. Chicken Salad" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Tags <span class="text-gray-400 font-normal">(comma separated)</span>
          </label>
          <input
            type="text"
            name="tags_input"
            value={Enum.join(@form[:tags].value || [], ", ")}
            placeholder="e.g. lunch, high-protein"
            class="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <.form_actions action={@action} cancel_path={~p"/recipes"} on_delete="delete" />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", all_params, socket) do
    params = build_params(all_params)

    changeset =
      socket.assigns.recipe
      |> Nutrition.change_recipe(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", all_params, socket) do
    params = build_params(all_params)

    case socket.assigns.action do
      :new -> create_recipe(socket, params)
      :edit -> update_recipe(socket, params)
    end
  end

  def handle_event("delete", _params, socket) do
    case Nutrition.delete_recipe(socket.assigns.recipe) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/recipes")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete recipe")}
    end
  end

  defp build_params(all_params) do
    tags =
      all_params
      |> Map.get("tags_input", "")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    recipe_params = Map.get(all_params, "recipe", %{})
    Map.put(recipe_params, "tags", tags)
  end

  defp create_recipe(socket, params) do
    case Nutrition.create_recipe(socket.assigns.user_id, params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe created")
         |> push_navigate(to: ~p"/recipes/#{recipe.id}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_recipe(socket, params) do
    case Nutrition.update_recipe(socket.assigns.recipe, params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated")
         |> push_navigate(to: ~p"/recipes/#{recipe.id}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_recipe(%{"id" => id}, user_id) do
    {Nutrition.get_recipe!(id, user_id), :edit}
  end

  defp load_recipe(_params, _user_id) do
    {Nutrition.new_recipe(), :new}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
