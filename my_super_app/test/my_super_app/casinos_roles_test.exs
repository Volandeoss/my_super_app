defmodule MySuperApp.CasinosRolesTest do
  use MySuperApp.DataCase

  alias MySuperApp.CasinosRoles

  describe "roles" do
    alias MySuperApp.Role

    import MySuperApp.CasinosRolesFixtures

    @invalid_attrs %{name: nil, operator_id: nil}

    test "list_roles/0 returns all roles" do
      role_fixture()
      assert length(CasinosRoles.list_roles()) >= 1
    end

    test "get_role!/1 returns the role with given id" do
      role = role_fixture()
      CasinosRoles.get_role!(role.id)
    end

    test "create_role/1 with valid data creates a role" do
      valid_attrs = %{name: "some name", operator_id: "1"}
      role = CasinosRoles.create_role(valid_attrs)
      assert %Role{} = role
      assert role.name == "some name"
    end

    test "create_role/1 with invalid data returns error changeset" do
      assert {:error, :check_params} = CasinosRoles.create_role(@invalid_attrs)
    end

    test "update_role/2 with valid data updates the role" do
      role = role_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Role{} = role} = CasinosRoles.update_role(role, update_attrs)
      assert role.name == "some updated name"
    end

    test "update_role/2 with invalid data returns error changeset" do
      role = role_fixture()
      assert {:error, :check_params} = CasinosRoles.update_role(role, @invalid_attrs)
    end

    test "delete_role/1 deletes the role" do
      role = role_fixture()

      assert {:ok, _deleted_role} = CasinosRoles.delete_role(role.id)
    end

    test "change_role/1 returns a role changeset" do
      role = role_fixture()
      assert %Ecto.Changeset{} = CasinosRoles.change_role(role)
    end
  end
end
