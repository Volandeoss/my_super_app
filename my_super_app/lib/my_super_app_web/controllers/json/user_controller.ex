defmodule MySuperAppWeb.UserController do
  use MySuperAppWeb, :controller

  alias MySuperApp.{Accounts, AccountsAuth, User}

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"email" => email}) do
    users = Accounts.list_users(email: email)
    render(conn, :index, users: users)
  end

  def index(conn, %{"username" => username}) do
    users = Accounts.list_users(username: username)
    render(conn, :index, users: users)
  end

  def index(conn, %{"role" => role}) do
    users = Accounts.list_users(role: role)
    render(conn, :index, users: users)
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def create(conn, %{"user" => user_params}) do
    case AccountsAuth.register_user(user_params) do
      {:ok, %User{} = user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/users/#{user}")
        |> render(:show, user: user)

      _ ->
        {:error, :check_params}
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)

    case user do
      nil ->
        {:error, :not_found}

      %{} ->
        render(conn, :show, user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    with {:ok, user} <- Accounts.api_update_user(id, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user(id)

    with {:ok, %User{} = user} <- Accounts.api_delete_user(user) do
      render(conn, :show, user: user)
    end
  end
end
