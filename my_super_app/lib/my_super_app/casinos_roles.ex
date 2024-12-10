defmodule MySuperApp.CasinosRoles do
  @moduledoc """
   Context for roles
  """
  alias MySuperApp.{Repo, User, Role}
  import Ecto.Query

  def add_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Role.maybe_put_assoc(attrs)
    |> Repo.insert()
  end

  def get_role_struct(id) do
    Repo.get(Role, id) |> Repo.preload([:operator])
  end

  def get_role(id) do
    Repo.one(
      from r in Role,
        join: operator in assoc(r, :operator),
        where: ^id == r.id,
        select: %{
          id: r.id,
          name: r.name,
          inserted_at: r.inserted_at,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_role_option(id) do
    query =
      from r in Role,
        where: r.id == ^id,
        select: %{key: r.name, value: r.id, disabled: false}

    Repo.all(query)
  end

  def get_roles_by_operator_name(operator_name) do
    Repo.all(
      from role in Role,
        join: operator in Operator,
        on: role.operator_id == operator.id,
        where: operator.name == ^operator_name,
        select: %{
          name: role.name,
          id: role.id
        }
    )
  end

  def get_roles() do
    Role
    |> Repo.all()
    |> Repo.preload(:operator)
    |> Enum.map(fn role ->
      %{
        id: role.id,
        name: role.name,
        operator: %{
          id: role.operator.id,
          name: role.operator.name
        },
        inserted_at: role.inserted_at,
        updated_at: role.updated_at
      }
    end)
  end

  def get_roles_with_operators("All", [{key, value}]) do
    dir = value |> String.downcase() |> String.to_atom()

    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        order_by: [{^dir, field(role, ^key)}],
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_roles_with_operators(nil, [{key, value}]) do
    dir = value |> String.downcase() |> String.to_atom()

    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        order_by: [{^dir, field(role, ^key)}],
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_roles_with_operators(order, [{key, value}]) do
    dir = value |> String.downcase() |> String.to_atom()

    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        where: operator.name == ^order,
        order_by: [{^dir, field(role, ^key)}],
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_roles_with_operators(nil, offset, limit, [{key, value}]) do
    dir = value |> String.downcase() |> String.to_atom()

    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        order_by: [{^dir, field(role, ^key)}],
        offset: ^offset,
        limit: ^limit,
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_roles_with_operators("All", offset, limit, [{key, value}]) do
    dir = value |> String.downcase() |> String.to_atom()

    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        order_by: [{^dir, field(role, ^key)}],
        offset: ^offset,
        limit: ^limit,
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_roles_with_operators(order, offset, limit, [{key, value}]) do
    dir = value |> String.downcase() |> String.to_atom()

    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        where: operator.name == ^order,
        order_by: [{^dir, field(role, ^key)}],
        offset: ^offset,
        limit: ^limit,
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def delete_role(id) do
    role = Repo.get(Role, id)

    if role do
      Repo.delete(role)
    else
      {:error, :not_found}
    end
  end

  def get_roles_options() do
    query =
      from r in Role,
        select: %{key: r.name, value: r.id}

    Repo.all(query)
  end

  def get_roles_name(operator_id) do
    query =
      from r in Role,
        where: r.operator_id == ^operator_id,
        select: r.name

    Repo.all(query)
  end

  def delete_all_roles() do
    Role
    |> Repo.delete_all()
  end

  def get_roles_by_oper(operator_id) do
    query =
      from r in Role,
        where: r.operator_id == ^operator_id,
        select: %{key: r.name, value: r.id, disabled: false}

    Repo.all(query)
  end

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def get_role_by_user(user_id) do
    Repo.one(
      from u in User,
        join: role in assoc(u, :role),
        on: ^user_id == u.id,
        join: operator in assoc(role, :operator),
        select: %{
          user_id: ^user_id,
          username: u.username,
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name
        }
    )
  end

  def get_role_by_name(name) do
    Repo.all(
      from role in Role,
        join: operator in assoc(role, :operator),
        on: role.operator_id == operator.id,
        where: role.name == ^name,
        select: %{
          id: role.id,
          inserted_at: role.inserted_at,
          updated_at: role.updated_at,
          name: role.name,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id), do: Repo.get(Role, id) |> Repo.preload([:operator])

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_role(attrs \\ %{}) do
    role_change =
      %Role{}
      |> Role.changeset(attrs)

    case role_change do
      %Ecto.Changeset{valid?: true} ->
        {:ok, role} = Repo.insert(role_change)
        role |> Repo.preload([:operator])

      %Ecto.Changeset{valid?: false} ->
        {:error, :check_params}
    end
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_role(role, attrs) do
    role_change =
      role
      |> Role.changeset(attrs)

    case role_change do
      %Ecto.Changeset{valid?: true} ->
        {:ok, role} = Repo.update(role_change)
        {:ok, role |> Repo.preload([:operator])}

      %Ecto.Changeset{valid?: false} ->
        {:error, :check_params}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{data: %Role{}}

  """
  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end
end
