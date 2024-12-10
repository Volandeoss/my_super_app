defmodule MySuperApp.Person do
  @moduledoc """
   Schema for person
  """
  alias Ecto.Changeset
  use Ecto.Schema
  import Changeset

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end

  def changeset(person, params) do
    person
    |> cast(params, [:name, :age])
    |> validate_required([:name])
    |> validate_length(:name, min: 2)
  end
end
