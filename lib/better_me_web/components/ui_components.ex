defmodule BetterMeWeb.UIComponents do
  use Phoenix.Component
  use BetterMeWeb, :verified_routes

  import BetterMeWeb.CoreComponents, only: [icon: 1]

  @doc """
  Page header with a title and an optional "New" action button.

  ## Examples

      <.page_header title="Habits" new_path={~p"/habits/new"} new_label="New" />
      <.page_header title="Body Metrics" new_path={~p"/health/new"} new_label="Log" />
  """
  attr :title, :string, required: true
  attr :new_path, :string, default: nil
  attr :new_label, :string, default: "New"

  def page_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold text-gray-900">{@title}</h1>
      <.link
        :if={@new_path}
        navigate={@new_path}
        class="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
      >
        <.icon name="hero-plus" class="h-4 w-4" /> {@new_label}
      </.link>
    </div>
    """
  end

  @doc """
  Form page header with a back arrow and title.

  ## Examples

      <.form_header title="New Habit" back_path={~p"/habits"} />
      <.form_header title="Edit Todo" back_path={~p"/todos"} />
  """
  attr :title, :string, required: true
  attr :back_path, :string, required: true

  def form_header(assigns) do
    ~H"""
    <div class="mb-6 flex items-center gap-2">
      <.link navigate={@back_path} class="text-gray-400 hover:text-gray-600">
        <.icon name="hero-arrow-left" class="h-5 w-5" />
      </.link>
      <h1 class="text-2xl font-bold text-gray-900">{@title}</h1>
    </div>
    """
  end

  @doc """
  Empty state message shown when a list has no items.

  ## Examples

      <.empty_state :if={@habits == []} message="No habits yet. Add your first one!" />
  """
  attr :message, :string, required: true

  def empty_state(assigns) do
    ~H"""
    <div class="text-center py-16 text-gray-400">
      {@message}
    </div>
    """
  end

  @doc """
  Form action buttons: submit, cancel, and optional delete.

  ## Examples

      <.form_actions action={:new} cancel_path={~p"/habits"} />
      <.form_actions action={:edit} cancel_path={~p"/todos"} on_delete="delete" />
  """
  attr :action, :atom, required: true
  attr :cancel_path, :string, required: true
  attr :on_delete, :string, default: nil
  attr :submit_label, :string, default: nil

  def form_actions(assigns) do
    ~H"""
    <div class="flex gap-3 pt-2">
      <button
        type="submit"
        class="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
      >
        {@submit_label || if(@action == :new, do: "Create", else: "Save")}
      </button>
      <.link
        navigate={@cancel_path}
        class="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
      >
        Cancel
      </.link>
      <button
        :if={@action == :edit && @on_delete}
        type="button"
        phx-click={@on_delete}
        data-confirm="Are you sure you want to delete this?"
        class="ml-auto rounded-md text-sm font-medium text-red-500 hover:text-red-700"
      >
        Delete
      </button>
    </div>
    """
  end

  @doc """
  Edit pencil icon link used in list rows.

  ## Examples

      <.edit_link path={~p"/habits/\#{habit.id}/edit"} />
  """
  attr :path, :string, required: true

  def edit_link(assigns) do
    ~H"""
    <.link navigate={@path} class="flex-shrink-0 text-gray-400 hover:text-gray-600">
      <.icon name="hero-pencil-square" class="h-4 w-4" />
    </.link>
    """
  end

  @doc """
  Tab bar for the Nutrition section — shared across /recipes and /ingredients.

  ## Examples

      <.nutrition_tabs active={:recipes} />
      <.nutrition_tabs active={:ingredients} />
  """
  attr :active, :atom, required: true, values: [:recipes, :ingredients]

  def nutrition_tabs(assigns) do
    ~H"""
    <div class="mb-6 flex border-b border-gray-200">
      <.link
        navigate={~p"/recipes"}
        class={[
          "px-4 py-2 text-sm font-medium border-b-2 -mb-px",
          if(@active == :recipes,
            do: "border-indigo-600 text-indigo-600",
            else: "border-transparent text-gray-500 hover:text-gray-700"
          )
        ]}
      >
        Recipes
      </.link>
      <.link
        navigate={~p"/ingredients"}
        class={[
          "px-4 py-2 text-sm font-medium border-b-2 -mb-px",
          if(@active == :ingredients,
            do: "border-indigo-600 text-indigo-600",
            else: "border-transparent text-gray-500 hover:text-gray-700"
          )
        ]}
      >
        Ingredients
      </.link>
    </div>
    """
  end

  @doc """
  Veg / non-veg badge pill.

  ## Examples

      <.veg_badge is_vegetarian={ingredient.is_vegetarian} />
  """
  attr :is_vegetarian, :boolean, required: true

  def veg_badge(assigns) do
    ~H"""
    <span
      :if={@is_vegetarian}
      class="rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700"
    >
      veg
    </span>
    <span
      :if={!@is_vegetarian}
      class="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700"
    >
      non-veg
    </span>
    """
  end

  @doc """
  4-column macro summary grid (calories, protein, carbs, fat).
  Used on recipe show and nutrition index (no-targets view).

  ## Examples

      <.macro_grid calories={312.0} protein={28.5} carbs={18.0} fat={10.2} />
  """
  attr :calories, :float, required: true
  attr :protein, :float, required: true
  attr :carbs, :float, required: true
  attr :fat, :float, required: true

  def macro_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-4 gap-2 rounded-lg border border-gray-200 bg-white p-4 text-center shadow-sm">
      <div>
        <p class="text-lg font-bold text-gray-900">{round(@calories)}</p>
        <p class="text-xs text-gray-400">kcal</p>
      </div>
      <div>
        <p class="text-lg font-bold text-gray-900">{Float.round(@protein, 1)}g</p>
        <p class="text-xs text-gray-400">protein</p>
      </div>
      <div>
        <p class="text-lg font-bold text-gray-900">{Float.round(@carbs, 1)}g</p>
        <p class="text-xs text-gray-400">carbs</p>
      </div>
      <div>
        <p class="text-lg font-bold text-gray-900">{Float.round(@fat, 1)}g</p>
        <p class="text-xs text-gray-400">fat</p>
      </div>
    </div>
    """
  end

  @doc """
  Standard page wrapper — constrains width and adds padding.
  Use as the outermost div on every page.

  ## Examples

      <.page_container>
        ...
      </.page_container>
  """
  slot :inner_block, required: true

  def page_container(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-4 py-8">
      {render_slot(@inner_block)}
    </div>
    """
  end
end
