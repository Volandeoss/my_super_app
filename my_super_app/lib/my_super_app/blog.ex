defmodule MySuperApp.Blog do
  @moduledoc """
  Context for posts and tags.
  """

  import Ecto.Query, warn: false
  alias MySuperApp.{Repo, User, Tag, Post, Picture}

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def subscribe() do
    Phoenix.PubSub.subscribe(MySuperApp.PubSub, "pictures")
  end

  def broadcast(message) do
    Phoenix.PubSub.broadcast(MySuperApp.PubSub, "pictures", message)
  end

  def list_posts do
    Repo.all(Post)
  end

  def list_tags() do
    Repo.all(
      from p in MySuperApp.Post,
        join: t in assoc(p, :tags),
        distinct: t.id,
        select: %{key: fragment("concat('#', ?)", t.title), value: t.id, disabled: false}
    )
  end

  def get_users_with_posts(posts) do
    posts
    |> Enum.map(fn post -> %{key: post.user.username, value: post.user_id} end)
    |> Enum.uniq_by(fn user -> {user.key, user.value} end)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """

  def create_picture(post_id, attrs) do
    picture =
      make_picture(post_id, attrs)

    {:ok, pic} =
      %Picture{}
      |> Picture.changeset(picture)
      |> Repo.insert()

    broadcast({:picture_created, pic})

    {:ok, pic}
  end

  def create_picture(attrs) do
    {:ok, pic} =
      %Picture{}
      |> Picture.changeset(attrs)
      |> Repo.insert()

    broadcast({:picture_created, pic})

    {:ok, pic}
  end

  def api_create_picture(attrs) do
    with false <- String.contains?(attrs.path, "res.cloudinary.com"),
         {:ok, upl} <- Cloudex.upload(attrs.path) do
      attrs =
        attrs |> Map.put(:path, upl.secure_url)

      {:ok, pic} =
        %Picture{}
        |> Picture.changeset(attrs)
        |> Repo.insert()

      broadcast({:picture_created, pic})

      {:ok, pic |> Repo.preload(post: [:user])}
    else
      true ->
        {:ok, pic} =
          %Picture{}
          |> Picture.changeset(attrs)
          |> Repo.insert()

        broadcast({:picture_created, pic})

        {:ok, pic |> Repo.preload(post: [:user])}

      _ ->
        {:error, "something went wrong"}
    end
  end

  def delete_picture(id) do
    pic =
      Picture
      |> Repo.get(id)

    if pic do
      Cloudex.delete(Regex.run(~r/\/([a-zA-Z0-9]+)\.(png|jpg|jpeg)$/, pic.path))
      {:ok, pic} = Repo.delete(pic)
      broadcast({:picture_deleted, pic})
      {:ok, pic |> Repo.preload(post: [:user])}
    else
      {:ok, pic}
    end
  end

  def delete_all_pictures() do
    Repo.all(
      from(p in Picture,
        select: p.file_name
      )
    )
    |> get_names()
    |> delete_all_from_cloud()

    Repo.delete_all(Picture)
  end

  defp get_names(list_images) do
    list_images
    |> Enum.map(fn x ->
      x
      |> String.split(".")
      |> hd()
    end)
  end

  defp delete_all_from_cloud(names) do
    names
    |> Enum.map(fn x ->
      Cloudex.delete(x)
    end)
  end

  defp make_picture(post_id, url) do
    file_name =
      url
      |> String.split("/")
      |> List.last()

    %{path: url, file_name: file_name, post_id: post_id}
  end

  def get_pictures() do
    Repo.all(
      from pic in Picture,
        left_join: p in Post,
        on: pic.post_id == p.id,
        select: %{
          id: pic.id,
          file_name: pic.file_name,
          path: pic.path,
          published_at: pic.inserted_at,
          post_id: pic.post_id,
          post: %{
            id: p.id,
            title: p.title
          }
        }
    )
  end

  def get_pictures([{key, value}], filter, selected_ext) do
    order = value |> String.downcase() |> String.to_atom()

    query =
      from pic in Picture,
        left_join: p in Post,
        on: pic.post_id == p.id,
        left_join: u in User,
        on: p.user_id == u.id,
        order_by: [{^order, field(pic, ^key)}],
        select: %{
          id: pic.id,
          file_name: pic.file_name,
          path: pic.path,
          published_at: pic.inserted_at,
          post_id: pic.post_id,
          post: %{
            id: p.id,
            title: p.title
          }
        }

    query
    |> apply_filter_pic(filter, selected_ext)
    |> Repo.all()
  end

  def get_pictures(limit, offset, [{key, value}], filter, selected_ext) do
    order = value |> String.downcase() |> String.to_atom()

    query =
      from pic in Picture,
        left_join: p in Post,
        on: pic.post_id == p.id,
        left_join: u in User,
        on: p.user_id == u.id,
        offset: ^offset,
        limit: ^limit,
        order_by: [{^order, field(pic, ^key)}],
        select: %{
          id: pic.id,
          file_name: pic.file_name,
          path: pic.path,
          published_at: pic.inserted_at,
          post_id: pic.post_id,
          user: %{
            username: u.username,
            email: u.email
          },
          post: %{
            id: p.id,
            title: p.title
          }
        }

    query
    |> apply_filter_pic(filter, selected_ext)
    |> Repo.all()
  end

  defp apply_filter_pic(query, filter, "") do
    if numeric?(filter) do
      from [pic, p] in query, where: pic.id == ^filter
    else
      from [pic, p, u] in query,
        where:
          ilike(p.title, ^"%#{filter}%") or ilike(u.username, ^"%#{filter}%") or
            ilike(pic.file_name, ^"%#{filter}%") or ilike(u.email, ^"%#{filter}%")
    end
  end

  defp apply_filter_pic(query, filter, selected_ext) do
    if numeric?(filter) do
      from [pic, p] in query, where: pic.id == ^filter
    else
      from [pic, p, u] in query,
        where:
          (ilike(p.title, ^"%#{filter}%") or ilike(pic.file_name, ^"%#{filter}%") or
             ilike(u.email, ^"%#{filter}%") or
             ilike(u.username, ^"%#{filter}%")) and ilike(pic.file_name, ^"%#{selected_ext}")
    end
  end

  def numeric?(string) do
    String.match?(string, ~r/^\d+$/)
  end

  # defp find_by_id(query, filter) do
  #   if numeric?(filter) do
  #     from [pic, p] in query, where: pic.id == ^filter
  #   else
  #     query
  #   end
  # end

  def posts_without_pic() do
    from(p in Post,
      left_join: pic in assoc(p, :picture),
      where: is_nil(pic.id),
      select: %{
        key: p.title,
        value: p.id,
        disabled: false
      }
    )
    |> Repo.all()
  end

  def validate_picture([], nil) do
    %Picture{}
    |> Picture.changeset_file_name(%{})
  end

  def validate_picture([], post_id) do
    %Picture{}
    |> Picture.changeset_file_name(%{post_id: post_id})
  end

  def validate_picture(entry, post_id) do
    [image] = entry

    {:ok, file_name} =
      image
      |> Map.from_struct()
      |> Map.fetch(:client_name)

    %Picture{}
    |> Picture.changeset_file_name(%{file_name: file_name, post_id: post_id})
    |> Map.put(:action, :insert)
  end

  def validate_picture(entry) do
    [image] = entry

    pic_map =
      image |> Map.from_struct()

    {:ok, file_name} =
      pic_map
      |> Map.fetch(:client_name)

    %Picture{}
    |> Picture.changeset(%{file_name: file_name, path: file_name})
    |> Map.put(:action, :insert)
  end

  def validate_link(post_id) do
    %Picture{}
    |> Picture.changeset_link(%{post_id: post_id})
    |> Map.put(:action, :insert)
  end

  def validate_upd_picture([image], post_id) do
    {:ok, file_name} =
      image
      |> Map.from_struct()
      |> Map.fetch(:client_name)

    %Picture{}
    |> Picture.changeset_ext(%{file_name: file_name, post_id: post_id})
    |> Map.put(:action, :insert)
  end

  def validate_upd_picture([], post_id) do
    %Picture{}
    |> Picture.changeset_ext(%{post_id: post_id})
    |> Map.put(:action, :insert)
  end

  def validate_upd_picture([image]) do
    {:ok, file_name} =
      image
      |> Map.from_struct()
      |> Map.fetch(:client_name)

    %Picture{}
    |> Picture.changeset_upd(%{file_name: file_name})
    |> Map.put(:action, :insert)
  end

  def get_post_with_pic(id) do
    query =
      from pic in Picture,
        where: pic.id == ^id,
        preload: [post: [:user, :tags]]

    picture = Repo.one(query)

    if picture.post do
      %{
        id: picture.id,
        file_name: picture.file_name,
        path: picture.path,
        published_at: picture.inserted_at,
        post_id: picture.post_id,
        post: %{
          id: picture.post.id,
          title: picture.post.title,
          body: picture.post.body,
          tags: Enum.map(picture.post.tags, &Map.from_struct/1),
          user: %{
            username: picture.post.user.username,
            email: picture.post.user.email
          }
        }
      }
    else
      %{
        id: picture.id,
        file_name: picture.file_name,
        path: picture.path,
        published_at: picture.inserted_at,
        post_id: picture.post_id
      }
    end
  end

  def get_post_by_preload(id) do
    case Repo.get(Post, id) do
      nil ->
        {:error, :not_found}

      %Post{} = post ->
        {:ok,
         post
         |> Repo.preload([:tags, :user])
         |> transform_post()}
    end
  end

  def get_post(id) do
    Repo.get(Post, id)
  end

  def get_post!(id) do
    Repo.get!(Post, id)
  end

  defp transform_post(post) do
    tags_as_maps = Enum.map(post.tags, &transform_tag/1)
    post_as_map = Map.from_struct(post)
    user_as_map = Map.from_struct(post.user)

    Map.put(post_as_map, :tags, tags_as_maps)
    |> Map.put(:user, user_as_map)
  end

  defp transform_tag(tag) do
    %{
      title: tag.title
    }
  end

  def get_tags_by_ids(ids) do
    for id <- ids do
      Repo.get(Tag, id)
      |> Map.from_struct()
    end
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def get_posts_by_preload() do
    Post
    |> Repo.all()
    |> Repo.preload([:tags, :user])
    |> Enum.map(fn post ->
      tags_as_maps = Enum.map(post.tags, &Map.from_struct/1)
      %{Map.from_struct(post) | tags: tags_as_maps}
    end)
  end

  def decode_from_bit_to_string(json_tags) do
    case Jason.decode(json_tags) do
      {:ok, tag_titles} when is_list(tag_titles) ->
        # Ensure all elements are strings and downcase them
        tag_titles
        |> Enum.map(&String.downcase/1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_posts_by_tags_bit(json_tags) do
    # Parse the JSON string into a list of strings
    case Jason.decode(json_tags) do
      {:ok, tag_titles} when is_list(tag_titles) ->
        # Ensure all elements are strings and downcase them
        tag_titles
        |> Enum.map(&String.downcase/1)
        |> get_posts_by_tags()

      {:error, _reason} ->
        # Handle JSON parsing error
        []
    end
  end

  def get_posts_by_tags(tag_titles) do
    Post
    |> Repo.all()
    |> Repo.preload([:tags, :user])
    |> Enum.filter(fn post ->
      post_tag_titles = Enum.map(post.tags, &String.downcase(&1.title))
      Enum.all?(tag_titles, fn tag_title -> tag_title in post_tag_titles end)
    end)
    |> Enum.map(fn post ->
      tags_as_maps = Enum.map(post.tags, &Map.from_struct/1)
      %{Map.from_struct(post) | tags: tags_as_maps}
    end)
  end

  def get_posts_by_preload(:created_at, created_at) do
    Post
    |> where([p], p.inserted_at == ^created_at)
    |> Repo.all()
    |> Repo.preload([:tags, :user])
    |> Enum.map(fn post ->
      tags_as_maps = Enum.map(post.tags, &Map.from_struct/1)
      %{Map.from_struct(post) | tags: tags_as_maps}
    end)
  end

  def get_posts_by_preload(
        filters \\ "",
        [{key, value}],
        offset,
        limit,
        selected_user_id,
        selected_tag_id,
        kind_of_post
      ) do
    order = value |> String.downcase() |> String.to_atom()

    Post
    |> apply_filter(filters)
    |> maybe_by_publish(kind_of_post)
    |> maybe_filter_by_user(selected_user_id)
    |> maybe_filter_by_tag(selected_tag_id)
    |> dynamic_order_by(key, order)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:tags, :user])
    |> Enum.map(fn post ->
      tags_as_maps = Enum.map(post.tags, &Map.from_struct/1)
      %{Map.from_struct(post) | tags: tags_as_maps}
    end)
  end

  defp maybe_filter_by_tag(query, "0"), do: query

  defp maybe_filter_by_tag(query, tag) do
    from p in query,
      join: t in assoc(p, :tags),
      where: t.id == ^tag
  end

  def get_posts_by_preload(filters \\ "", [{key, value}], selected_user_id, tag, kind_of_post) do
    order = value |> String.downcase() |> String.to_atom()

    Post
    |> apply_filter(filters)
    |> maybe_by_publish(kind_of_post)
    |> maybe_filter_by_user(selected_user_id)
    |> maybe_filter_by_tag(tag)
    |> dynamic_order_by(key, order)
    |> Repo.all()
    |> Repo.preload([:tags, :user])
    |> Enum.map(fn post ->
      tags_as_maps = Enum.map(post.tags, &Map.from_struct/1)
      %{Map.from_struct(post) | tags: tags_as_maps}
    end)
  end

  defp maybe_by_publish(query, kind_of_post) do
    case kind_of_post do
      1 -> query
      2 -> from(p in query, where: is_nil(p.published_at) == true)
      3 -> from(p in query, where: is_nil(p.published_at) == false)
    end
  end

  defp maybe_filter_by_user(query, "0"), do: query

  defp maybe_filter_by_user(query, selected_user_id) do
    from(p in query, where: p.user_id == ^selected_user_id)
  end

  defp apply_filter(query, filter) do
    if String.trim(filter) == "" do
      query
    else
      case Integer.parse(filter) do
        {id, ""} -> from(p in query, where: p.id == ^id)
        _ -> from(p in query, where: ilike(p.title, ^"%#{filter}%"))
      end
    end
  end

  defp dynamic_order_by(query, key, order) do
    from(q in query, order_by: [{^order, field(q, ^key)}])
  end

  def create_post_and_associate_tags(post_attrs, tag_attrs_list) do
    case create_post(post_attrs) do
      {:ok, post} ->
        assoc_tags(tag_attrs_list, post)

      {:error, error} ->
        {:error, error}
    end
  end

  def api_create_post_and_associate_tags(post_attrs, tag_attrs_list) do
    # Step 1: Create the Post
    tag_attrs_list = convert_tags(tag_attrs_list)

    case create_post(post_attrs) do
      {:ok, post} ->
        assoc_tags(tag_attrs_list, post)

      # Step 3: Associate the Post with the Tags
      {:error, error} ->
        {:error, error}
    end

    # Step 2: Find or Create Tags
  end

  def get_tags() do
    Tag
    |> Repo.all()
  end

  def convert_tags(tags) do
    Enum.map(tags, fn
      %{"title" => _v} = tag ->
        Enum.into(tag, %{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
    end)
  end

  # def check_tags(tag_attrs_list) do
  #   Enum.map(tag_attrs_list, fn(tag)->%{titles: _some} = tag end)
  # end

  def assoc_tags(tag_attrs_list, post) do
    tag_ids =
      Enum.map(tag_attrs_list, fn tag_attrs ->
        tag_title = tag_attrs[:title]

        # Check if the tag already exists
        tag = Repo.get_by(Tag, title: tag_title)

        check_or_create_tag(tag, tag_attrs)
      end)

    associate_post_with_tags(post, tag_ids)
  end

  def associate_post_with_tags(post, tag_ids) do
    post = post |> Repo.preload([:tags, :user])
    tags = Repo.all(from t in Tag, where: t.id in ^tag_ids)

    post
    |> Post.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  def check_or_create_tag(tag, tag_attrs) do
    if tag do
      tag.id
    else
      {:ok, new_tag} = create_tag(tag_attrs)
      new_tag.id
    end
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def update_published_at(:publish, id) do
    Repo.get(Post, id)
    |> Post.changeset(%{published_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def update_published_at(:unpublish, id) do
    Repo.get(Post, id)
    |> Post.changeset(%{published_at: nil})
    |> Repo.update()
  end

  def update_post(%Post{} = post, attrs) do
    tags_params = Map.get(attrs, "tags", [])
    tags = get_or_create_tags(tags_params)

    post_params = Map.take(attrs, ["title", "body", "user_id"])

    post
    |> Repo.preload(:tags)
    |> Post.changeset(post_params)
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  defp get_or_create_tags(tags_params) do
    tags_params
    |> Enum.map(&find_or_create_tag(&1))
  end

  defp find_or_create_tag(%{"title" => name}) do
    case Repo.get_by(Tag, title: name) do
      nil ->
        %Tag{}
        |> Tag.changeset(%{title: name})
        |> Repo.insert!()

      tag ->
        tag
    end
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """

  def delete_post(%Post{} = post) do
    Repo.transaction(fn ->
      Repo.delete_all(from pt in "posts_tags", where: pt.post_id == ^post.id)

      Repo.delete(post)
    end)
  end

  def delete_all_posts() do
    Repo.delete_all(from(pt in "posts_tags"))
    Repo.delete_all(Post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def get_ext do
    Repo.all(
      from pic in Picture,
        select: %{
          key: fragment("substring(?, '\\.[^.]*$')", pic.file_name),
          value: fragment("substring(?, '\\.[^.]*$')", pic.file_name),
          disabled: false
        },
        distinct: true
    )
  end

  @doc """
  Returns the list of pictures.

  ## Examples

      iex> list_pictures()
      [%Picture{}, ...]

  """
  def list_pictures do
    Repo.all(Picture) |> Repo.preload([:post, post: [:user]])
  end

  def list_pictures_in_period(from_datetime, to_datetime) do
    from(p in Picture,
      where: p.inserted_at >= ^from_datetime and p.inserted_at <= ^to_datetime
    )
    |> Repo.all()
    |> Repo.preload([:post, post: [:user]])
  end

  def list_pictures_by_post(post_id) do
    from(p in Picture,
      where: p.post_id == ^post_id
    )
    |> Repo.all()
    |> Repo.preload([:post, post: [:user]])
  end

  def list_pictures_by_author(author) do
    from(pic in Picture,
      join: p in Post,
      on: pic.post_id == p.id,
      join: u in User,
      on: p.user_id == u.id,
      where: u.username == ^author
    )
    |> Repo.all()
    |> Repo.preload([:post, post: [:user]])
  end

  def list_pictures_by_email(email) do
    from(pic in Picture,
      join: p in Post,
      on: pic.post_id == p.id,
      join: u in User,
      on: p.user_id == u.id,
      where: u.email == ^email
    )
    |> Repo.all()
    |> Repo.preload([:post, post: [:user]])
  end

  def sort_pictures(order, key) do
    order = order |> String.downcase() |> String.to_atom()

    from(p in Picture,
      order_by: [{^order, field(p, ^key)}]
    )
    |> Repo.all()
    |> Repo.preload([:post, post: [:user]])
  end

  @doc """
  Gets a single picture.

  Raises `Ecto.NoResultsError` if the Picture does not exist.

  ## Examples

      iex> get_picture!(123)
      %Picture{}

      iex> get_picture!(456)
      ** (Ecto.NoResultsError)

  """
  def get_picture!(id), do: Repo.get!(Picture, id)

  def get_picture(id) do
    Repo.get(Picture, id) |> Repo.preload(post: [:user])
  end

  @doc """
  Updates a picture.

  ## Examples

      iex> update_picture(picture, %{field: new_value})
      {:ok, %Picture{}}

      iex> update_picture(picture, %{field: bad_value})
      {:error, %Ecto.Changeset{}}


  """

  def api_update_picture(%Picture{} = picture, %{file_name: _file_name} = attrs) do
    with {:check, %{valid?: true}} <- {:check, picture |> Picture.changeset_ext(attrs)},
         {:path, true} <- {:path, Map.take(attrs, [:path]) != %{}},
         {:ok, _} <- delete_from_cloud(picture.path),
         {:ok, upl} <- Cloudex.upload(attrs.path),
         {:change, %{valid?: true} = pic} <-
           {:change, picture |> Picture.changeset_ext(attrs |> Map.put(:path, upl.secure_url))} do
      {:ok, picture} = Repo.update(pic)
      broadcast({:picture_updated, picture})
      {:ok, picture |> Repo.preload([:post, post: [:user]])}
    else
      {:change, %{valid?: false}} ->
        {:error, "invalid params"}

      {:check, %{valid?: false}} ->
        {:error, "invalid params"}

      {:path, false} ->
        {:ok, picture} =
          picture
          |> Picture.changeset_ext(attrs)
          |> Repo.update()

        broadcast({:picture_updated, picture})
        {:ok, picture |> Repo.preload([:post, post: [:user]])}
    end
  end

  def api_update_picture(%Picture{} = picture, attrs) do
    with {:check, %{valid?: true}} <- {:check, picture |> Picture.changeset(attrs)},
         {:path, true} <- {:path, Map.take(attrs, [:path]) != %{}},
         {:ok, _} <- delete_from_cloud(picture.path),
         {:ok, upl} <- Cloudex.upload(attrs.path),
         {:change, %{valid?: true} = pic} <-
           {:change, picture |> Picture.changeset(attrs |> Map.put(:path, upl.secure_url))} do
      {:ok, picture} = Repo.update(pic)
      broadcast({:picture_updated, picture})
      {:ok, picture |> Repo.preload([:post, post: [:user]])}
    else
      {:change, %{valid?: false}} ->
        {:error, "invalid params"}

      {:check, %{valid?: false}} ->
        {:error, "invalid params"}

      {:path, false} ->
        {:ok, picture} =
          picture
          |> Picture.changeset(attrs)
          |> Repo.update()

        broadcast({:picture_updated, picture})
        {:ok, picture |> Repo.preload([:post, post: [:user]])}
    end
  end

  def update_picture(%Picture{} = picture, attrs) do
    Cloudex.delete(get_public_id(picture.path))

    picture
    |> Picture.changeset(attrs)
    |> Repo.update()

    broadcast({:picture_updated, picture})
    {:ok, picture}
  end

  def update_picture_link(%Picture{} = picture, attrs) do
    picture
    |> Picture.changeset_link(attrs)
    |> Repo.update()

    broadcast({:picture_updated, picture})
    {:ok, picture}
  end

  @doc """
  Deletes a picture.

  ## Examples

      iex> delete_picture(picture)
      {:ok, %Picture{}}

      iex> delete_picture(picture)
      {:error, %Ecto.Changeset{}}

  """
  def api_delete_picture(id) do
    with {:ok, pic} <- Repo.get(Picture, id),
         {:ok, _} <- Repo.delete(pic) do
      broadcast({:picture_deleted, pic})
      {:ok, pic}
    else
      _ -> :not_found
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking picture changes.

  ## Examples

      iex> change_picture(picture)
      %Ecto.Changeset{data: %Picture{}}

  """
  def change_picture(%Picture{} = picture, attrs \\ %{}) do
    Picture.changeset(picture, attrs)
  end

  defp get_public_id(path) do
    String.split(path, "/")
    |> List.last()
    |> String.split(".")
    |> hd()
  end

  defp delete_from_cloud(path) do
    path
    |> get_public_id()
    |> Cloudex.delete()
  end

  def create_until_success({:ok, site}) do
    {:ok, site}
  end

  def create_until_success({:error, _}) do
    create_until_success(
      MySuperApp.CasinoSites.create_site(%{
        brand: Faker.Company.En.bullshit(),
        status: false,
        operator_id: :rand.uniform(4)
      })
    )
  end
end
