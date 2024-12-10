defmodule MySuperApp.SitesTest do
  use ExUnit.Case, async: true
  alias MySuperApp.Repo
  alias MySuperApp.{Site, CasinoSites, Operator}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    operator = Repo.insert!(%Operator{name: "Test Operator"})
    Repo.insert!(%Site{brand: "Test Brand", operator_id: operator.id})

    %{operator: operator}
  end

  test "retrieves sites with operators" do
    sites = MySuperApp.CasinoSites.get_sites_with_operators(0, 10, [id: "asc"], "", "", "")

    assert length(sites) > 1
    assert is_binary(Enum.at(sites, 0).operator_name) == true
  end

  test "filters sites by operator name" do
    sites =
      MySuperApp.CasinoSites.get_sites_with_operators(
        0,
        10,
        [operator_name: "asc"],
        "Test Operator",
        "",
        ""
      )

    assert length(sites) == 1
    assert Enum.at(sites, 0).operator_name == "Test Operator"
  end

  test "orders sites by brand", %{operator: operator} do
    Repo.insert!(%Site{brand: "Another Brand", operator_id: operator.id})
    sites = MySuperApp.CasinoSites.get_sites_with_operators(0, 10, [brand: "asc"], "", "", "")

    assert is_binary(Enum.at(sites, 0).brand) == true
  end

  test "filters sites within date range" do
    now = NaiveDateTime.utc_now()
    # 1 hour ago
    from_time = NaiveDateTime.add(now, -3600, :second)
    # 1 hour later
    to_time = NaiveDateTime.add(now, 3600, :second)

    sites =
      MySuperApp.CasinoSites.get_sites_with_operators(0, 10, [id: "asc"], "", from_time, to_time)

    assert length(sites) == 1
  end

  describe "sites" do
    alias MySuperApp.Site

    import MySuperApp.CasinoSitesFixtures

    @invalid_attrs %{status: nil, brand: nil}

    test "list_sites/0 returns all sites" do
      site_fixture()
      assert length(CasinoSites.list_sites()) > 1
    end

    test "get_site!/1 returns the site with given id" do
      site = site_fixture()
      assert CasinoSites.get_site!(site.id) == site
    end

    test "create_site/1 with valid data creates a site" do
      valid_attrs = %{status: true, brand: "some brand", operator_id: 1}

      assert {:ok, %Site{} = site} = CasinoSites.create_site(valid_attrs)
      assert site.status == true
      assert site.brand == "some brand"
    end

    test "create_site/1 with invalid data returns error changeset" do
      assert {:error, "something went wrong"} = CasinoSites.create_site(@invalid_attrs)
    end

    test "update_site/2 with valid data updates the site" do
      update_attrs = %{status: false, brand: "some updated brand"}

      assert {:ok, %Site{} = site} = CasinoSites.update_site(site_fixture(), update_attrs)
      assert site.status == false
      assert site.brand == "some updated brand"
    end

    test "update_site/2 with invalid data returns error changeset" do
      site = site_fixture()
      assert {:error, :check_params} = CasinoSites.update_site(site, @invalid_attrs)
      assert site == CasinoSites.get_site!(site.id)
    end

    test "delete_site/1 deletes the site" do
      site = site_fixture()
      assert {:ok, %Site{}} = CasinoSites.delete_site(site: site)
      assert_raise Ecto.NoResultsError, fn -> CasinoSites.get_site!(site.id) end
    end

    test "change_site/1 returns a site changeset" do
      site = site_fixture()
      assert %Ecto.Changeset{} = CasinoSites.change_site(site)
    end
  end
end
