defmodule BudgetSentinel.Repo do
  use Ecto.Repo,
    otp_app: :budget_sentinel,
    adapter: Ecto.Adapters.Postgres
end
