defmodule MySuperAppWeb.SiteController do
  use MySuperAppWeb, :controller

  alias MySuperApp.CasinoSites
  alias MySuperApp.Site

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"from" => from, "to" => to}) do
    with {:ok, from_datetime, _} <- DateTime.from_iso8601(from),
         {:ok, to_datetime, _} <- DateTime.from_iso8601(to) do
      sites = CasinoSites.list_sites(from_datetime, to_datetime)
      render(conn, :index, sites: sites)
    else
      _ ->
        {:error, :check_params}
    end
  end

  def index(conn, %{"author" => author}) do
    sites = CasinoSites.list_sites(author: author)
    render(conn, :index, sites: sites)
  end

  def index(conn, _params) do
    start_time = System.monotonic_time()

    sites = CasinoSites.list_sites()

    duration = System.monotonic_time() - start_time

    :telemetry.execute([:my_super_app, :api, :request], %{duration: duration}, %{
      controller: "MySuperAppWeb.SiteController",
      action: "index",
      status: conn.status,
      function: "index/2"
    })

    IO.puts(duration)

    render(conn, :index, sites: sites)
  end

  def create(conn, %{"site" => site_params}) do
    case CasinoSites.create_site(site_params) do
      {:ok, %Site{} = site} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/sites/#{site}")
        |> render(:show, site: site)

      _ ->
        {:error, "needs to be unique"}
    end
  end

  def show(conn, %{"id" => id}) do
    site = CasinoSites.get_site!(id)
    render(conn, :show, site: site)
  end

  def update(conn, %{"id" => id, "site" => site_params}) do
    site = CasinoSites.get_site!(id)

    with {:ok, %Site{} = site} <- CasinoSites.update_site(site, site_params) do
      render(conn, :show, site: site)
    end
  end

  def delete(conn, %{"id" => id}) do
    site = CasinoSites.get_site(id)

    with true <- site != nil,
         {:ok, %Site{}} <- CasinoSites.delete_site(site: site) do
      send_resp(conn, :no_content, "")
    else
      _ -> {:error, :not_found}
    end
  end
end
