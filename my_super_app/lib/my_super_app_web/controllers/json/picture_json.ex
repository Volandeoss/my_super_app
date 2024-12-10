defmodule MySuperAppWeb.PictureJSON do
  alias MySuperApp.Picture

  @doc """
  Renders a list of pictures.
  """
  def index(%{pictures: pictures}) do
    %{data: for(picture <- pictures, do: data(picture))}
  end

  def index(%{pictures_author: pictures}) do
    %{data: for(picture <- pictures, do: data(picture))}
  end

  @doc """
  Renders a single picture.
  """
  def show_pic(%{picture: picture}) do
    %{data: data(picture)}
  end

  defp data(%Picture{} = picture) do
    if picture.post_id do
      %{
        id: picture.id,
        file_name: picture.file_name,
        path: picture.path,
        uploaded_at: picture.inserted_at,
        post_id: picture.post_id,
        user: picture.post.user.username,
        email: picture.post.user.email
      }
    else
      %{
        id: picture.id,
        file_name: picture.file_name,
        path: picture.path,
        uploaded_at: picture.inserted_at,
        post_id: picture.post_id
      }
    end
  end

  def data_with_user(%Picture{} = picture) do
    if picture.post_id do
      %{
        id: picture.id,
        file_name: picture.file_name,
        path: picture.path,
        uploaded_at: picture.inserted_at,
        post_id: picture.post_id,
        username: picture.post.user.username
      }
    else
      %{
        id: picture.id,
        file_name: picture.file_name,
        path: picture.path,
        uploaded_at: picture.inserted_at,
        post_id: picture.post_id
      }
    end
  end
end
