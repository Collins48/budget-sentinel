defmodule BudgetSentinel.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias BudgetSentinel.Repo
      import Ecto
      import Ecto.Query
      import BudgetSentinel.DataCase
    end
  end

  setup tags do
    BudgetSentinel.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(BudgetSentinel.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
