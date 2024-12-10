defmodule MySuperAppWeb.RoleJSON do
  alias MySuperApp.Role

  @doc """
  Renders a list of roles.
  """
  def index(%{roles: roles}) do
    %{data: for(role <- roles, do: data(role))}
  end

  @doc """
  Renders a single role.
  """
  def show(%{role: role}) do
    %{data: data(role)}
  end

  def show_with_user(%{role: role}) do
    %{data: data_with_user(role)}
  end

  defp data_with_user(role) do
    %{
      id: role.id,
      name: role.name,
      inserted_at: role.inserted_at,
      operator_name: role.operator_name,
      username: role.username
    }
  end

  defp data(%Role{} = role) do
    %{
      id: role.id,
      name: role.name,
      inserted_at: role.inserted_at,
      operator_id: role.operator.id,
      operator_name: role.operator.name
    }
  end

  defp data(role) do
    %{
      id: role.id,
      name: role.name,
      inserted_at: role.inserted_at,
      operator_id: role.operator_id,
      operator_name: role.operator_name
    }
  end
end
