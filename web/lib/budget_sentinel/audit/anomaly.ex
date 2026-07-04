defmodule BudgetSentinel.Audit.Anomaly do
  use Ecto.Schema
  import Ecto.Changeset

  @fraud_types ~w(budget_overrun duplicate_payment ghost_project inflated_contract premature_payment unclassified_anomaly)
  @severities ~w(low medium high)
  @statuses ~w(open under_review resolved dismissed)

  schema "anomalies" do
    field :fraud_type, :string
    field :risk_score, :decimal
    field :severity, :string
    field :anomaly_score, :decimal
    field :explanation, :string
    field :detected_at, :utc_datetime
    field :status, :string, default: "open"
    field :resolution_notes, :string
    field :reviewed_at, :utc_datetime

    belongs_to :project, BudgetSentinel.Procurement.Project
    belongs_to :expenditure, BudgetSentinel.Procurement.Expenditure
    belongs_to :reviewed_by, BudgetSentinel.Accounts.User
    has_one :audit_report, BudgetSentinel.Audit.AuditReport
    has_many :alerts, BudgetSentinel.Audit.Alert

    timestamps(type: :utc_datetime)
  end

  def changeset(anomaly, attrs) do
    anomaly
    |> cast(attrs, [
      :fraud_type,
      :risk_score,
      :severity,
      :anomaly_score,
      :explanation,
      :detected_at,
      :status,
      :project_id,
      :expenditure_id
    ])
    |> validate_required([:fraud_type, :risk_score, :severity, :status, :project_id, :expenditure_id])
    |> validate_inclusion(:fraud_type, @fraud_types)
    |> validate_inclusion(:severity, @severities)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:risk_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:expenditure_id)
  end

  @doc "Changeset for an auditor/admin actioning an anomaly: status, notes, and who/when reviewed it."
  def status_changeset(anomaly, attrs) do
    anomaly
    |> cast(attrs, [:status, :resolution_notes, :reviewed_by_id, :reviewed_at])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:reviewed_by_id)
  end

  def fraud_types, do: @fraud_types
  def severities, do: @severities
  def statuses, do: @statuses
end
