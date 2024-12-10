defmodule MySuperApp.CasinosRolesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.CasinosRoles` context.
  """

  @doc """
  Generate a role.
  """
  def role_fixture(attrs \\ %{}) do
    role =
      attrs
      |> Enum.into(%{
        name: "some name",
        operator_id: "1"
      })
      |> MySuperApp.CasinosRoles.create_role()

    role
  end
end
