defmodule MySuperAppWeb.PostJSON do
  @doc """
  Renders a list of posts.
  """
  def index(%{posts: posts}) do
    %{data: for(post <- posts, do: data(post))}
  end

  def deleted(%{post: "deleted"}) do
    %{status: "deleted"}
  end

  @doc """
  Renders a single post.
  """
  def show(%{post: post}) do
    %{data: data(post)}
  end

  def get_tags(post_tags) do
    for(tag <- post_tags, do: %{title: tag.title})
  end

  defp data(post) do
    %{
      id: post.id,
      title: post.title,
      body: post.body,
      user_id: post.user_id,
      user: %{
        username: post.user.username,
        email: post.user.email
      },
      tags: get_tags(post.tags),
      created_at: post.inserted_at,
      updated_at: post.updated_at
    }
  end
end
