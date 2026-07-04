defmodule BudgetSentinelWeb.UserManagementLive.Index do
  use BudgetSentinelWeb, :live_view

  alias BudgetSentinel.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, Accounts.list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params), do: assign(socket, :page_title, "User Accounts")
  defp apply_action(socket, :new, _params), do: assign(socket, :page_title, "New Account")

  @impl true
  def handle_info({BudgetSentinelWeb.UserManagementLive.FormComponent, {:saved, _user}}, socket) do
    {:noreply, assign(socket, :users, Accounts.list_users())}
  end

  @impl true
  def handle_event("resend_invite", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.resend_invite(user, &url(~p"/users/invite/#{&1}"))

    {:noreply,
     socket
     |> put_flash(:info, "Invitation resent to #{user.email}")
     |> assign(:users, Accounts.list_users())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="page-heading">
      <h1>User Accounts</h1>
      <.link patch={~p"/admin/users/new"} class="btn">Invite Account</.link>
    </div>

    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Email</th>
            <th>Role</th>
            <th>Ministry</th>
            <th>Status</th>
            <th>Invited by</th>
            <th>Created</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={user <- @users}>
            <td><%= user.email %></td>
            <td><%= user.role |> String.replace("_", " ") |> String.capitalize() %></td>
            <td><%= (user.ministry && user.ministry.name) || "—" %></td>
            <td>
              <span class={"status-pill status-pill--#{BudgetSentinel.Accounts.User.status(user)}"}>
                <%= if BudgetSentinel.Accounts.User.status(user) == :invited, do: "Invited", else: "Active" %>
              </span>
            </td>
            <td><%= (user.invited_by && user.invited_by.email) || "—" %></td>
            <td><%= Calendar.strftime(user.inserted_at, "%Y-%m-%d") %></td>
            <td>
              <button
                :if={BudgetSentinel.Accounts.User.status(user) == :invited}
                phx-click="resend_invite"
                phx-value-id={user.id}
                class="btn btn--secondary btn--small"
              >
                Resend invite
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <.live_component
      :if={@live_action == :new}
      module={BudgetSentinelWeb.UserManagementLive.FormComponent}
      id="new-user"
      current_user={@current_user}
      patch={~p"/admin/users"}
    />
    """
  end
end
