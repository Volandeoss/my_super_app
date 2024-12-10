defmodule MySuperAppWeb.UserJSON do
  alias MySuperApp.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    with {:role, false} <- {:role, user.role_id != nil},
         {:operator, false} <- {:operator, user.operator_id != nil} do
      %{
        id: user.id,
        name: user.username,
        email: user.email
      }
    else
      {:role, true} ->
        %{
          id: user.id,
          name: user.username,
          email: user.email,
          role_id: user.role_id,
          role_name: user.role.name
        }

      {:operator, true} ->
        %{
          id: user.id,
          name: user.username,
          email: user.email,
          operator_id: user.operator_id,
          operator_name: user.operator.name
        }
    end
  end

  defp data(user) do
    with {:role, false} <- {:role, user.role_id != nil},
         {:operator, false} <- {:operator, user.operator_id != nil} do
      %{
        id: user.id,
        name: user.username,
        email: user.email
      }
    else
      {:role, true} ->
        %{
          id: user.id,
          name: user.username,
          email: user.email,
          role_id: user.role_id,
          role_name: user.role.name
        }

      {:operator, true} ->
        %{
          id: user.id,
          name: user.username,
          email: user.email,
          operator_id: user.operator_id,
          operator_name: user.operator.name
        }
    end
  end
end
