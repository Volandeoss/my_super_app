defmodule MySuperApp.LeftMenu do
  @moduledoc """
    schema for left_menu
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "left_menu" do
    field :title, :string
  end

  @doc false
  def changeset(left_menu, attrs) do
    left_menu
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
