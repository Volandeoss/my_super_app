defmodule MySuperAppWeb.RoleController do
  use MySuperAppWeb, :controller

  alias MySuperApp.CasinosRoles
  alias MySuperApp.Role

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"user_id" => user_id}) do
    role = CasinosRoles.get_role_by_user(user_id)

    if role do
      render(conn, :show_with_user, role: role)
    else
      {:error, :not_found}
    end
  end

  def index(conn, %{"name" => name}) do
    roles = CasinosRoles.get_role_by_name(name)
    render(conn, :index, roles: roles)
  end

  def index(conn, _params) do
    roles = CasinosRoles.list_roles()
    render(conn, :index, roles: roles)
  end

  def create(conn, %{"role" => role_params}) do
    with %Role{} = role <- CasinosRoles.create_role(role_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/roles/#{role}")
      |> render(:show, role: role)
    end
  end

  def show(conn, %{"id" => id}) do
    role = CasinosRoles.get_role(id)

    if role do
      render(conn, :show, role: role)
    else
      {:error, :not_found}
    end
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    role = CasinosRoles.get_role_struct(id)

    with {:ok, %Role{} = role} <- CasinosRoles.update_role(role, role_params) do
      render(conn, :show, role: role)
    end
  end

  def delete(conn, %{"id" => id}) do
    role = CasinosRoles.get_role_struct(id)

    with %Role{} <- role,
         {:ok, %Role{}} <- CasinosRoles.delete_role(role.id) do
      render(conn, :show, role: role)
    else
      _ -> {:error, :not_found}
    end
  end
end
