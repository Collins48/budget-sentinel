defmodule BudgetSentinel.Ministries do
  @moduledoc """
  Context for government ministries, used to scope projects and user access.
  """

  import Ecto.Query

  alias BudgetSentinel.Ministries.Ministry
  alias BudgetSentinel.Repo

  def list_ministries do
    Ministry
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def get_ministry!(id), do: Repo.get!(Ministry, id)

  def create_ministry(attrs) do
    %Ministry{}
    |> Ministry.changeset(attrs)
    |> Repo.insert()
  end
end
