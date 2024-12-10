defmodule MySuperAppWeb.PostController do
  use MySuperAppWeb, :controller

  alias MySuperApp.Blog
  alias MySuperApp.Post
  alias MySuperApp.Repo

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"tags" => post_params}) do
    posts = Blog.get_posts_by_tags_bit(post_params)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"created_at" => post_params}) do
    posts = Blog.get_posts_by_preload(:created_at, post_params)
    render(conn, :index, posts: posts)
  end

  def index(conn, _params) do
    posts = Blog.get_posts_by_preload()
    render(conn, :index, posts: posts)
  end

  def create(conn, %{"post" => post_params}) do
    tags = Map.get(post_params, "tags", [])

    post_params = Map.delete(post_params, "tags")

    case Blog.api_create_post_and_associate_tags(post_params, tags) do
      {:ok, %Post{} = post} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/posts/#{post}")
        |> render(:show, post: post)

      _ ->
        {:error, :check_params}
    end
  end

  def show(conn, %{"id" => id}) do
    case Blog.get_post_by_preload(id) do
      {:ok, post} ->
        render(conn, :show, post: post)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Blog.get_post(id)

    case post do
      nil ->
        {:error, :not_found}

      post ->
        with {:ok, %Post{} = post} <- Blog.update_post(post, post_params) do
          render(conn, :show, post: post |> Repo.preload([:user, :tags]))
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    with %Post{} = post <- Blog.get_post!(id),
         {:ok, {:ok, %Post{}}} <- Blog.delete_post(post) do
      render(conn, :deleted, post: "deleted")
    else
      # Handle case when `get_post!` raises an error
      _ -> {:error, :not_found}
    end
  end
end
