defmodule MySuperApp.Picture do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "pictures" do
    field :file_name, :string
    field :path, :string
    belongs_to :post, MySuperApp.Post
    timestamps(type: :utc_datetime)
  end

  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [:file_name, :path, :post_id])
    |> validate_required([:file_name, :path])
    |> validate_ext()
  end

  defp validate_ext(changeset) do
    file_name = get_field(changeset, :file_name)
    name = if file_name == nil, do: "", else: file_name

    case String.ends_with?(name, [".png", ".jpg", "jpeg"]) do
      true -> changeset
      false -> add_error(changeset, file_name, "bad_extension")
    end
  end

  def changeset_file_name(picture, attrs) do
    picture
    |> cast(attrs, [:file_name, :post_id])
    |> validate_ext()
  end

  def changeset_ext(picture, attrs) do
    picture
    |> cast(attrs, [:file_name, :post_id])
    |> validate_ext()
  end

  def changeset_link(picture, attrs) do
    picture
    |> cast(attrs, [:post_id])
    |> validate_required([:post_id])
  end

  def changeset_upd(picture, attrs) do
    picture
    |> cast(attrs, [:file_name])
  end
end
