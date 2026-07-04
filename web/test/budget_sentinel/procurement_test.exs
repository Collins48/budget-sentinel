defmodule BudgetSentinel.ProcurementTest do
  use BudgetSentinel.DataCase, async: true

  alias BudgetSentinel.Procurement

  test "budget_utilization_percent reflects total disbursed against approved budget" do
    {:ok, project} =
      Procurement.create_project(%{
        name: "Test Road Project",
        sector: "infrastructure",
        approved_budget: Decimal.new("100000"),
        completion_rate: Decimal.new("50")
      })

    {:ok, _} =
      Procurement.create_expenditure(%{
        project_id: project.id,
        contractor: "Kivu Builders Ltd",
        amount: Decimal.new("40000"),
        milestone: "foundation",
        paid_on: ~D[2024-02-01]
      })

    assert Decimal.equal?(Procurement.budget_utilization_percent(project), Decimal.new("40.0"))
  end

  test "create_project rejects an unknown sector" do
    assert {:error, changeset} =
             Procurement.create_project(%{
               name: "Invalid Sector Project",
               sector: "space",
               approved_budget: Decimal.new("10000")
             })

    assert "is invalid" in errors_on(changeset).sector
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
