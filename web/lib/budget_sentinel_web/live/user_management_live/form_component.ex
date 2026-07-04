defmodule BudgetSentinelWeb.UserManagementLive.FormComponent do
  use BudgetSentinelWeb, :live_component

  alias BudgetSentinel.Accounts
  alias BudgetSentinel.Accounts.User
  alias BudgetSentinel.Ministries

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:ministries, Ministries.list_ministries())
     |> assign(:roles, User.roles())
     |> assign(:form, to_form(Accounts.change_user_invite(%User{})))}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset = Accounts.change_user_invite(%User{}, params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => params}, socket) do
    params = Map.put(params, "invited_by_id", socket.assigns.current_user.id)

    case Accounts.invite_user(params, &url(~p"/users/invite/#{&1}")) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "Invitation sent to #{user.email}")
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
        <h2>Invite Account</h2>
        <p class="form-hint">
          The recipient gets an email with a secure link to accept the invite and set their own password. No password is set here.
        </p>
        <.form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
          <div class="form-field">
            <label>Email</label>
            <input type="email" name="user[email]" value={@form[:email].value} />
            <p :for={msg <- @form[:email].errors |> Enum.map(&translate_error/1)} class="form-error"><%= msg %></p>
          </div>

          <div class="form-field">
            <label>Role</label>
            <select name="user[role]">
              <option :for={role <- @roles} value={role} selected={@form[:role].value == role}>
                <%= role |> String.replace("_", " ") |> String.capitalize() %>
              </option>
            </select>
          </div>

          <div class="form-field">
            <label>Ministry (leave blank for admins)</label>
            <select name="user[ministry_id]">
              <option value="">No ministry / all ministries</option>
              <option :for={ministry <- @ministries} value={ministry.id} selected={to_string(@form[:ministry_id].value) == to_string(ministry.id)}>
                <%= ministry.name %>
              </option>
            </select>
          </div>

          <div class="modal-actions">
            <.link patch={@patch} class="btn btn--secondary">Cancel</.link>
            <button type="submit" class="btn">Send Invitation</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp translate_error({msg, _opts}), do: msg
end
