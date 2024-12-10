defmodule MySuperAppWeb.PictureController do
  use MySuperAppWeb, :controller

  alias MySuperApp.Blog
  alias MySuperApp.Picture

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"from" => from, "to" => to}) do
    with {:ok, from_datetime, _} <- DateTime.from_iso8601(from),
         {:ok, to_datetime, _} <- DateTime.from_iso8601(to) do
      pictures = Blog.list_pictures_in_period(from_datetime, to_datetime)
      render(conn, :index, pictures: pictures)
    else
      _ ->
        {:error, :check_params}
    end
  end

  def index(conn, %{"order" => order, "key" => key}) do
    valid_keys = [:file_name, :path, :post_id, :id, :inserted_at, :updated_at]

    valid_orders = ["asc", "desc"]

    key_atom = String.to_existing_atom(key)

    if key_atom in valid_keys and order in valid_orders do
      pictures = Blog.sort_pictures(String.trim(order, "\""), key_atom)

      render(conn, :index, pictures: pictures)
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid sorting key or order"})
    end
  end

  def index(conn, %{"post_id" => post_id}) do
    pictures = Blog.list_pictures_by_post(post_id)
    render(conn, :index, pictures: pictures)
  end

  def index(conn, %{"author" => author}) do
    pictures = Blog.list_pictures_by_author(author)
    render(conn, :index, pictures: pictures)
  end

  def index(conn, %{"email" => email}) do
    pictures = Blog.list_pictures_by_email(email)
    render(conn, :index, pictures: pictures)
  end

  def index(conn, _params) do
    pictures = Blog.list_pictures()
    render(conn, :index, pictures: pictures)
  end

  def create(conn, %{
        "file" => %Plug.Upload{path: file_path, filename: file_name},
        "post_id" => post_id
      }) do
    with {:ok, %Picture{} = picture} <-
           Blog.api_create_picture(%{path: file_path, file_name: file_name, post_id: post_id}) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/pictures/#{picture}")
      |> render(:show_pic, picture: picture)
    end
  end

  def create(conn, %{"file" => %Plug.Upload{path: file_path, filename: file_name}}) do
    with {:ok, %Picture{} = picture} <-
           Blog.api_create_picture(%{path: file_path, file_name: file_name}) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/pictures/#{picture}")
      |> render(:show_pic, picture: picture)
    end
  end

  def create(_conn, _params) do
    {:error, :check_params}
  end

  def show(conn, %{"id" => id}) do
    picture = Blog.get_picture(id)

    if picture do
      render(conn, :show_pic, picture: picture)
    else
      {:error, :not_found}
    end
  end

  def update(conn, %{
        "id" => id,
        "file" => %Plug.Upload{path: file_path, filename: file_name},
        "post_id" => post_id
      }) do
    picture = Blog.get_picture!(id)

    case Blog.api_update_picture(picture, %{
           path: file_path,
           file_name: file_name,
           post_id: post_id
         }) do
      {:ok, %Picture{} = picture} ->
        render(conn, :show_pic, picture: picture)

      {:error, "invalid params"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid params"})
    end
  end

  def update(conn, %{"id" => id, "file" => %Plug.Upload{path: file_path, filename: file_name}}) do
    picture = Blog.get_picture!(id)

    case Blog.api_update_picture(picture, %{path: file_path, file_name: file_name}) do
      {:ok, %Picture{} = picture} ->
        render(conn, :show_pic, picture: picture)

      {:error, "invalid params"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid params"})
    end
  end

  def update(conn, %{"id" => id, "file_name" => file_name, "post_id" => post_id}) do
    picture = Blog.get_picture!(id)

    case Blog.api_update_picture(picture, %{file_name: file_name, post_id: post_id}) do
      {:ok, %Picture{} = picture} ->
        render(conn, :show_pic, picture: picture)

      {:error, "invalid params"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid params"})
    end
  end

  def update(conn, %{"id" => id, "file_name" => file_name}) do
    picture = Blog.get_picture!(id)

    case Blog.api_update_picture(picture, %{file_name: file_name}) do
      {:ok, %Picture{} = picture} ->
        render(conn, :show_pic, picture: picture)

      {:error, "invalid params"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid params"})
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid params"})
  end

  def delete(conn, %{"id" => id}) do
    case Blog.delete_picture(id) do
      {:ok, %Picture{} = picture} ->
        render(conn, :show_pic, picture: picture)

      _ ->
        {:error, :not_found}
    end
  end
end
