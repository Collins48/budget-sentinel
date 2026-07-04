defmodule BudgetSentinel.Repo.Migrations.AddAnomalyStatusWorkflow do
  use Ecto.Migration

  def change do
    alter table(:anomalies) do
      add :status, :string, null: false, default: "open"
      add :resolution_notes, :text
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)
      add :reviewed_at, :utc_datetime
    end

    create index(:anomalies, [:status])
  end
end
