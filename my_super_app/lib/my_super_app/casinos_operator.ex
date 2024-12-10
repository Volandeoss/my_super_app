defmodule MySuperApp.CasinosAdmins do
  @moduledoc false
  alias MySuperApp.{Repo, User, Operator}
  import Ecto.Query

  def add_operator(attrs \\ %{}) do
    %Operator{}
    |> Operator.changeset(attrs)
    |> Repo.insert()
  end

  def get_operator_name(id) do
    operator = Repo.get(Operator, id)
    Map.get(operator, :name)
  end

  def get_operators() do
    query =
      from o in Operator,
        select: %{
          id: o.id,
          name: o.name,
          inserted_at: o.inserted_at,
          updated_at: o.updated_at
        }

    Repo.all(query)
  end

  def get_operators(offset, limit) do
    query =
      from o in Operator,
        offset: ^offset,
        limit: ^limit,
        select: %{
          id: o.id,
          name: o.name,
          inserted_at: o.inserted_at,
          updated_at: o.updated_at
        }

    Repo.all(query)
  end

  def delete_operator(id) do
    remove_operator_from_users(id)

    Operator
    |> Repo.get(id)
    |> Repo.delete()
  end

  defp remove_operator_from_users(operator_id) do
    case Repo.update_all(
           from(u in User, where: u.operator_id == ^operator_id),
           set: [operator_id: nil]
         ) do
      {count, _} ->
        IO.puts("#{count} users updated")
        :ok
    end
  end

  def get_oper_options do
    Repo.all(
      from(op in Operator,
        select: %{
          key: op.name,
          value: op.id,
          disabled: false
        }
      )
    )
  end

  def get_oper_name do
    Repo.all(from(op in Operator, select: op.name))
  end

  def delete_all() do
    Repo.delete_all(Operator)
  end
end
