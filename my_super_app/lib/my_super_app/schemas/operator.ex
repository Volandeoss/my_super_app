defmodule MySuperApp.Operator do
  @moduledoc """
   Schema for operator
  """
  use Ecto.Schema
  alias Ecto.Changeset
  import Changeset

  schema "operators" do
    field :name, :string
    has_many :users, MySuperApp.User
    has_many :roles, MySuperApp.Role
    has_many :sites, MySuperApp.Site
    timestamps(type: :utc_datetime)
  end

  def changeset(operator, params) do
    operator
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 4)
  end

  def changeset_for_operator(operator, attrs) do
    operator
    |> cast(attrs, [:operator_id])
    |> validate_required([:operator_id])
  end
end
