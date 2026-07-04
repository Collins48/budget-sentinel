defmodule BudgetSentinel.Procurement.Expenditure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenditures" do
    field :contractor, :string
    field :amount, :decimal
    field :milestone, :string
    field :paid_on, :date

    belongs_to :project, BudgetSentinel.Procurement.Project
    has_many :anomalies, BudgetSentinel.Audit.Anomaly

    timestamps(type: :utc_datetime)
  end

  def changeset(expenditure, attrs) do
    expenditure
    |> cast(attrs, [:contractor, :amount, :milestone, :paid_on, :project_id])
    |> validate_required([:contractor, :amount, :milestone, :paid_on, :project_id])
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:project_id)
  end
end
