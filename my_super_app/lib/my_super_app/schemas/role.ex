defmodule MySuperApp.Role do
  @moduledoc """
    schema for roles
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias MySuperApp.Operator
  alias MySuperApp.Repo

  schema "roles" do
    field :name, :string
    belongs_to :operator, MySuperApp.Operator
    has_many :users, MySuperApp.User, on_delete: :nilify_all
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :operator_id])
    |> validate_required([:name, :operator_id])
  end

  def changeset_for_role(role, attrs) do
    role
    |> cast(attrs, [:role_id])
    |> validate_required([:role_id])
  end

  def changeset_for_operator(role, attrs) do
    role
    |> cast(attrs, [:operator_id])
    |> validate_required([:operator_id])
  end

  def delete_role(id) do
    Role
    |> Repo.get(id)
    |> Repo.delete()
  end

  def drop_changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :id])
  end

  def maybe_put_assoc(changeset, attrs) do
    case Map.fetch(attrs, :operator_id) do
      {:ok, id} -> put_assoc(changeset, :operator, Repo.get(Operator, id))
      :error -> changeset
    end
  end
end
