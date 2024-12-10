defmodule MySuperApp.CasinoSites do
  @moduledoc false

  alias Ecto.Changeset
  alias MySuperApp.{Repo, Site}
  import Ecto.Query

  def subscribe() do
    Phoenix.PubSub.subscribe(MySuperApp.PubSub, "sites")
  end

  def broadcast(message) do
    Phoenix.PubSub.broadcast(MySuperApp.PubSub, "sites", message)
  end

  def create_site(attrs \\ %{}) do
    with %Changeset{valid?: true} = changeset <- %Site{} |> Site.changeset(attrs),
         {:ok, site} <- Repo.insert(changeset) do
      broadcast({:site_created, site})

      {:ok, site |> Repo.preload([:operator])}
    else
      _ -> {:error, "something went wrong"}
    end
  end

  def get_sites() do
    Site
    |> Repo.all()
    |> Enum.map(fn x -> Map.from_struct(x) end)
  end

  def delete_all() do
    Site |> Repo.delete_all()
  end

  def get_sites_with_operators(offset, limit, [{key, value}], filter, from, to) do
    order = value |> String.downcase() |> String.to_atom()

    query =
      from site in Site,
        join: operator in assoc(site, :operator),
        on: site.operator_id == operator.id,
        offset: ^offset,
        limit: ^limit,
        select: %{
          id: site.id,
          status: site.status,
          inserted_at: site.inserted_at,
          updated_at: site.updated_at,
          brand: site.brand,
          operator_name: operator.name,
          operator_id: operator.id
        }

    query
    |> get_order_by_clause(order, key)
    |> apply_filter(filter)
    |> apply_time(from, to)
    |> Repo.all()
  end

  def get_sites_with_operators([{key, value}], filter, from, to) do
    order = value |> String.downcase() |> String.to_atom()

    query =
      from site in Site,
        join: operator in assoc(site, :operator),
        on: site.operator_id == operator.id,
        select: %{
          id: site.id,
          status: site.status,
          inserted_at: site.inserted_at,
          updated_at: site.updated_at,
          brand: site.brand,
          operator_name: operator.name,
          operator_id: operator.id
        }

    query
    |> get_order_by_clause(order, key)
    |> apply_time(from, to)
    |> apply_filter(filter)
    |> Repo.all()
  end

  defp get_order_by_clause(query, order, :operator_name) do
    from [site, operator] in query, order_by: [{^order, operator.name}]
  end

  defp get_order_by_clause(query, order, key) do
    from [site] in query, order_by: [{^order, field(site, ^key)}]
  end

  defp apply_time(query, "", "") do
    query
  end

  defp apply_time(query, from, "") do
    from [site] in query, where: site.inserted_at >= ^from
  end

  defp apply_time(query, "", to) do
    from [site] in query, where: site.inserted_at <= ^to
  end

  defp apply_time(query, from, to) do
    from [site] in query, where: site.inserted_at >= ^from and site.inserted_at <= ^to
  end

  defp apply_filter(query, filter) do
    if numeric?(filter) do
      from [site] in query, where: site.id == ^filter
    else
      from [site, operator] in query,
        where: ilike(operator.name, ^"%#{filter}%") or ilike(site.brand, ^"%#{filter}%")
    end
  end

  defp numeric?(string) do
    String.match?(string, ~r/^\d+$/)
  end

  def change_time(attrs) do
    %Site{}
    |> Site.changeset_time(attrs)
    |> Map.put(:action, :insert)
  end

  def clear_time_form() do
    Site.changeset_time(%Site{}, %{inserted_at: "", updated_at: ""})
  end

  def clear_form() do
    Site.changeset(%Site{}, %{})
  end

  def change_form(attrs) do
    %Site{}
    |> Site.changeset(attrs)
    |> Map.put(:action, :insert)
  end

  def get_sites_with_operators() do
    Repo.all(
      from site in Site,
        join: operator in assoc(site, :operator),
        on: site.operator_id == operator.id,
        order_by: site.id,
        select: %{
          id: site.id,
          inserted_at: site.inserted_at,
          updated_at: site.updated_at,
          brand: site.brand,
          status: site.status,
          operator_name: operator.name,
          operator_id: operator.id
        }
    )
  end

  def delete_site(site: site) do
    Repo.delete(site)
  end

  def delete_site(id) do
    site = Repo.get(Site, id)
    Repo.delete(site)
  end

  def update_site_status(id) do
    site = Repo.get(Site, id)

    Site.changeset(site, %{status: !site.status})
    |> Repo.update()
  end

  def get_sites_count do
    query = from(u in Site, select: count(u))
    Repo.aggregate(query, :count) - 1
  end

  @doc """
  Returns the list of sites.

  ## Examples

      iex> list_sites()
      [%Site{}, ...]

  """
  def list_sites do
    Repo.all(Site) |> Repo.preload([:operator])
  end

  def list_sites(from, to) do
    Repo.all(
      from s in Site,
        preload: :operator,
        where: s.inserted_at >= ^from and s.inserted_at <= ^to
    )
  end

  def list_sites(author: author) do
    Repo.all(
      from s in Site,
        join: operator in assoc(s, :operator),
        preload: :operator,
        where: ilike(operator.name, ^"%#{author}%")
    )
  end

  @doc """
  Gets a single site.

  Raises `Ecto.NoResultsError` if the Site does not exist.

  ## Examples

      iex> get_site!(123)
      %Site{}

      iex> get_site!(456)
      ** (Ecto.NoResultsError)

  """
  def get_site!(id), do: Repo.get!(Site, id) |> Repo.preload([:operator])
  def get_site(id), do: Repo.get(Site, id) |> Repo.preload([:operator])

  @doc """
  Updates a site.

  ## Examples

      iex> update_site(site, %{field: new_value})
      {:ok, %Site{}}

      iex> update_site(site, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_site(%Site{} = site, attrs) do
    with %Ecto.Changeset{valid?: true} = site_change <- site |> Site.changeset(attrs),
         {:ok, site} <- Repo.update(site_change) do
      {:ok, site |> Repo.preload([:operator])}
    else
      _ -> {:error, :check_params}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking site changes.

  ## Examples

      iex> change_site(site)
      %Ecto.Changeset{data: %Site{}}

  """
  def change_site(%Site{} = site, attrs \\ %{}) do
    Site.changeset(site, attrs)
  end
end
