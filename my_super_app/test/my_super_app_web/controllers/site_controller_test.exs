defmodule MySuperAppWeb.SiteControllerTest do
  use MySuperAppWeb.ConnCase

  import MySuperApp.CasinoSitesFixtures

  alias MySuperApp.Site

  @create_attrs %{
    status: true,
    brand: "some brand",
    operator_id: 1
  }
  @update_attrs %{
    status: false,
    brand: "some updated brand",
    operator_id: 2
  }
  @invalid_attrs %{status: nil, brand: nil, operator_id: 2}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all sites", %{conn: conn} do
      conn = get(conn, ~p"/api/sites")
      assert length(json_response(conn, 200)["data"]) > 1
    end
  end

  describe "create site" do
    test "renders site when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/sites", site: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/sites/#{id}")

      assert %{
               "id" => ^id,
               "brand" => "some brand",
               "status" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/sites", site: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update site" do
    setup [:create_site]

    test "renders site when data is valid", %{conn: conn, site: %Site{id: id} = site} do
      conn = put(conn, ~p"/api/sites/#{site}", site: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/sites/#{id}")

      assert %{
               "id" => ^id,
               "brand" => "some updated brand",
               "status" => false
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, site: site} do
      conn = put(conn, ~p"/api/sites/#{site}", site: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete site" do
    setup [:create_site]

    test "deletes chosen site", %{conn: conn, site: site} do
      conn = delete(conn, ~p"/api/sites/#{site}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/sites/#{site}")
      end
    end
  end

  defp create_site(_) do
    site = site_fixture()
    %{site: site}
  end
end
