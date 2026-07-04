defmodule BudgetSentinelWeb do
  @moduledoc """
  Shared imports/aliases for controllers, views, and LiveViews, plus the
  list of static asset paths served directly by the endpoint.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  defmacro __using__(which)
           when which in [:controller, :live_view, :live_component, :html, :verified_routes] do
    apply(__MODULE__, which, [])
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: BudgetSentinelWeb, formats: [:html, :json]

      import Plug.Conn
      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {BudgetSentinelWeb.Layouts, :app}
      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import BudgetSentinelWeb.CoreComponents

      alias Phoenix.LiveView.JS

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BudgetSentinelWeb.Endpoint,
        router: BudgetSentinelWeb.Router,
        statics: BudgetSentinelWeb.static_paths()
    end
  end
end
