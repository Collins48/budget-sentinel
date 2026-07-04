defmodule BudgetSentinel.Intelligence.HttpAIClient do
  @moduledoc """
  HTTP adapter that forwards expenditure data to the Python Flask AI
  microservice and parses its anomaly/report responses.
  """

  @behaviour BudgetSentinel.Intelligence.AIClientBehaviour

  @impl true
  def detect_anomalies(projects, expenditures) do
    case post("/api/v1/anomalies/detect", %{projects: projects, expenditures: expenditures}) do
      {:ok, %{"anomalies" => anomalies}} -> {:ok, anomalies}
      {:ok, body} -> {:error, {:unexpected_response, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def generate_report(anomaly, project, expenditure) do
    post("/api/v1/audit-reports/generate", %{
      anomaly: anomaly,
      project: project,
      expenditure: expenditure
    })
  end

  defp post(path, body) do
    base_url = Application.fetch_env!(:budget_sentinel, :ai_service_base_url)

    case Req.post(base_url <> path, json: body, receive_timeout: 15_000) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}

      {:ok, %{status: status, body: response_body}} ->
        {:error, {:http_error, status, response_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
