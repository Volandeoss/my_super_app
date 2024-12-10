defmodule MySuperApp.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string
      add :operator_id, references(:operators)
      timestamps(type: :utc_datetime)
    end
  end
end
