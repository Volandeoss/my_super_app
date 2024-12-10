defmodule MySuperApp.Site do
  @moduledoc """
  schema for sites
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "sites" do
    timestamps(type: :utc_datetime)
    field :brand, :string
    field :status, :boolean, default: false
    belongs_to :operator, MySuperApp.Operator
  end

  def changeset_time(site, attrs) do
    site
    |> cast(attrs, [:inserted_at, :updated_at])
  end

  def changeset(site, attrs) do
    site
    |> cast(attrs, [:brand, :status, :operator_id])
    |> validate_required([:brand, :status, :operator_id])
    |> unique_constraint([:brand])
  end
end
