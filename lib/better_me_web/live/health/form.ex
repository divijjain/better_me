defmodule BetterMeWeb.HealthLive.Form do
  use BetterMeWeb, :live_view

  alias BetterMe.Health

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {metric, action} = load_metric(params, user_id)
    changeset = Health.change_metric(metric)

    {:ok,
     socket
     |> assign(action: action, metric: metric, user_id: user_id)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <.form_header
        title={if @action == :new, do: "Log Measurement", else: "Edit Measurement"}
        back_path={~p"/health"}
      />

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
          <.input field={@form[:date]} type="date" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Weight (kg) <span class="text-gray-400">(optional)</span>
          </label>
          <.input
            field={@form[:weight]}
            type="number"
            step="0.1"
            placeholder="e.g. 75.5"
            class="w-full"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Body fat % <span class="text-gray-400">(optional)</span>
          </label>
          <.input
            field={@form[:body_fat_pct]}
            type="number"
            step="0.1"
            placeholder="e.g. 18.5"
            class="w-full"
          />
        </div>

        <.form_actions
          action={@action}
          cancel_path={~p"/health"}
          on_delete="delete"
          submit_label={if @action == :new, do: "Save", else: "Update"}
        />
      </.form>
    </.page_container>
    """
  end

  def handle_event("validate", %{"body_metric" => params}, socket) do
    changeset =
      socket.assigns.metric
      |> Health.change_metric(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"body_metric" => params}, socket) do
    case socket.assigns.action do
      :new -> log_metric(socket, params)
      :edit -> update_metric(socket, params)
    end
  end

  def handle_event("delete", _params, socket) do
    case Health.delete_metric(socket.assigns.metric) do
      {:ok, _} -> {:noreply, push_navigate(socket, to: ~p"/health")}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not delete entry")}
    end
  end

  defp log_metric(socket, params) do
    case Health.log_metric(socket.assigns.user_id, params) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Measurement logged") |> push_navigate(to: ~p"/health")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_metric(socket, params) do
    case Health.update_metric(socket.assigns.metric, params) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Measurement updated") |> push_navigate(to: ~p"/health")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_metric(%{"id" => id}, user_id), do: {Health.get_metric!(id, user_id), :edit}
  defp load_metric(_params, _user_id), do: {Health.new_metric(), :new}

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
end
