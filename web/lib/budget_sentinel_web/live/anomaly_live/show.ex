defmodule BudgetSentinelWeb.AnomalyLive.Show do
  use BudgetSentinelWeb, :live_view

  alias BudgetSentinel.Accounts.User
  alias BudgetSentinel.Audit
  alias BudgetSentinel.Audit.Anomaly

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    anomaly = Audit.get_anomaly!(id)
    user = socket.assigns.current_user

    if User.admin?(user) or anomaly.project.ministry_id == user.ministry_id do
      {:ok,
       socket
       |> assign(:anomaly, anomaly)
       |> assign(:status_form, to_form(Audit.change_anomaly_status(anomaly)))}
    else
      {:ok,
       socket
       |> put_flash(:error, "You don't have access to that anomaly.")
       |> push_navigate(to: ~p"/anomalies")}
    end
  end

  @impl true
  def handle_event("validate_status", %{"anomaly" => params}, socket) do
    changeset = Audit.change_anomaly_status(socket.assigns.anomaly, params)
    {:noreply, assign(socket, :status_form, to_form(changeset, action: :validate))}
  end

  def handle_event("update_status", %{"anomaly" => params}, socket) do
    if User.can_manage?(socket.assigns.current_user) do
      case Audit.update_anomaly_status(socket.assigns.anomaly, params, socket.assigns.current_user) do
        {:ok, _anomaly} ->
          anomaly = Audit.get_anomaly!(socket.assigns.anomaly.id)

          {:noreply,
           socket
           |> put_flash(:info, "Anomaly status updated")
           |> assign(:anomaly, anomaly)
           |> assign(:status_form, to_form(Audit.change_anomaly_status(anomaly)))}

        {:error, changeset} ->
          {:noreply, assign(socket, :status_form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to update this anomaly.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="page-heading">
      <h1>Anomaly #<%= @anomaly.id %></h1>
      <div class="row-actions">
        <span class={["status-pill", "status-pill--#{@anomaly.status}"]}><%= humanize(@anomaly.status) %></span>
        <.risk_badge severity={@anomaly.severity} risk_score={@anomaly.risk_score} />
      </div>
    </div>

    <div class="card">
      <h2>Detection Details</h2>
      <p><strong>Project:</strong> <.link navigate={~p"/projects/#{@anomaly.project_id}"}><%= @anomaly.project.name %></.link></p>
      <p><strong>Fraud type:</strong> <.fraud_type_label fraud_type={@anomaly.fraud_type} /></p>
      <p><strong>Contractor:</strong> <%= @anomaly.expenditure.contractor %></p>
      <p><strong>Amount:</strong> <%= Decimal.to_string(@anomaly.expenditure.amount) %></p>
      <p><strong>Detected at:</strong> <%= Calendar.strftime(@anomaly.detected_at, "%Y-%m-%d %H:%M") %></p>
      <p><strong>Explanation:</strong> <%= @anomaly.explanation %></p>
    </div>

    <div class="card" :if={@anomaly.audit_report}>
      <h2>AI-Generated Audit Report</h2>
      <p><strong>Summary</strong></p>
      <p><%= @anomaly.audit_report.summary %></p>
      <p><strong>Severity Assessment</strong></p>
      <p><%= @anomaly.audit_report.severity_assessment %></p>
      <p><strong>Recommended Actions</strong></p>
      <p><%= @anomaly.audit_report.recommended_actions %></p>
    </div>

    <div class="card">
      <h2>Audit Review</h2>
      <p :if={@anomaly.reviewed_by}>
        <strong>Last reviewed by:</strong> <%= @anomaly.reviewed_by.email %>
        on <%= Calendar.strftime(@anomaly.reviewed_at, "%Y-%m-%d %H:%M") %>
      </p>
      <p :if={@anomaly.resolution_notes}><strong>Notes:</strong> <%= @anomaly.resolution_notes %></p>

      <.form
        :if={User.can_manage?(@current_user)}
        for={@status_form}
        phx-change="validate_status"
        phx-submit="update_status"
      >
        <div class="form-field">
          <label>Status</label>
          <select name="anomaly[status]" class="status-select">
            <option :for={status <- Anomaly.statuses()} value={status} selected={@status_form[:status].value == status}>
              <%= humanize(status) %>
            </option>
          </select>
        </div>
        <div class="form-field">
          <label>Resolution Notes</label>
          <textarea name="anomaly[resolution_notes]" class="textarea-field"><%= @status_form[:resolution_notes].value %></textarea>
        </div>
        <button type="submit" class="btn">Update Status</button>
      </.form>
    </div>

    <div class="card" :if={@anomaly.alerts != []}>
      <h2>Alert Dispatch History</h2>
      <table class="data-table">
        <thead>
          <tr>
            <th>Recipient</th>
            <th>Status</th>
            <th>Dispatched At</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={alert <- @anomaly.alerts}>
            <td><%= alert.recipient %></td>
            <td><span class={["alert-status", "alert-status--#{alert.status}"]}><%= String.capitalize(alert.status) %></span></td>
            <td><%= alert.dispatched_at && Calendar.strftime(alert.dispatched_at, "%Y-%m-%d %H:%M") %></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp humanize(value), do: value |> String.replace("_", " ") |> String.capitalize()
end
