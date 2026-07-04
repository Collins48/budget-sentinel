defmodule BudgetSentinelWeb.UserInviteAcceptLive do
  use BudgetSentinelWeb, :live_view

  alias BudgetSentinel.Accounts

  def render(assigns) do
    ~H"""
    <div class="auth-page card">
      <.header>
        Accept your invitation
        <:subtitle>
          You've been invited to BudgetSentinel as
          <strong><%= role_label(@user) %></strong>
          for <strong><%= ministry_label(@user) %></strong>. Set a password to activate your account.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="accept_invite_form"
        phx-submit="accept_invite"
        phx-change="validate"
      >
        <.error :if={@form.errors != []}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:password]} type="password" label="Password" required />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm password"
          required
        />
        <:actions>
          <.button phx-disable-with="Activating..." class="btn--full">Accept &amp; Activate Account</.button>
        </:actions>
      </.simple_form>

      <p class="auth-header__subtitle" style="text-align: center; margin-top: 1rem;">
        <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    # Accepting an invite is independent of whatever session happens to be
    # active in this browser — always render the logged-out app shell so an
    # admin testing their own invite link doesn't see the authenticated nav.
    socket = assign(socket, :current_user, nil)
    socket = assign_user_and_token(socket, token)

    form_source =
      case socket.assigns do
        %{user: user} -> Accounts.change_user_invite_acceptance(user)
        _ -> %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  def handle_event("accept_invite", %{"user" => user_params}, socket) do
    case Accounts.accept_invite(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account activated. Log in with your new password.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_invite_acceptance(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, token) do
    if user = Accounts.get_user_by_invite_token(token) do
      user = BudgetSentinel.Repo.preload(user, :ministry)
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Invitation link is invalid or has expired. Ask an administrator to resend it.")
      |> redirect(to: ~p"/users/log_in")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end

  defp role_label(%{role: role}), do: role |> String.replace("_", " ") |> String.capitalize()
  defp role_label(_), do: ""

  defp ministry_label(%{ministry: %{name: name}}), do: name
  defp ministry_label(_), do: "all ministries (administrator access)"
end
