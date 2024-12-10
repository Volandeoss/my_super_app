defmodule MySuperApp.Tag do
  @moduledoc """
  Schema for Tag
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :title, :string

    many_to_many :posts, MySuperApp.Post, join_through: "posts_tags"

    timestamps(type: :utc_datetime)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> validate_length(:title, min: 3, max: 50)
  end

  def changeset_drop(tag, attrs) do
    tag
    |> cast(attrs, [:id])
  end
end
