defmodule BudgetSentinel.Ministries.Ministry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ministries" do
    field :name, :string
    field :code, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(ministry, attrs) do
    ministry
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
    |> unique_constraint(:code)
  end
end
