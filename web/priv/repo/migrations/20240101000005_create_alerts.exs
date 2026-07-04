defmodule BudgetSentinel.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :anomaly_id, references(:anomalies, on_delete: :delete_all), null: false
      add :recipient, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :dispatched_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:alerts, [:anomaly_id])
    create index(:alerts, [:status])
  end
end
