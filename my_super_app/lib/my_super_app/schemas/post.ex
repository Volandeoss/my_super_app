defmodule MySuperApp.Post do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  # alias MySuperApp.Repo

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published_at, :utc_datetime
    has_one :picture, MySuperApp.Picture
    belongs_to :user, MySuperApp.User
    timestamps(type: :utc_datetime)

    many_to_many :tags, MySuperApp.Tag,
      join_through: "posts_tags",
      on_replace: :delete,
      on_delete: :delete_all
  end

  def changeset_user(post, attrs) do
    post
    |> cast(attrs, [:user_id])
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :user_id, :published_at])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 5, max: 30)
    |> validate_length(:body, min: 10)
  end
end
