defmodule BudgetSentinel.Intelligence.AIClientBehaviour do
  @moduledoc """
  Port for the Python AI microservice. The web layer depends only on this
  behaviour, never on the HTTP adapter directly, so it can be swapped for a
  mock in tests.
  """

  @callback detect_anomalies(projects :: [map()], expenditures :: [map()]) ::
              {:ok, [map()]} | {:error, term()}

  @callback generate_report(anomaly :: map(), project :: map(), expenditure :: map()) ::
              {:ok, map()} | {:error, term()}
end
