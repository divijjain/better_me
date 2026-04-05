defmodule BetterMeWeb.ProfileLive.Index do
  use BetterMeWeb, :live_view

  alias BetterMe.Profiles

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {profile, action} =
      case Profiles.get_profile(user_id) do
        {:ok, profile} -> {profile, :edit}
        {:error, :not_found} -> {Profiles.new_profile(), :new}
      end

    changeset = Profiles.change_profile(profile)

    {:ok,
     socket
     |> assign(action: action, profile: profile, user_id: user_id)
     |> assign(activity_levels: activity_level_options())
     |> assign(genders: gender_options())
     |> assign_form(changeset)
     |> assign_targets(profile, action)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.page_header title="Profile & Targets" />

      <%!-- Current targets summary (only if profile exists) --%>
      <div :if={@action == :edit} class="mb-6 grid grid-cols-4 gap-2 rounded-xl border border-gray-200 bg-white p-4 shadow-sm text-center">
        <div>
          <p class="text-lg font-bold text-gray-900">{@targets.calories}</p>
          <p class="text-xs text-gray-400">kcal</p>
        </div>
        <div>
          <p class="text-lg font-bold text-gray-900">{@targets.protein_g}g</p>
          <p class="text-xs text-gray-400">protein</p>
        </div>
        <div>
          <p class="text-lg font-bold text-gray-900">{@targets.carbs_g}g</p>
          <p class="text-xs text-gray-400">carbs</p>
        </div>
        <div>
          <p class="text-lg font-bold text-gray-900">{@targets.fat_g}g</p>
          <p class="text-xs text-gray-400">fat</p>
        </div>
      </div>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Age</label>
            <.input field={@form[:age]} type="number" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Gender</label>
            <.input field={@form[:gender]} type="select" options={@genders} class="w-full" />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Weight (kg)</label>
            <.input field={@form[:weight_kg]} type="number" step="0.1" class="w-full" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Height (cm)</label>
            <.input field={@form[:height_cm]} type="number" step="0.1" class="w-full" />
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Activity Level</label>
          <.input field={@form[:activity_level]} type="select" options={@activity_levels} class="w-full" />
        </div>

        <div>
          <h3 class="text-sm font-medium text-gray-700 mb-2">
            Macro Split
            <span class="text-gray-400 font-normal ml-1">(fat auto-adjusts)</span>
          </h3>
          <div class="grid grid-cols-3 gap-4">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Protein %</label>
              <.input field={@form[:protein_pct]} type="number" min="1" max="98" class="w-full" />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Carbs %</label>
              <.input field={@form[:carbs_pct]} type="number" min="1" max="98" class="w-full" />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Fat %</label>
              <div class="flex h-10 items-center rounded-md border border-gray-200 bg-gray-50 px-3 text-sm text-gray-500">
                {@fat_pct}%
              </div>
            </div>
          </div>
        </div>

        <.form_actions action={@action} cancel_path={~p"/habits"} />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", %{"user_profile" => params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profiles.change_profile(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> assign_fat_pct(params)}
  end

  def handle_event("save", %{"user_profile" => params}, socket) do
    case Profiles.save_profile(socket.assigns.user_id, params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> assign(action: :edit, profile: profile)
         |> assign_targets(profile, :edit)
         |> assign_form(Profiles.change_profile(profile))
         |> put_flash(:info, "Profile saved")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_targets(socket, _profile, :new), do: assign(socket, targets: nil, fat_pct: 30)

  defp assign_targets(socket, profile, :edit) do
    targets  = Profiles.calculate_targets(profile)
    fat_pct  = 100 - profile.protein_pct - profile.carbs_pct
    assign(socket, targets: targets, fat_pct: fat_pct)
  end

  defp assign_fat_pct(socket, params) do
    protein = parse_int(params["protein_pct"], 30)
    carbs   = parse_int(params["carbs_pct"],   40)
    fat     = max(100 - protein - carbs, 0)
    assign(socket, :fat_pct, fat)
  end

  defp parse_int(val, default) do
    case Integer.parse(to_string(val)) do
      {n, _} -> n
      :error  -> default
    end
  end

  defp activity_level_options do
    Profiles.activity_levels()
    |> Enum.map(fn level ->
      label = level |> to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, level}
    end)
  end

  defp gender_options do
    Profiles.genders()
    |> Enum.map(fn g -> {String.capitalize(to_string(g)), g} end)
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
