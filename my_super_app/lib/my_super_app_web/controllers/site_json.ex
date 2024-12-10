defmodule MySuperAppWeb.SiteJSON do
  alias MySuperApp.Site

  @doc """
  Renders a list of sites.
  """
  def index(%{sites: sites}) do
    %{data: for(site <- sites, do: data(site))}
  end

  @doc """
  Renders a single site.
  """
  def show(%{site: site}) do
    %{data: data(site)}
  end

  defp data(%Site{} = site) do
    %{
      id: site.id,
      brand: site.brand,
      status: site.status,
      operator_id: site.operator_id,
      inserted_at: site.inserted_at,
      operator_name: site.operator.name
    }
  end
end
