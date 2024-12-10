defmodule MySuperAppWeb.ImagePage do
  @moduledoc false
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Design.Progress

  alias MySuperApp.{Blog, Picture}
  alias Moon.Design.{Modal, Chip, Button, Form, Form.Field, Search, Dropdown}

  alias Moon.Icons.ControlsCloseSmall
  alias Moon.Icons.ControlsChevronRightSmall
  alias Moon.Icons.ControlsChevronLeftSmall
  alias Moon.Design.Pagination

  alias Moon.Design.Tag, as: MoonTag
  alias Moon.Icons.TextHashtag
  alias Moon.Icons.MediaPng

  alias Moon.Icons.GenericDelete
  alias Moon.Icons.GenericShareIosBig

  def mount(_, _, socket) do
    if connected?(socket) do
      Blog.subscribe()
    end

    socket =
      assign(socket,
        limit: 8,
        sort: [inserted_at: "ASC"],
        filter: "",
        current_page: 1,
        images: Blog.get_pictures(),
        selected_ext: ""
      )

    {:ok,
     assign(socket,
       change?: true,
       images: Blog.get_pictures(),
       picture_form: to_form(Picture.changeset_file_name(%Picture{}, %{})),
       editing?: false,
       current_pic: get_models_10(socket.assigns),
       filter: "",
       posts: Blog.posts_without_pic(),
       selected_post_id: "",
       total_pages: total_pages(socket.assigns),
       chip_status: "Oldest",
       post: nil,
       form: to_form(Picture.changeset_ext(%Picture{}, %{})),
       link_form: to_form(Picture.changeset_link(%Picture{}, %{}))
     )
     |> allow_upload(:picture,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  def handle_event("open_link_form", _, socket) do
    {:noreply,
     assign(socket,
       posts: Blog.posts_without_pic(),
       change?: !socket.assigns.change?,
       editing?: true
     )}
  end

  def handle_event("validate_link", %{"picture" => %{"post_id" => post_id}}, socket) do
    form =
      Blog.validate_link(post_id)
      |> to_form()

    {:noreply,
     assign(socket,
       posts: Blog.posts_without_pic(),
       editing?: true,
       link_form: form
     )}
  end

  def handle_event("update_link", %{"picture" => %{"post_id" => post_id}}, socket) do
    Blog.get_picture(socket.assigns.post.id)
    |> Blog.update_picture_link(%{post_id: post_id})

    socket = assign(socket, post: Blog.get_post_with_pic(socket.assigns.post.id))

    {:noreply,
     assign(socket,
       change?: true,
       posts: Blog.posts_without_pic(),
       link_form: to_form(Picture.changeset_link(%Picture{}, %{}))
     )}
  end

  def handle_event("update_image", _, socket) when socket.assigns.uploads.picture.entries != [] do
    pic =
      socket.assigns.uploads.picture.entries |> hd()

    [url] =
      consume_uploaded_entries(socket, :picture, fn %{path: path}, _entry ->
        case Cloudex.upload(path) do
          {:ok, result} ->
            Blog.get_picture(socket.assigns.post.id)
            |> Blog.update_picture(%{
              path: result.secure_url,
              file_name: pic.client_name
            })

            {:ok, result.secure_url}

          {:error, reason} ->
            {:error, reason}
        end
      end)

    {:noreply,
     assign(socket,
       change?: !socket.assigns.change?,
       editing?: true,
       post: Map.put(socket.assigns.post, :path, url)
     )}
  end

  def handle_event("update_image", _, socket) do
    {:noreply,
     assign(socket |> put_flash(:warn, "Invalid file"),
       change?: !socket.assigns.change?,
       editing?: true
     )}
  end

  def handle_event("open_update", _params, socket) do
    if socket.assigns.uploads.picture.entries != [] do
      picture =
        socket.assigns.uploads.picture.entries |> hd() |> Map.from_struct()

      {:noreply,
       assign(socket, change?: !socket.assigns.change?, editing?: true)
       |> cancel_upload(:picture, picture.ref)}
    else
      {:noreply, assign(socket, change?: !socket.assigns.change?, editing?: true)}
    end
  end

  def handle_event("set_open", _params, socket) do
    Modal.open("big_content_modal")
    {:noreply, assign(socket, editing?: true)}
  end

  def handle_event("set_close", _, socket) do
    Modal.close("big_content_modal")
    Process.send_after(self(), :close_modal, 400)
    {:noreply, socket}
  end

  def handle_event("validate_upd_avatar", %{"_target" => ["picture"]}, socket) do
    form =
      Blog.validate_upd_picture(socket.assigns.uploads.picture.entries)
      |> to_form()

    {:noreply, assign(socket, picture_form: form)}
  end

  def handle_event("validate_avatar", %{"_target" => ["picture"]}, socket) do
    form =
      Blog.validate_picture(
        socket.assigns.uploads.picture.entries,
        socket.assigns.selected_post_id
      )
      |> to_form()

    {:noreply, assign(socket, picture_form: form)}
  end

  def handle_event(
        "validate_avatar",
        %{"_target" => ["picture", "post_id"], "picture" => %{"post_id" => post_id}},
        socket
      ) do
    form =
      Blog.validate_picture(socket.assigns.uploads.picture.entries, post_id)
      |> to_form()

    {:noreply, assign(socket, picture_form: form, selected_post_id: post_id)}
  end

  def handle_event("save_avatar", %{"picture" => %{"post_id" => post_id}}, socket) do
    pic =
      socket.assigns.uploads.picture.entries |> hd()

    consume_uploaded_entries(socket, :picture, fn %{path: path}, _entry ->
      case Cloudex.upload(path) do
        {:ok, result} ->
          Blog.create_picture(%{
            post_id: post_id,
            path: result.secure_url,
            file_name: pic.client_name
          })

          {:ok, result.secure_url}

        {:error, reason} ->
          {:error, reason}
      end
    end)

    Modal.close("big_content_modal")

    {:noreply,
     assign(socket |> put_flash(:info, "Avatar uploaded successfully"),
       current_pic: get_models_10(socket.assigns),
       editing?: false,
       posts: Blog.posts_without_pic(),
       post_id: nil,
       picture_form: to_form(Picture.changeset_file_name(%Picture{}, %{})),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("save_avatar", %{}, socket) do
    consume_uploaded_entries(socket, :picture, fn %{path: path}, entry ->
      case Cloudex.upload(path) do
        {:ok, result} ->
          Blog.create_picture(%{
            path: result.secure_url,
            file_name: entry.client_name
          })

          {:ok, result.secure_url}

        {:error, reason} ->
          {:error, reason}
      end
    end)

    Modal.close("big_content_modal")

    {:noreply,
     assign(socket |> put_flash(:info, "Avatar uploaded successfully"),
       current_pic: get_models_10(socket.assigns),
       editing?: false,
       posts: Blog.posts_without_pic(),
       post_id: nil,
       picture_form: to_form(Picture.changeset_file_name(%Picture{}, %{})),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("set_current_page", %{"value" => page}, socket) do
    socket = assign(socket, current_page: String.to_integer(page))
    {:noreply, assign(socket, current_pic: get_models_10(socket.assigns))}
  end

  def handle_event("sort_by", _params, socket) do
    new_sort =
      case socket.assigns.sort do
        [inserted_at: "ASC"] -> [inserted_at: "DESC"]
        [inserted_at: "DESC"] -> [inserted_at: "ASC"]
      end

    socket = assign(socket, sort: new_sort)

    {:noreply,
     assign(socket,
       current_pic: get_models_10(socket.assigns),
       chip_status: if(socket.assigns.chip_status == "Newest", do: "Oldest", else: "Newest")
     )}
  end

  def handle_event("delete_image", %{"value" => img_id}, socket) do
    Modal.close("big_content_modal")
    Blog.delete_picture(img_id)

    total_pages = total_pages(socket.assigns)

    socket =
      assign(socket |> put_flash(:info, "image has been deleted"),
        current_page:
          if(socket.assigns.current_page > total_pages,
            do: total_pages,
            else: socket.assigns.current_page
          )
      )

    {:noreply,
     assign(socket,
       post: nil,
       posts: Blog.posts_without_pic(),
       current_pic: get_models_10(socket.assigns),
       total_pages: total_pages
     )}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    socket = assign(socket, filter: filter)

    {:noreply,
     assign(socket,
       filter: filter,
       current_pic: get_models_10(socket.assigns),
       current_page: 1,
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("open_post", %{"value" => post_id}, socket) do
    Modal.open("big_content_modal")
    post = Blog.get_post_with_pic(post_id)
    {:noreply, assign(socket, post: post)}
  end

  def handle_event("select_ext", %{"picture" => params}, socket) do
    %{"file_name" => ext} = params

    form =
      %Picture{}
      |> Picture.changeset_ext(params)
      |> Map.put(:action, :insert)
      |> to_form()

    socket = assign(socket, current_page: 1, selected_ext: ext)

    {:noreply,
     assign(socket,
       form: form,
       current_pic: get_models_10(socket.assigns),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def handle_event("clear_all", _params, socket) do
    socket =
      assign(socket,
        selected_ext: "",
        filter: "",
        current_page: 1,
        sort: [inserted_at: "ASC"],
        chip_status: "Oldest"
      )

    {:noreply,
     assign(socket,
       form: to_form(Picture.changeset_ext(%Picture{}, %{})),
       current_pic: get_models_10(socket.assigns),
       total_pages: total_pages(socket.assigns)
     )}
  end

  def get_models_10(assigns) do
    offset = (assigns.current_page - 1) * assigns.limit

    Blog.get_pictures(
      assigns.limit,
      offset,
      assigns.sort,
      assigns.filter,
      assigns.selected_ext
    )
  end

  defp total_pages(assigns) do
    page_count(
      length(
        Blog.get_pictures(
          assigns.sort,
          assigns.filter,
          assigns.selected_ext
        )
      ),
      assigns.limit
    )
  end

  defp page_count(total_count, limit) do
    page_count = ceil(total_count / limit)
    if page_count == 0, do: 1, else: page_count
  end

  def handle_info(:close_modal, socket) do
    if socket.assigns.uploads.picture.entries != [] do
      picture =
        socket.assigns.uploads.picture.entries |> hd() |> Map.from_struct()

      {:noreply,
       assign(socket,
         editing?: false,
         change?: true,
         picture_form: to_form(Picture.changeset_file_name(%Picture{}, %{})),
         post: nil,
         selected_post_id: ""
       )
       |> cancel_upload(:picture, picture.ref)}
    else
      {:noreply,
       assign(socket,
         change?: true,
         selected_post_id: "",
         editing?: false,
         picture_form: to_form(Picture.changeset_file_name(%Picture{}, %{})),
         post: nil
       )}
    end
  end

  def handle_info({:picture_created, pic}, socket) do
    {:noreply,
     assign(socket |> put_flash(:info, "New picture #{pic.id} created"),
       current_pic: get_models_10(socket.assigns)
     )}
  end

  def handle_info({:picture_deleted, pic}, socket) do
    {:noreply,
     assign(socket |> put_flash(:info, "Picture #{pic.id} deleted"),
       current_pic: get_models_10(socket.assigns)
     )}
  end

  def handle_info({:picture_updated, pic}, socket) do
    {:noreply,
     assign(socket |> put_flash(:info, "picture #{pic.id} has been updated"),
       current_pic: get_models_10(socket.assigns)
     )}
  end
end
