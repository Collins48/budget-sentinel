defmodule BudgetSentinel.Repo.Migrations.CreateAnomalies do
  use Ecto.Migration

  def change do
    create table(:anomalies) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :expenditure_id, references(:expenditures, on_delete: :delete_all), null: false
      add :fraud_type, :string, null: false
      add :risk_score, :decimal, precision: 5, scale: 2, null: false
      add :severity, :string, null: false
      add :anomaly_score, :decimal, precision: 6, scale: 4
      add :explanation, :text
      add :detected_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:anomalies, [:project_id])
    create index(:anomalies, [:expenditure_id])
    create index(:anomalies, [:severity])
    create index(:anomalies, [:detected_at])
  end
end
