defmodule MySuperApp.SiteCreationWorker do
  @moduledoc """
    creates site every hour inside dev.exs
  """
  use Oban.Worker, queue: :default, max_attempts: 3
  alias MySuperApp.CasinoSites

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    if length(CasinoSites.get_sites()) < 50 do
      CasinoSites.create_site(%{
        brand: "Oban_#{Faker.Commerce.En.department()}",
        status: true,
        operator_id: :rand.uniform(5)
      })

      :ok
    else
      :ok
    end
  end
end
