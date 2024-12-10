defmodule MySuperAppWeb.RoleControllerTest do
  use MySuperAppWeb.ConnCase

  import MySuperApp.CasinosRolesFixtures

  alias MySuperApp.Role

  @create_attrs %{
    name: "some name",
    operator_id: "1"
  }
  @update_attrs %{
    name: "some updated name",
    operator_id: "2"
  }
  @invalid_attrs %{name: nil, operator_id: "2"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all roles", %{conn: conn} do
      role1 = role_fixture()
      role2 = role_fixture()

      conn = get(conn, ~p"/api/roles")

      response_data = json_response(conn, 200)["data"]

      assert length(response_data) >= 2
      assert Enum.any?(response_data, fn role -> role["id"] == role1.id end)
      assert Enum.any?(response_data, fn role -> role["id"] == role2.id end)
    end
  end

  describe "create role" do
    test "renders role when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", role: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/roles/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", role: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update role" do
    setup [:create_role]

    test "renders role when data is valid", %{conn: conn, role: %Role{id: id} = role} do
      conn = put(conn, ~p"/api/roles/#{role}", role: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/roles/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, role: role} do
      conn = put(conn, ~p"/api/roles/#{role}", role: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete role" do
    setup [:create_role]

    test "deletes chosen role", %{conn: conn, role: role} do
      conn = delete(conn, ~p"/api/roles/#{role}")
      assert response(conn, 200)
    end
  end

  defp create_role(_) do
    role = role_fixture()
    %{role: role}
  end
end
