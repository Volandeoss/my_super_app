defmodule MySuperApp.Room do
  @moduledoc """
    schema for rooms
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :room_number, :integer
    many_to_many :phones, MySuperApp.Phone, join_through: "rooms_phones"
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:room_number])
    |> validate_required([:room_number])
    |> validate_number(:room_number, greater_than: 0)
  end
end
