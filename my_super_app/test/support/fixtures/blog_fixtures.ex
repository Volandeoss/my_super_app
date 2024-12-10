defmodule MySuperApp.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.Blog` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some bodyyyyyyyyyyy",
        title: "some title",
        user_id: 4
      })
      |> MySuperApp.Blog.create_post()

    post
  end

  @doc """
  Generate a picture.
  """
  def picture_fixture(attrs \\ %{}) do
    {:ok, picture} =
      attrs
      |> Enum.into(%{
        file_name: "file_name.jpg",
        path: "some path/some_photo.jpg"
      })
      |> MySuperApp.Blog.create_picture()

    picture
  end
end
