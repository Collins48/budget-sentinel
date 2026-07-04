defmodule BudgetSentinel.Audit.AuditReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_reports" do
    field :summary, :string
    field :severity_assessment, :string
    field :recommended_actions, :string

    belongs_to :anomaly, BudgetSentinel.Audit.Anomaly

    timestamps(type: :utc_datetime)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [:summary, :severity_assessment, :recommended_actions, :anomaly_id])
    |> validate_required([:summary, :anomaly_id])
    |> foreign_key_constraint(:anomaly_id)
  end
end
