defmodule MySuperApp.Repo do
  use Ecto.Repo,
    otp_app: :my_super_app,
    adapter: Ecto.Adapters.Postgres
end
