defmodule BudgetSentinelWeb.Router do
  use Phoenix.Router, helpers: false

  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Plug.Conn
  import BudgetSentinelWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", BudgetSentinelWeb do
    get "/health", HealthController, :show
  end

  scope "/", BudgetSentinelWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{BudgetSentinelWeb.UserAuth, :ensure_authenticated}] do
      live "/", DashboardLive, :index
      live "/projects", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.Index, :new
      live "/projects/:id", ProjectLive.Show, :show
      live "/projects/:id/edit", ProjectLive.Show, :edit
      live "/projects/:id/expenditures/new", ProjectLive.Show, :new_expenditure
      live "/projects/:id/expenditures/:expenditure_id/edit", ProjectLive.Show, :edit_expenditure
      live "/anomalies", AnomalyLive.Index, :index
      live "/anomalies/:id", AnomalyLive.Show, :show
      live "/alerts", AlertLive.Index, :index
    end

    live_session :admin,
      on_mount: [{BudgetSentinelWeb.UserAuth, :ensure_admin}] do
      live "/admin/users", UserManagementLive.Index, :index
      live "/admin/users/new", UserManagementLive.Index, :new
    end
  end

  ## Authentication routes

  scope "/", BudgetSentinelWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{BudgetSentinelWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", BudgetSentinelWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{BudgetSentinelWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/users/profile", UserProfileLive, :show
    end
  end

  scope "/", BudgetSentinelWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{BudgetSentinelWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
      live "/users/invite/:token", UserInviteAcceptLive, :edit
    end
  end
end
