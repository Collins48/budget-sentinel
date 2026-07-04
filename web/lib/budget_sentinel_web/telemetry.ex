defmodule BudgetSentinelWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.live_view.mount.stop.duration", unit: {:native, :millisecond}),
      summary("budget_sentinel.repo.query.total_time", unit: {:native, :millisecond}),
      last_value("vm.memory.total", unit: {:byte, :megabyte}),
      last_value("vm.total_run_queue_lengths.total")
    ]
  end

  defp periodic_measurements, do: []
end
