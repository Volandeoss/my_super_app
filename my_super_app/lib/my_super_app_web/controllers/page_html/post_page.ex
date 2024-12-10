defmodule MySuperAppWeb.PostPage do
  @moduledoc false
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Components.{Button}
  alias MySuperApp.{Blog, Post, Tag}
  alias MySuperApp.Tag
  alias Moon.Design.{Modal, Chip, Form, Form.Field, Tabs, Dropdown, Form.Input}

  alias Moon.Design.Tooltip

  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  alias Moon.Design.Search

  alias Moon.Icons.TextHashtag
  alias Moon.Icons.ControlsPlus

  alias Moon.Design.Tag, as: MoonTag
  alias Moon.Design.{Table, Button, Button.IconButton}
  alias Moon.Design.Table.Column

  def mount(_, _, socket) do
    posts = Blog.get_posts_by_preload()

    {:ok,
     assign(socket,
       sort: [id: "ASC"],
       posts: posts,
       adding_tag: false,
       selected: 0,
       kind_of_post: 1,
       current:
         Blog.get_posts_by_preload(
           "",
           [id: "ASC"],
           0,
           8,
           "0",
           "0",
           1
         ),
       users: Blog.get_users_with_posts(posts),
       form: to_form(Post.changeset(%Post{}, %{})),
       form_tag: to_form(Tag.changeset(%Tag{}, %{})),
       editing?: false,
       filter: "",
       total_pages: max(page_count(length(posts), 8), 1),
       current_page: 1,
       selected_user_id: "0",
       limit: 8,
       tags_input: [],
       form_drop_user: to_form(Post.changeset_user(%Post{}, %{"user_id" => "0"})),
       post: %{title: "", user_id: "", user: %{username: ""}, body: "", tags: []},
       id: nil,
       form_drop_tags: to_form(Tag.changeset_drop(%Tag{}, %{"id" => "0"})),
       tags: Blog.list_tags(),
       selected_tag_id: "0"
     )}
  end

  def handle_event("set_open", %{"value" => ""}, socket) do
    Modal.open("big_content_modal")
    {:noreply, assign(socket, editing?: true)}
  end

  def handle_event("set_open", %{"value" => id}, socket) do
    post =
      Enum.find(socket.assigns.posts, fn post -> post.id == String.to_integer(id) end)

    Modal.open("big_content_modal")
    {:noreply, assign(socket, editing?: true, id: id, post: post)}
  end

  def handle_event("show_all_posts", _, socket) do
    socket = assign(socket, kind_of_post: 1)

    {:noreply,
     assign(socket, selected: 0, total_pages: total_pages(socket.assigns), current_page: 1)}
  end

  def handle_event("show_unpublished_posts", _, socket) do
    socket = assign(socket, kind_of_post: 2)

    {:noreply,
     assign(socket, selected: 1, total_pages: total_pages(socket.assigns), current_page: 1)}
  end

  def handle_event("show_published_posts", _, socket) do
    socket = assign(socket, kind_of_post: 3)

    {:noreply,
     assign(socket, selected: 2, total_pages: total_pages(socket.assigns), current_page: 1)}
  end

  def handle_event("unpublish", %{"value" => id}, socket) do
    Blog.update_published_at(:unpublish, id)
    total = total_pages(socket.assigns)

    {:noreply,
     assign(socket |> put_flash(:warn, "post has been unpublished"),
       current: get_models_10(socket.assigns),
       current_page:
         if(socket.assigns.current_page > total, do: total, else: socket.assigns.current_page),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("publish", %{"value" => id}, socket) do
    Blog.update_published_at(:publish, id)
    total = total_pages(socket.assigns)

    {:noreply,
     assign(socket |> put_flash(:info, "post has been published"),
       current: get_models_10(socket.assigns),
       current_page:
         if(socket.assigns.current_page > total, do: total, else: socket.assigns.current_page),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event(
        "on_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    {:noreply,
     assign(socket,
       current_page: 1,
       current:
         users_sorted_by(
           Blog.get_posts_by_preload(
             socket.assigns.filter,
             socket.assigns.sort,
             (socket.assigns.current_page - 1) * socket.assigns.limit,
             socket.assigns.limit,
             socket.assigns.selected_user_id,
             socket.assigns.selected_tag_id,
             socket.assigns.kind_of_post
           ),
           String.to_atom(sort_key),
           sort_dir
         ),
       sort: ["#{sort_key}": sort_dir],
       updated?: false
     )}
  end

  def handle_event("select_user", %{"post" => %{"user_id" => user_id} = user}, socket) do
    form =
      %Post{}
      |> Post.changeset_user(user)
      |> Map.put(:action, :insert)
      |> to_form()

    socket = assign(socket, selected_user_id: user_id, current_page: 1)

    {:noreply,
     assign(socket,
       form_drop_user: form,
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("select_tag", %{"tag" => %{"id" => tag_id} = params}, socket) do
    form =
      %Tag{}
      |> Tag.changeset_drop(params)
      |> Map.put(:action, :insert)
      |> to_form()

    socket = assign(socket, current_page: 1, selected_tag_id: tag_id)

    {:noreply,
     assign(socket,
       form_drop_tags: form,
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("delete", _, socket) do
    Modal.close("big_content_modal")

    post = Blog.get_post(socket.assigns.post.id)
    Blog.delete_post(post)

    total_pages = total_pages(socket.assigns)

    {:noreply,
     assign(socket |> put_flash(:info, "Post deleted"),
       editing?: false,
       tags: Blog.list_tags(),
       current_page:
         if(socket.assigns.current_page > total_pages,
           do: total_pages,
           else: socket.assigns.current_page
         ),
       current: get_models_10(socket.assigns),
       total_pages: total_pages,
       id: nil,
       post: %{title: "", user_id: "", user: %{username: ""}, body: "", tags: []}
     )}
  end

  def handle_event("validate", %{"post" => %{"body" => body, "title" => title} = params}, socket) do
    form =
      %Post{}
      |> Post.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply,
     assign(socket,
       form: form,
       post: %{title: title, body: body, user_id: "", user: %{username: ""}}
     )}
  end

  def handle_event("validate_tag", %{"tag" => params}, socket) do
    form =
      %Tag{}
      |> Tag.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply,
     assign(socket,
       form_tag: form
     )}
  end

  def handle_event("add_tag", %{"tag" => params}, socket) do
    %{"title" => title} = params

    change = Tag.changeset(%Tag{}, params)

    case change.valid? && %{title: params["title"]} not in socket.assigns.tags_input do
      true ->
        tags_input = [%{title: title |> String.downcase()} | socket.assigns.tags_input]

        {:noreply,
         assign(socket,
           tags_input: tags_input,
           adding_tag: !socket.assigns.adding_tag,
           form_tag: to_form(Tag.changeset(%Tag{}, %{}))
         )}

      false ->
        {:noreply,
         assign(socket |> put_flash(:error, "same or invalid tag"),
           form_tag: to_form(Tag.changeset(%Tag{}, %{}))
         )}
    end
  end

  def handle_event("add", %{"post" => post_params}, socket) do
    params =
      post_params
      |> Map.put("user_id", socket.assigns.current_user.id)

    case Blog.create_post_and_associate_tags(params, socket.assigns.tags_input) do
      {:ok, post} ->
        Modal.close("big_content_modal")

        %{
          "current_user" => socket.assigns.current_user,
          "post" => %{body: post.body, title: post.title}
        }
        |> MySuperApp.MinuteWorker.new()
        |> Oban.insert()

        users_drop = Blog.get_users_with_posts(Blog.get_posts_by_preload())

        posts =
          Blog.get_posts_by_preload(
            socket.assigns.filter,
            socket.assigns.sort,
            socket.assigns.selected_user_id,
            socket.assigns.selected_tag_id,
            socket.assigns.kind_of_post
          )

        {:noreply,
         assign(
           socket
           |> put_flash(:info, "post created"),
           id: nil,
           tags: Blog.list_tags(),
           users: users_drop,
           posts: posts,
           total_pages: max(page_count(length(posts), socket.assigns.limit), 1),
           form: to_form(Post.changeset(%Post{}, %{})),
           form_tag: to_form(Tag.changeset(%Tag{}, %{})),
           tags_input: [],
           editing?: false
         )}

      {:error, _error} ->
        Modal.close("big_content_modal")

        {:noreply,
         assign(socket |> put_flash(:error, "Something went wrong"),
           tags_input: [],
           form: to_form(Post.changeset(%Post{}, %{})),
           form_tag: to_form(Tag.changeset(%Tag{}, %{})),
           editing?: false,
           id: nil
         )}
    end
  end

  def handle_event("set_close", _, socket) do
    Modal.close("big_content_modal")

    {:noreply,
     assign(socket,
       editing?: false,
       id: nil,
       form: to_form(Post.changeset(%Post{}, %{})),
       form_tag: to_form(Tag.changeset(%Tag{}, %{})),
       tags_input: [],
       adding_tag: false,
       post: %{
         title: "",
         user_id: "",
         user: %{username: ""},
         body: "",
         tags: []
       }
     )}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(current_page: current_page, current: get_models_10(socket.assigns))}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    socket = assign(socket, filter: filter, current_page: 1)
    {:noreply, assign(socket, total_pages: total_pages(socket.assigns))}
  end

  def handle_event("clear_all", _params, socket) do
    socket =
      assign(socket,
        current_page: 1,
        sort: [id: "ASC"],
        selected_user_id: "0",
        selected_tag_id: "0",
        filter: "",
        kind_of_post: 1,
        selected: 0
      )

    {:noreply,
     assign(socket,
       current: get_models_10(socket.assigns),
       form_drop_tags: to_form(Tag.changeset_drop(%Tag{}, %{"id" => "0"})),
       form_drop_user: to_form(Post.changeset_user(%Post{}, %{"user_id" => "0"})),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("get_tag_form", _, socket) do
    {:noreply, assign(socket, adding_tag: !socket.assigns.adding_tag)}
  end

  def users_sorted_by(users, col, dir) do
    case dir do
      "ASC" ->
        users
        |> Enum.sort_by(&[&1[col]], :asc)

      "DESC" ->
        users
        |> Enum.sort_by(&[&1[col]], :desc)

      _ ->
        users
    end
  end

  defp page_count(total_count, limit) do
    ceil(total_count / limit)
  end

  def total_pages(assigns) do
    max(
      page_count(
        length(
          Blog.get_posts_by_preload(
            assigns.filter,
            assigns.sort,
            assigns.selected_user_id,
            assigns.selected_tag_id,
            assigns.kind_of_post
          )
        ),
        assigns.limit
      ),
      1
    )
  end

  def get_models_10(assigns) do
    offset = (assigns.current_page - 1) * assigns.limit

    Blog.get_posts_by_preload(
      assigns.filter,
      assigns.sort,
      offset,
      assigns.limit,
      assigns.selected_user_id,
      assigns.selected_tag_id,
      assigns.kind_of_post
    )
  end
end
