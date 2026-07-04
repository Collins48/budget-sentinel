defmodule BudgetSentinel.Repo.Migrations.CreateAuditReports do
  use Ecto.Migration

  def change do
    create table(:audit_reports) do
      add :anomaly_id, references(:anomalies, on_delete: :delete_all), null: false
      add :summary, :text, null: false
      add :severity_assessment, :text
      add :recommended_actions, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:audit_reports, [:anomaly_id])
  end
end
