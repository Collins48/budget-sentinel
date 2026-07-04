defmodule BudgetSentinel.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BudgetSentinelWeb.Telemetry,
      BudgetSentinel.Repo,
      {Phoenix.PubSub, name: BudgetSentinel.PubSub},
      {Finch, name: BudgetSentinel.Finch},
      {Task.Supervisor, name: BudgetSentinel.TaskSupervisor},
      BudgetSentinelWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: BudgetSentinel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BudgetSentinelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
