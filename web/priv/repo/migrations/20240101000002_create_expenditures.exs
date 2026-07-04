defmodule BudgetSentinel.Repo.Migrations.CreateExpenditures do
  use Ecto.Migration

  def change do
    create table(:expenditures) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :contractor, :string, null: false
      add :amount, :decimal, precision: 14, scale: 2, null: false
      add :milestone, :string, null: false
      add :paid_on, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:expenditures, [:project_id])
    create index(:expenditures, [:contractor])
  end
end
