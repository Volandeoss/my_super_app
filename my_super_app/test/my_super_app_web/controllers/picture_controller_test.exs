defmodule MySuperAppWeb.PictureControllerTest do
  use MySuperAppWeb.ConnCase

  alias MySuperApp.Blog

  @valid_attrs %{
    "file" => %Plug.Upload{
      path: "/home/support/Downloads/cOOOL_SHET.jpg",
      filename: "test_picture.jpg"
    }
  }

  @invalid_attrs %{
    "file" => nil
  }

  # Preload some sample data for tests
  setup do
    picture =
      Blog.api_create_picture(%{
        path: "/path/to/file.jpg",
        file_name: "test_picture.jpg",
        post_id: 1
      })

    {:ok, picture: picture}
  end

  describe "index/2" do
    test "lists all pictures", %{conn: conn} do
      conn = get(conn, ~p"/api/pictures")
      assert json_response(conn, 200)["pictures"] != []
    end

    test "filters pictures by period", %{conn: conn} do
      from = DateTime.utc_now() |> DateTime.to_iso8601()
      to = DateTime.utc_now() |> DateTime.add(3600) |> DateTime.to_iso8601()

      conn = get(conn, ~p"/api/pictures", %{"from" => from, "to" => to})
      assert json_response(conn, 200)["pictures"] != []
    end

    test "sorts pictures by key and order", %{conn: conn} do
      conn = get(conn, ~p"/api/pictures", %{"order" => "asc", "key" => "id"})
      assert json_response(conn, 200)["pictures"] != []
    end
  end

  describe "create/2" do
    test "creates a picture with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/pictures", @valid_attrs)
      refute nil = json_response(conn, 201)["picture"]
    end

    test "returns error when creating with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/pictures", @invalid_attrs)
      assert json_response(conn, 422)["error"] == "Invalid or missing parameters."
    end
  end

  describe "show/2" do
    test "shows the picture", %{conn: conn, picture: _picture} do
      conn = get(conn, ~p"/api/pictures/")
      assert json_response(conn, 200)["picture"] == nil
    end

    test "returns error for non-existing picture", %{conn: conn} do
      conn = get(conn, ~p"/api/pictures/9999")
      assert json_response(conn, 404)["error"] == nil
    end
  end

  describe "update/2" do
    test "returns error when updating with invalid data", %{conn: conn, picture: _picture} do
      conn = put(conn, ~p"/api/pictures/1}", %{"file" => nil})

      assert %{"error" => "Invalid params"} = json_response(conn, 400)
    end
  end
end
