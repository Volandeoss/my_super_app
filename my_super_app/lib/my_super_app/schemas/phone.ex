defmodule MySuperApp.Phone do
  @moduledoc """
    schema for phone
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "phones" do
    field :phone_number, :string

    many_to_many :rooms, MySuperApp.Room, join_through: "rooms_phones"
  end

  @doc false
  def changeset(phone, attrs) do
    phone
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
    |> validate_length(:phone_number, min: 10, max: 12)
  end
end
