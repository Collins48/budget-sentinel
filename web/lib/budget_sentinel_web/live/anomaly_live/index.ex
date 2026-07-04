defmodule BudgetSentinelWeb.AnomalyLive.Index do
  use BudgetSentinelWeb, :live_view

  alias BudgetSentinel.Audit

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    status_filter = params["status"]

    opts = [limit: 100] ++ if(status_filter, do: [status: status_filter], else: [])
    anomalies = Audit.list_anomalies(socket.assigns.current_user, opts)

    {:noreply, assign(socket, anomalies: anomalies, status_filter: status_filter)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="page-heading">
      <h1>Anomaly History</h1>
      <div class="filter-tabs">
        <.link patch={~p"/anomalies"} class={["filter-tab", @status_filter == nil && "filter-tab--active"]}>All</.link>
        <.link patch={~p"/anomalies?status=open"} class={["filter-tab", @status_filter == "open" && "filter-tab--active"]}>Open</.link>
        <.link patch={~p"/anomalies?status=under_review"} class={["filter-tab", @status_filter == "under_review" && "filter-tab--active"]}>Under Review</.link>
        <.link patch={~p"/anomalies?status=resolved"} class={["filter-tab", @status_filter == "resolved" && "filter-tab--active"]}>Resolved</.link>
        <.link patch={~p"/anomalies?status=dismissed"} class={["filter-tab", @status_filter == "dismissed" && "filter-tab--active"]}>Dismissed</.link>
      </div>
    </div>

    <div class="card">
      <div :if={@anomalies == []} class="empty-state">
        No anomalies match this filter.
      </div>
      <table :if={@anomalies != []} class="data-table">
        <thead>
          <tr>
            <th>Project</th>
            <th>Fraud Type</th>
            <th>Risk Score</th>
            <th>Status</th>
            <th>Audit Report</th>
            <th>Detected</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={anomaly <- @anomalies}>
            <td><.link navigate={~p"/anomalies/#{anomaly.id}"}><%= anomaly.project.name %></.link></td>
            <td><.fraud_type_label fraud_type={anomaly.fraud_type} /></td>
            <td><.risk_badge severity={anomaly.severity} risk_score={anomaly.risk_score} /></td>
            <td><span class={["status-pill", "status-pill--#{anomaly.status}"]}><%= anomaly.status |> String.replace("_", " ") |> String.capitalize() %></span></td>
            <td><%= if anomaly.audit_report, do: "Generated", else: "Pending" %></td>
            <td><%= Calendar.strftime(anomaly.detected_at, "%Y-%m-%d %H:%M") %></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
