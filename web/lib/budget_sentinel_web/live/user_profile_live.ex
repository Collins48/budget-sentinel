defmodule BudgetSentinelWeb.UserProfileLive do
  use BudgetSentinelWeb, :live_view

  alias BudgetSentinel.Accounts.User
  alias BudgetSentinel.Repo

  def mount(_params, _session, socket) do
    user = Repo.preload(socket.assigns.current_user, [:ministry, :invited_by])
    {:ok, assign(socket, :user, user)}
  end

  def render(assigns) do
    ~H"""
    <div class="page-heading">
      <h1>My Profile</h1>
    </div>

    <div class="card">
      <dl class="profile-grid">
        <dt>Email</dt>
        <dd><%= @user.email %></dd>

        <dt>Role</dt>
        <dd><%= @user.role |> String.replace("_", " ") |> String.capitalize() %></dd>

        <dt>Ministry scope</dt>
        <dd><%= (@user.ministry && @user.ministry.name) || "All ministries (administrator access)" %></dd>

        <dt>Permissions</dt>
        <dd>
          <%= if User.can_manage?(@user) do %>
            Can create/edit projects and expenditures, run detection scans, and action anomalies.
          <% else %>
            Read-only: can view dashboards, projects, anomalies, and alerts for your ministry.
          <% end %>
        </dd>

        <dt>Account status</dt>
        <dd>
          <span class={"status-pill status-pill--#{User.status(@user)}"}>
            <%= if User.status(@user) == :invited, do: "Invited", else: "Active" %>
          </span>
        </dd>

        <dt>Invited by</dt>
        <dd><%= (@user.invited_by && @user.invited_by.email) || "Seeded demo account" %></dd>

        <dt>Member since</dt>
        <dd><%= Calendar.strftime(@user.inserted_at, "%Y-%m-%d") %></dd>
      </dl>

      <div class="modal-actions" style="justify-content: flex-start; margin-top: 1.5rem;">
        <.link href={~p"/users/settings"} class="btn">Change email / password</.link>
      </div>
    </div>
    """
  end
end
