defmodule BudgetSentinel.Repo.Migrations.AddInviteFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :hashed_password, :string, null: true
      add :invited_at, :utc_datetime
      add :invited_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:users, [:invited_by_id])
  end
end
