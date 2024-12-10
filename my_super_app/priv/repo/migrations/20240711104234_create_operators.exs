defmodule MySuperApp.Repo.Migrations.AddOperators do
  use Ecto.Migration

  def change do
    create table(:operators) do
      add :name, :string
      timestamps(type: :utc_datetime)
    end
  end
end
