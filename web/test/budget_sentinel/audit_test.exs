defmodule BudgetSentinel.AuditTest do
  use BudgetSentinel.DataCase, async: true

  alias BudgetSentinel.{Audit, Procurement}

  setup do
    {:ok, project} =
      Procurement.create_project(%{
        name: "Test Bridge Project",
        sector: "infrastructure",
        approved_budget: Decimal.new("100000"),
        completion_rate: Decimal.new("0")
      })

    {:ok, expenditure} =
      Procurement.create_expenditure(%{
        project_id: project.id,
        contractor: "Akagera Civil Works",
        amount: Decimal.new("60000"),
        milestone: "handover",
        paid_on: ~D[2024-03-01]
      })

    %{project: project, expenditure: expenditure}
  end

  test "record_anomaly persists a detected anomaly", %{project: project, expenditure: expenditure} do
    assert {:ok, anomaly} =
             Audit.record_anomaly(%{
               fraud_type: "ghost_project",
               risk_score: Decimal.new("85.0"),
               severity: "high",
               anomaly_score: Decimal.new("0.9"),
               explanation: "Full payment against zero completion.",
               project_id: project.id,
               expenditure_id: expenditure.id
             })

    assert anomaly.fraud_type == "ghost_project"
    assert Audit.high_risk?(anomaly)
  end

  test "high_risk?/1 returns false below the configured threshold", %{
    project: project,
    expenditure: expenditure
  } do
    {:ok, anomaly} =
      Audit.record_anomaly(%{
        fraud_type: "budget_overrun",
        risk_score: Decimal.new("30.0"),
        severity: "low",
        project_id: project.id,
        expenditure_id: expenditure.id
      })

    refute Audit.high_risk?(anomaly)
  end
end
