defmodule MySuperApp.Accounts do
  @moduledoc """
  The Accounts context.
  """
  import Ecto.Query

  alias MySuperApp.{User, Repo}

  def delete_user(id) do
    user = Repo.get(User, id)
    Repo.delete(user)
  end

  def update_user(id, attrs \\ %{}) do
    Repo.get(User, id)
    |> User.registration_changeset(attrs)
    |> Repo.update()
  end

  def change_user(user, attrs) do
    user
    |> User.changeset(attrs)
  end

  def get_user_by_id(id), do: Repo.get(User, id) |> Map.from_struct()

  def get_users_with_associations_pagination(
        offset,
        limit,
        [{key, value}],
        filter \\ "",
        role_id \\ "0",
        operator_id \\ "0"
      ) do
    order = value |> String.downcase() |> String.to_atom()

    where_clause =
      if operator_id != "0" do
        check_filter_operator(filter, operator_id)
      else
        check_filter_role(filter, role_id)
      end

    Repo.all(
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: ^where_clause,
        offset: ^offset,
        limit: ^limit,
        order_by: [{^order, field(u, ^key)}],
        select: %{
          id: u.id,
          role_id: u.role_id,
          username: u.username,
          email: u.email,
          inserted_at: u.inserted_at,
          updated_at: u.updated_at,
          role_id: r.id,
          role_name: r.name,
          operator_name: p.name,
          operator_id: p.id
        }
    )
  end

  def get_users_with_associations(filter \\ "", role_id \\ "0", operator_id \\ "0") do
    where_clause =
      if operator_id != "0" do
        check_filter_operator(filter, operator_id)
      else
        check_filter_role(filter, role_id)
      end

    Repo.all(
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: ^where_clause,
        order_by: u.id,
        select: %{
          id: u.id,
          role_id: u.role_id,
          username: u.username,
          email: u.email,
          inserted_at: u.inserted_at,
          updated_at: u.updated_at,
          role_id: r.id,
          role_name: r.name,
          operator_name: p.name,
          operator_id: p.id
        }
    )
  end

  def get_users() do
    Repo.all(from u in User, where: u.superadmin == false)
    |> Enum.map(fn x -> Map.from_struct(x) end)
    |> Enum.sort_by(&max(&1.inserted_at, &1.updated_at))
    |> Enum.reverse()
  end

  def get_users(:all) do
    Repo.all(from(u in User))
    |> Enum.map(fn x -> Map.from_struct(x) end)
    |> Enum.sort_by(&max(&1.inserted_at, &1.updated_at))
    |> Enum.reverse()
  end

  def get_users_count(:oper, "", operator_id) do
    if operator_id == "0" do
      query =
        from(u in User,
          where: u.superadmin == false,
          select: count(u.id)
        )

      Repo.one(query)
    else
      query =
        from(u in User,
          where: u.superadmin == false and u.operator_id == ^operator_id,
          select: count(u.id)
        )

      Repo.one(query)
    end
  end

  def get_users_count(:oper, filter, operator_id) do
    if operator_id == "0" do
      query =
        from(u in User,
          where:
            (ilike(u.username, ^"%#{filter}%") or ilike(u.email, ^"%#{filter}%")) and
              u.superadmin == false,
          select: count(u.id)
        )

      Repo.one(query)
    else
      query =
        from(u in User,
          where:
            (ilike(u.username, ^"%#{filter}%") or ilike(u.email, ^"%#{filter}%")) and
              (u.superadmin == false and u.operator_id == ^operator_id),
          select: count(u.id)
        )

      Repo.one(query)
    end
  end

  def get_users_count("", role_id) do
    if role_id == "0" do
      query =
        from(u in User,
          where: u.superadmin == false,
          select: count(u.id)
        )

      Repo.one(query)
    else
      query =
        from(u in User,
          where: u.superadmin == false and u.role_id == ^role_id,
          select: count(u.id)
        )

      Repo.one(query)
    end
  end

  def get_users_count(filter, role_id) do
    if role_id == "0" do
      query =
        from(u in User,
          where:
            (ilike(u.username, ^"%#{filter}%") or ilike(u.email, ^"%#{filter}%")) and
              u.superadmin == false,
          select: count(u.id)
        )

      Repo.one(query)
    else
      query =
        from(u in User,
          where:
            (ilike(u.username, ^"%#{filter}%") or ilike(u.email, ^"%#{filter}%")) and
              u.superadmin == false and u.role_id == ^role_id,
          select: count(u.id)
        )

      Repo.one(query)
    end
  end

  defp check_filter_operator(filter, operator_id) do
    with {:All, false} <- {:All, filter == "" and operator_id == "0"},
         {:only_filter, false} <- {:only_filter, filter != "" and operator_id == "0"},
         {:only_operator_id, false} <- {:only_operator_id, filter == "" and operator_id != "0"},
         {:none, true} <- {:none, filter != "" and operator_id != "0"} do
      give_specific(:oper, filter, operator_id)
    else
      {:none, false} ->
        raise "shitty query"

      {:All, true} ->
        give_all()

      {:only_filter, true} ->
        give_only_filter(filter)

      {:only_operator_id, true} ->
        give_only_operator(operator_id)
    end
  end

  defp check_filter_role(filter, role_id) do
    with {:All, false} <- {:All, filter == "" and role_id == "0"},
         {:only_filter, false} <- {:only_filter, filter != "" and role_id == "0"},
         {:only_role_id, false} <- {:only_role_id, filter == "" and role_id != "0"},
         {:none, true} <- {:none, filter != "" and role_id != "0"} do
      give_specific(filter, role_id)
    else
      {:none, false} ->
        raise "shitty query"

      {:All, true} ->
        give_all()

      {:only_filter, true} ->
        give_only_filter(filter)

      {:only_role_id, true} ->
        give_only_role(role_id)
    end
  end

  defp give_specific(filter, role_id) do
    dynamic(
      [u],
      (ilike(u.username, ^"%#{filter}%") or
         ilike(u.email, ^"%#{filter}%")) and u.superadmin == false and
        u.role_id == ^role_id
    )
  end

  defp give_specific(:oper, filter, operator_id) do
    dynamic(
      [u],
      (ilike(u.username, ^"%#{filter}%") or
         ilike(u.email, ^"%#{filter}%")) and u.superadmin == false and
        u.operator_id == ^operator_id
    )
  end

  defp give_only_operator(operator_id) do
    dynamic([u], u.superadmin == false and u.operator_id == ^operator_id)
  end

  defp give_only_role(role_id) do
    dynamic([u], u.superadmin == false and u.role_id == ^role_id)
  end

  defp give_only_filter(filter) do
    dynamic(
      [u],
      (ilike(u.username, ^"%#{filter}%") or
         ilike(u.email, ^"%#{filter}%")) and u.superadmin == false
    )
  end

  defp give_all() do
    dynamic([u], u.superadmin == false)
  end

  def delete_all do
    Repo.delete_all(User)
  end

  def change_user_role(user_id, attrs) do
    Repo.get(User, user_id)
    |> User.changeset_role(attrs)
    |> Repo.update()
  end

  def update_user_role(user_id, role_id) do
    User
    |> Repo.get(user_id)
    |> User.role_changeset(%{role_id: role_id})
    |> Repo.update()
  end

  def update_user_operator(user_id, operator_id) do
    User
    |> Repo.get(user_id)
    |> User.oper_changeset(%{operator_id: operator_id})
    |> Repo.update()
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    query =
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: u.superadmin != true,
        select: %{
          id: u.id,
          username: u.username,
          email: u.email,
          operator_id: u.operator_id,
          role_id: u.role_id,
          operator: %{
            name: p.name
          },
          role: %{
            name: r.name
          }
        }

    Repo.all(query)
  end

  def list_users(username: username) do
    query =
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: u.superadmin != true and ^username == u.username,
        select: %{
          id: u.id,
          username: u.username,
          email: u.email,
          operator_id: u.operator_id,
          role_id: u.role_id,
          operator: %{
            name: p.name
          },
          role: %{
            name: r.name
          }
        }

    Repo.all(query)
  end

  def list_users(role: role) do
    query =
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: u.superadmin != true and ^role == r.name,
        select: %{
          id: u.id,
          username: u.username,
          email: u.email,
          operator_id: u.operator_id,
          role_id: u.role_id,
          operator: %{
            name: p.name
          },
          role: %{
            name: r.name
          }
        }

    Repo.all(query)
  end

  def list_users(email: email) do
    query =
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: u.superadmin != true and ^email == u.email,
        select: %{
          id: u.id,
          username: u.username,
          email: u.email,
          operator_id: u.operator_id,
          role_id: u.role_id,
          operator: %{
            name: p.name
          },
          role: %{
            name: r.name
          }
        }

    Repo.all(query)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user(id) do
    query =
      from u in User,
        left_join: r in assoc(u, :role),
        left_join: p in assoc(u, :operator),
        where: u.superadmin != true and ^id == u.id,
        select: %{
          id: u.id,
          username: u.username,
          email: u.email,
          operator_id: u.operator_id,
          role_id: u.role_id,
          operator: %{
            name: p.name
          },
          role: %{
            name: r.name
          }
        }

    Repo.one(query)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def api_update_user(id, attrs) do
    case Repo.get(User, id) do
      %User{} = user ->
        {:ok, modified_user} =
          user
          |> User.changeset(attrs)
          |> Repo.update()

        {:ok, modified_user |> Repo.preload([:operator, :role])}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> api_delete_user(user)
      {:ok, %User{}}

      iex> api_delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def api_delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def api_delete_user(user) do
    Repo.get(User, user.id)
    |> Repo.delete()
  end
end
