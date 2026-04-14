defmodule BetterMeWeb.UIComponents do
  use Phoenix.Component
  use BetterMeWeb, :verified_routes

  import BetterMeWeb.CoreComponents, only: [icon: 1]

  # ── Navigation components ──────────────────────────────────────────────────

  @doc """
  Desktop sidebar nav link with active state detection.
  """
  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :current_path, :string, default: ""

  def sidebar_link(assigns) do
    active = String.starts_with?(assigns.current_path, assigns.navigate)
    assigns = assign(assigns, :active, active)

    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
        if(@active,
          do: "bg-teal-500/10 text-teal-400",
          else: "text-slate-400 hover:bg-slate-800 hover:text-slate-200"
        )
      ]}
    >
      <.icon name={@icon} class="h-4 w-4 shrink-0" />
      {@label}
      <div :if={@active} class="ml-auto h-1.5 w-1.5 rounded-full bg-teal-400" />
    </.link>
    """
  end

  @doc """
  Mobile bottom nav link with active state detection.
  """
  attr :navigate, :string, required: true
  attr :label, :string, required: true
  attr :current_path, :string, default: ""
  slot :inner_block, required: true

  def mobile_nav_link(assigns) do
    active = String.starts_with?(assigns.current_path, assigns.navigate)
    assigns = assign(assigns, :active, active)

    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex flex-col items-center gap-0.5 px-3 py-2 text-xs font-medium transition-colors min-w-0 flex-1",
        if(@active, do: "text-teal-600", else: "text-slate-400 hover:text-slate-600")
      ]}
    >
      <div class={[
        "flex items-center justify-center rounded-lg w-8 h-6 transition-colors",
        if(@active, do: "bg-teal-50", else: "")
      ]}>
        {render_slot(@inner_block)}
      </div>
      <span class={if(@active, do: "font-bold", else: "")}>{@label}</span>
    </.link>
    """
  end

  @doc """
  Row link inside the mobile More slide-up sheet.
  """
  attr :navigate, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :current_path, :string, default: ""
  attr :"phx-click", :any, default: nil

  def more_sheet_link(assigns) do
    active = String.starts_with?(assigns.current_path, assigns.navigate)
    assigns = assign(assigns, :active, active)

    ~H"""
    <.link
      navigate={@navigate}
      phx-click={assigns[:"phx-click"]}
      class={[
        "flex items-center gap-4 px-3 py-3 rounded-xl text-sm font-medium transition-colors",
        if(@active, do: "bg-teal-50 text-teal-600", else: "text-slate-700 hover:bg-slate-50")
      ]}
    >
      <span class={[
        "flex h-9 w-9 items-center justify-center rounded-lg shrink-0",
        if(@active, do: "bg-teal-100 text-teal-600", else: "bg-slate-100 text-slate-500")
      ]}>
        <.icon name={@icon} class="h-5 w-5" />
      </span>
      {@label}
      <.icon name="hero-chevron-right" class="h-4 w-4 ml-auto text-slate-300" />
    </.link>
    """
  end

  # ── Page layout components ─────────────────────────────────────────────────

  @doc """
  Standard page wrapper — constrains width, adds padding, responsive.
  """
  slot :inner_block, required: true

  def page_container(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-6 md:py-8">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Page header with a title and an optional "New" action button.
  """
  attr :title, :string, required: true
  attr :new_path, :string, default: nil
  attr :new_label, :string, default: "New"

  def page_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-bold text-slate-900">{@title}</h1>
      <.link
        :if={@new_path}
        navigate={@new_path}
        class="inline-flex items-center gap-1.5 rounded-lg bg-teal-600 px-3 py-2 text-sm font-semibold text-white hover:bg-teal-500 transition-colors shadow-sm"
      >
        <.icon name="hero-plus" class="h-4 w-4" /> {@new_label}
      </.link>
    </div>
    """
  end

  @doc """
  Form page header with a back arrow and title.
  """
  attr :title, :string, required: true
  attr :back_path, :string, required: true

  def form_header(assigns) do
    ~H"""
    <div class="mb-6 flex items-center gap-3">
      <.link
        navigate={@back_path}
        class="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 text-slate-400 hover:text-slate-600 hover:bg-slate-50 transition"
      >
        <.icon name="hero-arrow-left" class="h-4 w-4" />
      </.link>
      <h1 class="text-xl font-bold text-slate-900">{@title}</h1>
    </div>
    """
  end

  @doc """
  Empty state message shown when a list has no items.
  """
  attr :message, :string, required: true

  def empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-14 text-center">
      <div class="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-slate-100">
        <.icon name="hero-inbox" class="h-6 w-6 text-slate-400" />
      </div>
      <p class="text-sm font-medium text-slate-500">{@message}</p>
    </div>
    """
  end

  @doc """
  Form action buttons: submit, cancel, and optional delete.
  """
  attr :action, :atom, required: true
  attr :cancel_path, :string, required: true
  attr :on_delete, :string, default: nil
  attr :submit_label, :string, default: nil

  def form_actions(assigns) do
    ~H"""
    <div class="flex items-center gap-3 pt-4 border-t border-slate-100 mt-2">
      <button
        type="submit"
        class="rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-500 transition-colors shadow-sm"
      >
        {@submit_label || if(@action == :new, do: "Create", else: "Save changes")}
      </button>
      <.link
        navigate={@cancel_path}
        class="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50 transition"
      >
        Cancel
      </.link>
      <button
        :if={@action == :edit && @on_delete}
        type="button"
        phx-click={@on_delete}
        data-confirm="Are you sure you want to delete this?"
        class="ml-auto rounded-lg px-3 py-2 text-sm font-medium text-red-500 hover:bg-red-50 hover:text-red-600 transition"
      >
        Delete
      </button>
    </div>
    """
  end

  @doc """
  Edit pencil icon link used in list rows.
  """
  attr :path, :string, required: true

  def edit_link(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class="flex-shrink-0 flex h-7 w-7 items-center justify-center rounded-md text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
    >
      <.icon name="hero-pencil-square" class="h-4 w-4" />
    </.link>
    """
  end

  # ── Nutrition-specific components ──────────────────────────────────────────

  @doc """
  Tab bar for the Nutrition section.
  """
  attr :active, :atom, required: true, values: [:log, :recipes, :ingredients]

  def nutrition_tabs(assigns) do
    ~H"""
    <div class="mb-6 flex gap-1 border-b border-slate-200">
      <.link
        navigate={~p"/nutrition"}
        class={[
          "px-4 py-2 text-sm font-semibold border-b-2 -mb-px transition-colors",
          if(@active == :log,
            do: "border-teal-600 text-teal-600",
            else: "border-transparent text-slate-500 hover:text-slate-700"
          )
        ]}
      >
        Daily Log
      </.link>
      <.link
        navigate={~p"/recipes"}
        class={[
          "px-4 py-2 text-sm font-semibold border-b-2 -mb-px transition-colors",
          if(@active == :recipes,
            do: "border-teal-600 text-teal-600",
            else: "border-transparent text-slate-500 hover:text-slate-700"
          )
        ]}
      >
        Recipes
      </.link>
      <.link
        navigate={~p"/ingredients"}
        class={[
          "px-4 py-2 text-sm font-semibold border-b-2 -mb-px transition-colors",
          if(@active == :ingredients,
            do: "border-teal-600 text-teal-600",
            else: "border-transparent text-slate-500 hover:text-slate-700"
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
  """
  attr :is_vegetarian, :boolean, required: true

  def veg_badge(assigns) do
    ~H"""
    <span
      :if={@is_vegetarian}
      class="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-semibold text-emerald-700"
    >
      veg
    </span>
    <span
      :if={!@is_vegetarian}
      class="rounded-full bg-red-100 px-2 py-0.5 text-xs font-semibold text-red-700"
    >
      non-veg
    </span>
    """
  end

  @doc """
  4-column macro summary grid (calories, protein, carbs, fat).
  """
  attr :calories, :float, required: true
  attr :protein, :float, required: true
  attr :carbs, :float, required: true
  attr :fat, :float, required: true

  def macro_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-4 gap-3 rounded-xl border border-slate-200 bg-white p-4 text-center shadow-sm">
      <div class="space-y-0.5">
        <p class="text-lg font-bold text-slate-900">{round(@calories)}</p>
        <p class="text-xs font-medium text-slate-400">kcal</p>
      </div>
      <div class="space-y-0.5 border-l border-slate-100">
        <p class="text-lg font-bold text-red-500">{Float.round(@protein, 1)}g</p>
        <p class="text-xs font-medium text-slate-400">protein</p>
      </div>
      <div class="space-y-0.5 border-l border-slate-100">
        <p class="text-lg font-bold text-amber-500">{Float.round(@carbs, 1)}g</p>
        <p class="text-xs font-medium text-slate-400">carbs</p>
      </div>
      <div class="space-y-0.5 border-l border-slate-100">
        <p class="text-lg font-bold text-purple-500">{Float.round(@fat, 1)}g</p>
        <p class="text-xs font-medium text-slate-400">fat</p>
      </div>
    </div>
    """
  end
end
