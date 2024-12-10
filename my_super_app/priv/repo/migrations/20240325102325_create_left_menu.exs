defmodule MySuperApp.Repo.Migrations.CreateLeftMenu do
  use Ecto.Migration

  def change do
    create table(:left_menu) do
      add :title, :string
    end
  end
end
