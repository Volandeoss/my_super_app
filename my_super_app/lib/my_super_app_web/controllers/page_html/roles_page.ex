defmodule MySuperAppWeb.RolesPage do
  @moduledoc false
  use MySuperAppWeb, :admin_surface_live_view

  alias MySuperApp.{CasinosRoles, CasinosAdmins, Role}
  alias Moon.Design.{Table, Button, Button.IconButton, Modal, Form, Dropdown, Chip}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}

  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  def mount(_, _, socket) do
    {
      :ok,
      assign(socket,
        roles: CasinosRoles.get_roles_with_operators(nil, id: "ASC"),
        form: to_form(Role.changeset(%Role{}, %{})),
        editing?: false,
        operators: CasinosAdmins.get_operators(),
        value: nil,
        current_page: 1,
        limit: 8,
        sort: [id: "ASC"],
        total_pages:
          max(page_count(length(CasinosRoles.get_roles_with_operators(nil, id: "ASC")), 8), 1)
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

  defp page_count(total_count, limit) do
    ceil(total_count / limit)
  end

  def get_models_10(assigns) do
    offset = (assigns.current_page - 1) * assigns.limit
    CasinosRoles.get_roles_with_operators(assigns.value, offset, assigns.limit, assigns.sort)
  end

  def handle_event(
        "on_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    {:noreply,
     assign(socket,
       sites:
         users_sorted_by(
           CasinosRoles.get_roles_with_operators(nil, socket.assigns.sort),
           String.to_atom(sort_key),
           sort_dir
         ),
       sort: ["#{sort_key}": sort_dir],
       updated?: false
     )}
  end

  def handle_event("set_operator", %{"value" => name}, socket) do
    {:noreply,
     assign(socket,
       value: name,
       current_page: 1,
       total_pages:
         max(
           page_count(
             length(
               CasinosRoles.get_roles_with_operators(
                 name,
                 socket.assigns.sort
               )
             ),
             socket.assigns.limit
           ),
           1
         )
     )}
  end

  def handle_event("set_current_page", %{"value" => page}, socket) do
    {:noreply, assign(socket, current_page: String.to_integer(page))}
  end

  def handle_event("delete", %{"value" => id}, socket) do
    case CasinosRoles.delete_role(id) do
      {:ok, _} ->
        {:noreply,
         assign(socket |> put_flash(:info, "role deleted"),
           current_page: max(socket.assigns.current_page - 1, 1),
           total_pages:
             max(
               page_count(
                 length(
                   CasinosRoles.get_roles_with_operators(
                     socket.assigns.value,
                     socket.assigns.sort
                   )
                 ),
                 socket.assigns.limit
               ),
               1
             )
         )}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "something went wrong")}
    end
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(current_page: current_page, models_10: get_models_10(socket.assigns))}
  end

  def handle_event("set_open", %{"value" => ""}, socket) do
    Modal.open("default_modal")
    {:noreply, assign(socket, editing?: true)}
  end

  def handle_event("set_close", _, socket) do
    Modal.close("default_modal")
    {:noreply, assign(socket, form: to_form(Role.changeset(%Role{}, %{})))}
  end

  def handle_event("validate", %{"operator_id" => _operator_id, "role" => params}, socket) do
    params = params |> Map.put("operator_id", socket.assigns.current_user.operator_id)

    form =
      %Role{}
      |> Role.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("validate", %{"role" => params}, socket) do
    params = params |> Map.put("operator_id", socket.assigns.current_user.operator_id)

    form =
      %Role{}
      |> Role.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add", %{"role" => params}, socket) do
    attrs =
      params
      |> Map.put("operator_id", socket.assigns.current_user.operator_id)

    Modal.close("default_modal")

    case CasinosRoles.add_role(attrs) do
      {:ok, _user} ->
        {:noreply,
         assign(socket |> put_flash(:info, "New role created"),
           editing?: false,
           total_pages:
             max(
               page_count(
                 length(
                   CasinosRoles.get_roles_with_operators(
                     socket.assigns.value,
                     socket.assigns.sort
                   )
                 ),
                 8
               ),
               1
             ),
           form: to_form(Role.changeset(%Role{}, %{})),
           roles: get_models_10(socket.assigns)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Invalid parameters"),
           form: to_form(changeset),
           editing?: false
         )}
    end
  end
end
