defmodule BetterMeWeb.NutritionLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Nutrition

  @meal_type_labels %{
    breakfast: "Breakfast",
    lunch: "Lunch",
    dinner: "Dinner",
    snack: "Snack"
  }

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    today = Date.utc_today()

    {:ok,
     socket
     |> assign(user_id: user_id, date: today, show_log_form: false)
     |> assign(recipes: Nutrition.list_recipes(user_id))
     |> load_summary(user_id, today)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <%!-- Header + date nav --%>
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Nutrition</h1>
        <div class="flex items-center gap-2">
          <button phx-click="prev_day" class="text-gray-400 hover:text-gray-600 p-1">
            <.icon name="hero-chevron-left" class="h-5 w-5" />
          </button>
          <span class="text-sm font-medium text-gray-700 w-24 text-center">
            {format_date(@date)}
          </span>
          <button
            phx-click="next_day"
            disabled={@date == Date.utc_today()}
            class="text-gray-400 hover:text-gray-600 p-1 disabled:opacity-30"
          >
            <.icon name="hero-chevron-right" class="h-5 w-5" />
          </button>
        </div>
      </div>

      <%!-- Daily macro totals --%>
      <div class="mb-6 grid grid-cols-4 gap-2 rounded-xl border border-gray-200 bg-white p-4 shadow-sm text-center">
        <div>
          <p class="text-lg font-bold text-gray-900">{round(@summary.totals.calories)}</p>
          <p class="text-xs text-gray-400">kcal</p>
        </div>
        <div>
          <p class="text-lg font-bold text-gray-900">{Float.round(@summary.totals.protein, 1)}g</p>
          <p class="text-xs text-gray-400">protein</p>
        </div>
        <div>
          <p class="text-lg font-bold text-gray-900">{Float.round(@summary.totals.carbs, 1)}g</p>
          <p class="text-xs text-gray-400">carbs</p>
        </div>
        <div>
          <p class="text-lg font-bold text-gray-900">{Float.round(@summary.totals.fat, 1)}g</p>
          <p class="text-xs text-gray-400">fat</p>
        </div>
      </div>

      <%!-- Meals by type --%>
      <div class="space-y-4 mb-6">
        <div :for={meal_type <- Nutrition.meal_type_order()} :key={meal_type}>
          <div class="flex items-center justify-between mb-2">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-gray-500">
              {meal_type_label(meal_type)}
            </h2>
            <span
              :if={@summary.meals_by_type[meal_type] != []}
              class="text-xs text-gray-400"
            >
              {meal_type_calories(@summary.meals_by_type[meal_type])} kcal
            </span>
          </div>

          <.empty_state
            :if={@summary.meals_by_type[meal_type] == []}
            message="Nothing logged"
          />

          <ul class="space-y-2">
            <li
              :for={log <- @summary.meals_by_type[meal_type]}
              :key={log.id}
              class="flex items-center justify-between rounded-lg border border-gray-200 bg-white px-4 py-2.5 shadow-sm"
            >
              <div>
                <p class="font-medium text-gray-900 text-sm">{log.recipe.title}</p>
                <p class="text-xs text-gray-400">
                  {log.servings}x · {round(log.macros.calories)} kcal · {Float.round(
                    log.macros.protein,
                    1
                  )}g protein
                </p>
              </div>
              <button
                phx-click="delete_log"
                phx-value-id={log.id}
                class="text-gray-300 hover:text-red-400 ml-3"
                data-confirm="Remove this meal log?"
              >
                <.icon name="hero-x-mark" class="h-4 w-4" />
              </button>
            </li>
          </ul>
        </div>
      </div>

      <%!-- Log meal button --%>
      <button
        :if={!@show_log_form}
        phx-click="show_log_form"
        class="w-full rounded-xl border-2 border-dashed border-indigo-300 py-3 text-sm font-medium text-indigo-500 hover:border-indigo-400 hover:text-indigo-600 transition"
      >
        + Log a meal
      </button>

      <%!-- Log meal form --%>
      <div :if={@show_log_form} class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
        <h3 class="mb-4 text-sm font-semibold text-gray-700">Log a Meal</h3>

        <form phx-submit="log_meal" class="space-y-3">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Recipe</label>
            <select
              name="recipe_id"
              class="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            >
              <option value="">Select recipe…</option>
              <option :for={recipe <- @recipes} :key={recipe.id} value={recipe.id}>
                {recipe.title}
              </option>
            </select>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Meal type</label>
              <select
                name="meal_type"
                class="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              >
                <option :for={type <- Nutrition.meal_type_order()} :key={type} value={type}>
                  {meal_type_label(type)}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Servings</label>
              <input
                type="number"
                name="servings"
                value="1"
                min="0.1"
                step="0.1"
                class="block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              />
            </div>
          </div>

          <div class="flex gap-2 pt-1">
            <button
              type="submit"
              class="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
            >
              Log
            </button>
            <button
              type="button"
              phx-click="hide_log_form"
              class="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </.page_container>
    """
  end

  def handle_event("prev_day", _params, socket) do
    new_date = Date.add(socket.assigns.date, -1)
    {:noreply, reload(socket, new_date)}
  end

  def handle_event("next_day", _params, socket) do
    new_date = Date.add(socket.assigns.date, 1)

    if Date.compare(new_date, Date.utc_today()) == :gt do
      {:noreply, socket}
    else
      {:noreply, reload(socket, new_date)}
    end
  end

  def handle_event("show_log_form", _params, socket) do
    {:noreply, assign(socket, :show_log_form, true)}
  end

  def handle_event("hide_log_form", _params, socket) do
    {:noreply, assign(socket, :show_log_form, false)}
  end

  def handle_event("log_meal", %{"recipe_id" => ""}, socket) do
    {:noreply, put_flash(socket, :error, "Please select a recipe")}
  end

  def handle_event("log_meal", params, socket) do
    {servings, _} = Float.parse(params["servings"] || "1")

    attrs = %{
      recipe_id: String.to_integer(params["recipe_id"]),
      meal_type: params["meal_type"],
      servings: servings,
      date: socket.assigns.date
    }

    case Nutrition.log_meal_for_user(socket.assigns.user_id, attrs) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:show_log_form, false)
         |> reload(socket.assigns.date)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not log meal")}
    end
  end

  def handle_event("delete_log", %{"id" => id}, socket) do
    with {:ok, log} <- Nutrition.get_meal_log(id, socket.assigns.user_id),
         {:ok, _} <- Nutrition.delete_meal_log(log) do
      {:noreply, reload(socket, socket.assigns.date)}
    else
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not remove meal")}
    end
  end

  defp reload(socket, date) do
    socket
    |> assign(:date, date)
    |> load_summary(socket.assigns.user_id, date)
  end

  defp load_summary(socket, user_id, date) do
    assign(socket, :summary, Nutrition.daily_summary(user_id, date))
  end

  defp format_date(date) do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)

    case date do
      ^today -> "Today"
      ^yesterday -> "Yesterday"
      _ -> Calendar.strftime(date, "%b %d")
    end
  end

  defp meal_type_label(type), do: Map.fetch!(@meal_type_labels, type)

  defp meal_type_calories(logs) do
    logs
    |> Enum.reduce(0.0, fn log, acc -> acc + log.macros.calories end)
    |> round()
  end
end
