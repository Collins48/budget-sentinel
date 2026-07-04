defmodule BudgetSentinel.Audit.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending sent failed)

  schema "alerts" do
    field :recipient, :string
    field :status, :string, default: "pending"
    field :dispatched_at, :utc_datetime

    belongs_to :anomaly, BudgetSentinel.Audit.Anomaly

    timestamps(type: :utc_datetime)
  end

  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:recipient, :status, :dispatched_at, :anomaly_id])
    |> validate_required([:recipient, :status, :anomaly_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:anomaly_id)
  end
end
