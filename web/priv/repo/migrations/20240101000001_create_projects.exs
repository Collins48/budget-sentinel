defmodule BudgetSentinel.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :sector, :string, null: false
      add :approved_budget, :decimal, precision: 14, scale: 2, null: false
      add :market_benchmark, :decimal, precision: 14, scale: 2
      add :completion_rate, :decimal, precision: 5, scale: 1, null: false, default: 0
      add :milestones, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:sector])
  end
end
