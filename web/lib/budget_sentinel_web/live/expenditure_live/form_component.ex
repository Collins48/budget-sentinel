defmodule BudgetSentinelWeb.ExpenditureLive.FormComponent do
  use BudgetSentinelWeb, :live_component

  alias BudgetSentinel.Procurement

  @impl true
  def update(%{expenditure: expenditure} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(Procurement.change_expenditure(expenditure)))}
  end

  @impl true
  def handle_event("validate", %{"expenditure" => params}, socket) do
    changeset = Procurement.change_expenditure(socket.assigns.expenditure, params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"expenditure" => params}, socket) do
    params = Map.put(params, "project_id", socket.assigns.project_id)
    save_expenditure(socket, socket.assigns.action, params)
  end

  defp save_expenditure(socket, :new, params) do
    case Procurement.create_expenditure(params) do
      {:ok, expenditure} ->
        notify_parent({:saved, expenditure})

        {:noreply,
         socket
         |> put_flash(:info, "Expenditure recorded")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_expenditure(socket, :edit, params) do
    case Procurement.update_expenditure(socket.assigns.expenditure, params) do
      {:ok, expenditure} ->
        notify_parent({:saved, expenditure})

        {:noreply,
         socket
         |> put_flash(:info, "Expenditure updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div class="modal-backdrop">
      <div class="modal-panel card">
        <h2><%= if @action == :new, do: "Add Expenditure", else: "Edit Expenditure" %></h2>
        <.form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
          <div class="form-field">
            <label>Contractor</label>
            <input type="text" name="expenditure[contractor]" value={@form[:contractor].value} />
            <p :for={msg <- @form[:contractor].errors |> Enum.map(&translate_error/1)} class="form-error"><%= msg %></p>
          </div>

          <div class="form-field">
            <label>Amount</label>
            <input type="number" step="0.01" name="expenditure[amount]" value={@form[:amount].value} />
            <p :for={msg <- @form[:amount].errors |> Enum.map(&translate_error/1)} class="form-error"><%= msg %></p>
          </div>

          <div class="form-field">
            <label>Milestone</label>
            <input type="text" name="expenditure[milestone]" value={@form[:milestone].value} placeholder="e.g. foundation" />
            <p :for={msg <- @form[:milestone].errors |> Enum.map(&translate_error/1)} class="form-error"><%= msg %></p>
          </div>

          <div class="form-field">
            <label>Paid On</label>
            <input type="date" name="expenditure[paid_on]" value={@form[:paid_on].value} />
            <p :for={msg <- @form[:paid_on].errors |> Enum.map(&translate_error/1)} class="form-error"><%= msg %></p>
          </div>

          <div class="modal-actions">
            <.link patch={@patch} class="btn btn--secondary">Cancel</.link>
            <button type="submit" class="btn">Save</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp translate_error({msg, _opts}), do: msg
end
