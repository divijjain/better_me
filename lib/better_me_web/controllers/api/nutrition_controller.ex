defmodule BetterMeWeb.Api.NutritionController do
  @moduledoc "JSON API for nutrition — daily summary, meal logging, recipes list."

  use BetterMeWeb, :controller
  alias BetterMe.{Nutrition, Profiles}

  def daily_summary(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    date = parse_date(params["date"])
    summary = Nutrition.daily_summary(user_id, date)
    targets = load_targets(user_id)

    json(conn, %{
      data: %{
        date: date,
        totals: summary.totals,
        meals_by_type: serialize_meals_by_type(summary.meals_by_type),
        targets: targets
      }
    })
  end

  def recipes(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    recipes = Nutrition.list_recipes(user_id)
    json(conn, %{data: Enum.map(recipes, &serialize_recipe/1)})
  end

  def log_meal(conn, %{"meal" => attrs}) do
    user_id = conn.assigns.current_scope.user.id

    parsed_attrs =
      attrs
      |> Map.update("recipe_id", nil, &parse_int/1)
      |> Map.update("servings", 1.0, &parse_float/1)
      |> Map.put_new("date", Date.utc_today())
      |> Map.update("date", Date.utc_today(), &parse_date/1)

    case Nutrition.log_meal_for_user(user_id, parsed_attrs) do
      {:ok, _log} ->
        summary = Nutrition.daily_summary(user_id, parsed_attrs["date"])
        json(conn, %{data: serialize_meals_by_type(summary.meals_by_type)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def delete_meal(conn, %{"id" => id}) do
    user_id = conn.assigns.current_scope.user.id

    with {:ok, log} <- Nutrition.get_meal_log(id, user_id),
         {:ok, _} <- Nutrition.delete_meal_log(log) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{errors: %{detail: "Not found"}})
    end
  end

  defp serialize_meals_by_type(meals_by_type) do
    Map.new(meals_by_type, fn {type, logs} ->
      {type, Enum.map(logs, &serialize_meal_log/1)}
    end)
  end

  defp serialize_meal_log(log) do
    %{
      id: log.id,
      recipe_id: log.recipe_id,
      recipe_title: log.recipe.title,
      meal_type: log.meal_type,
      servings: log.servings,
      macros: log.macros
    }
  end

  defp serialize_recipe(recipe) do
    %{id: recipe.id, title: recipe.title}
  end

  defp load_targets(user_id) do
    case Profiles.get_profile(user_id) do
      {:ok, profile} ->
        t = Profiles.calculate_targets(profile)
        %{calories: t.calories, protein_g: t.protein_g, carbs_g: t.carbs_g, fat_g: t.fat_g}
      {:error, _} ->
        nil
    end
  end

  defp parse_date(nil), do: Date.utc_today()
  defp parse_date(%Date{} = d), do: d
  defp parse_date(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, d} -> d
      _ -> Date.utc_today()
    end
  end

  defp parse_int(v) when is_integer(v), do: v
  defp parse_int(v) when is_binary(v), do: String.to_integer(v)
  defp parse_int(_), do: nil

  defp parse_float(v) when is_float(v), do: v
  defp parse_float(v) when is_integer(v), do: v * 1.0
  defp parse_float(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error -> 1.0
    end
  end
  defp parse_float(_), do: 1.0

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
