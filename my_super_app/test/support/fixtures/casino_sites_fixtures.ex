defmodule MySuperApp.CasinoSitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.CasinoSites` context.
  """

  @doc """
  Generate a site.
  """
  def site_fixture(attrs \\ %{}) do
    {:ok, site} =
      attrs
      |> Enum.into(%{
        brand: "some brand",
        status: true,
        operator_id: 1
      })
      |> MySuperApp.CasinoSites.create_site()

    site
  end
end
