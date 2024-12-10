defmodule MySuperAppWeb.AdminMainPage do
  @moduledoc """
    admin page
  """
  use MySuperAppWeb, :admin_surface_live_view

  alias Moon.Design.Table
  alias Moon.Design.Form

  alias Moon.Design.Table.Column
  alias Moon.Design.{Button, Button.IconButton, Modal}

  alias Moon.Design.Tooltip

  alias Moon.Design.Drawer
  alias Moon.Design.Dropdown

  alias Moon.Design.Search
  # import Moon.Helpers.Form, only: [filter_options: 2]

  alias MySuperApp.{Accounts, CasinosRoles, User, Role, CasinosAdmins}

  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  # prop(options, :list, default: MoonWeb.Schema.Link.titles())
  prop(filter, :string, default: "")
  prop(selected, :list, default: [])
  data(users, :any, default: [])
  data(user, :any, default: %{id: "", username: "", email: ""})

  def mount(_, _session, socket) do
    users = Accounts.get_users_with_associations()

    {
      :ok,
      assign(
        socket,
        users: users,
        id: nil,
        current_page: 1,
        limit: 8,
        total_pages: page_count(length(users)),
        sort: [id: "ASC"],
        selected: [],
        form_role: to_form(User.changeset(%User{}, %{})),
        form_drop_role: to_form(User.changeset_role(%User{}, %{"role_id" => "0"})),
        form_drop_oper: to_form(User.changeset_operator(%User{}, %{"operator_id" => "0"})),
        editing?: false,
        form_oper: to_form(Role.changeset(%Role{}, %{})),
        filter: "",
        selected_role_id: "0",
        selected_oper_id: "0"
      )
    }
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

  def handle_event("validate_role", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset_role(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form_role: form)}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    total =
      if socket.assigns.selected_role_id != "0" do
        max(
          page_count(
            Accounts.get_users_count(filter, socket.assigns.selected_role_id),
            socket.assigns.limit
          ),
          1
        )
      else
        max(
          page_count(
            Accounts.get_users_count(:oper, filter, socket.assigns.selected_oper_id),
            socket.assigns.limit
          ),
          1
        )
      end

    {:noreply, assign(socket, filter: filter, total_pages: total, current_page: 1)}
  end

  def handle_event("validate_operator", %{"role" => params}, socket) do
    form =
      %Role{}
      |> Role.changeset_for_operator(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form_oper: form)}
  end

  def handle_event("delete", _params, socket) do
    id = socket.assigns.user.id
    count = Accounts.get_users_count(socket.assigns.filter, socket.assigns.selected_role_id)
    Accounts.delete_user(id)

    Modal.close("default_modal")

    {:noreply,
     assign(socket |> put_flash(:info, "user deleted"),
       users:
         Accounts.get_users_with_associations(
           socket.assigns.filter,
           socket.assigns.selected_role_id
         ),
       total_pages: page_count(count, socket.assigns.limit),
       current_page:
         min(
           ceil(count / socket.assigns.limit) |> max(1),
           socket.assigns.current_page
         )
     )}
  end

  def handle_event("set_open", %{"value" => selected}, socket) do
    Drawer.open("with_close_drawer")
    {:noreply, assign(socket, selected: [selected], editing?: true)}
  end

  def handle_event("select_role", %{"user" => %{"role_id" => role_id} = role}, socket) do
    total =
      max(
        page_count(
          Accounts.get_users_count(socket.assigns.filter, role_id),
          socket.assigns.limit
        ),
        1
      )

    form =
      %User{}
      |> User.changeset_role(role)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply,
     assign(socket,
       selected_oper_id: "0",
       selected_role_id: role_id,
       form_drop_role: form,
       form_drop_oper: to_form(User.changeset_operator(%User{}, %{"operator_id" => "0"})),
       total_pages: total,
       current_page: 1
     )}
  end

  def handle_event("select_oper", %{"user" => %{"operator_id" => operator_id} = operator}, socket) do
    total =
      max(
        page_count(
          Accounts.get_users_count(:oper, socket.assigns.filter, operator_id),
          socket.assigns.limit
        ),
        1
      )

    form =
      %User{}
      |> User.changeset_operator(operator)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply,
     assign(socket,
       selected_role_id: "0",
       selected_oper_id: operator_id,
       form_drop_role: to_form(User.changeset_role(%User{}, %{"role_id" => "0"})),
       form_drop_oper: form,
       total_pages: total,
       current_page: 1
     )}
  end

  def handle_event("set_close", _params, socket) do
    Drawer.close("with_close_drawer")
    {:noreply, assign(socket, selected: [], editing?: false)}
  end

  def handle_event(
        "on_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    {:noreply,
     assign(socket,
       users:
         users_sorted_by(
           Accounts.get_users_with_associations(
             socket.assigns.filter,
             socket.assigns.selected_role_id
           ),
           String.to_atom(sort_key),
           sort_dir
         ),
       sort: ["#{sort_key}": sort_dir],
       updated?: false
     )}
  end

  def handle_event("add", %{"user" => %{"role_id" => role_id}}, socket) do
    [user_id] = socket.assigns.selected

    Modal.close("default_modal")

    case Accounts.update_user_role(user_id, role_id) do
      {:ok, _user} ->
        {:noreply,
         assign(socket |> put_flash(:info, "User role has been updated"),
           editing?: false,
           selected: [],
           form_role: to_form(User.changeset(%User{}, %{}))
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Invalid parameters"),
           form_role: to_form(changeset),
           editing?: false
         )}
    end
  end

  def handle_event("add_operator", %{"role" => %{"operator_id" => operator_id}}, socket) do
    user_id = socket.assigns.selected |> hd()

    Modal.close("default_modal")

    case Accounts.update_user_operator(user_id, operator_id) do
      {:ok, _user} ->
        {:noreply,
         assign(socket |> put_flash(:info, "User operator has been updated"),
           editing?: false,
           form_oper: to_form(Role.changeset(%Role{}, %{}))
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Invalid parameters"),
           form_oper: to_form(changeset),
           editing?: false
         )}
    end
  end

  def handle_event("set_open_modal", %{"value" => id}, socket) do
    user =
      socket.assigns.users
      |> Enum.find(fn user -> user.id == String.to_integer(id) end)

    Modal.open("default_modal")
    {:noreply, assign(socket, user: user)}
  end

  def handle_event("set_close_modal", _, socket) do
    Modal.close("default_modal")
    {:noreply, assign(socket, user: %{id: "", username: "", email: ""})}
  end

  def handle_event("set_current_page", %{"value" => page}, socket) do
    {:noreply, assign(socket, current_page: String.to_integer(page))}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(current_page: current_page, models_10: get_models_10(socket.assigns))}
  end

  defp page_count(total_count, limit \\ 8) do
    ceil(total_count / limit)
  end

  def get_models_10(assigns) do
    offset = (assigns.current_page - 1) * assigns.limit

    Accounts.get_users_with_associations_pagination(
      offset,
      assigns.limit,
      assigns.sort,
      assigns.filter,
      assigns.selected_role_id,
      assigns.selected_oper_id
    )
  end

  def handle_info(:after_modal_close, socket) do
    {:noreply, assign(socket, user: %{id: "", username: "", email: ""})}
  end
end
