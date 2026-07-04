defmodule BudgetSentinelWeb.HealthController do
  use BudgetSentinelWeb, :controller

  def show(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
