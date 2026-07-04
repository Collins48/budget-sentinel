defmodule BudgetSentinel.Repo.Migrations.AddMinistriesAndRoles do
  use Ecto.Migration

  def change do
    create table(:ministries) do
      add :name, :string, null: false
      add :code, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ministries, [:code])

    alter table(:users) do
      add :role, :string, null: false, default: "oversight_officer"
      add :ministry_id, references(:ministries, on_delete: :nilify_all)
    end

    create index(:users, [:ministry_id])

    alter table(:projects) do
      add :ministry_id, references(:ministries, on_delete: :nilify_all)
    end

    create index(:projects, [:ministry_id])
  end
end
