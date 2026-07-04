defmodule BudgetSentinel.IntelligenceTest.MockAIClient do
  @moduledoc """
  Test double for the Python AI microservice, configured as the `:ai_client`
  implementation in `config/test.exs` so tests never make real HTTP calls.
  """

  @behaviour BudgetSentinel.Intelligence.AIClientBehaviour

  @impl true
  def detect_anomalies(_projects, expenditures) do
    anomalies =
      expenditures
      |> Enum.take(1)
      |> Enum.map(fn expenditure ->
        %{
          "expenditure_id" => to_string(expenditure.id),
          "project_id" => to_string(expenditure.project_id),
          "fraud_type" => "budget_overrun",
          "risk_score" => 85.0,
          "severity" => "high",
          "anomaly_score" => 0.91,
          "explanation" => "Stubbed anomaly for test purposes."
        }
      end)

    {:ok, anomalies}
  end

  @impl true
  def generate_report(_anomaly, _project, _expenditure) do
    {:ok,
     %{
       "summary" => "Stubbed audit summary.",
       "severity_assessment" => "Stubbed severity assessment.",
       "recommended_actions" => "Stubbed recommended actions."
     }}
  end
end
