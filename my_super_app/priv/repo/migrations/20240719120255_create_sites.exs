defmodule MySuperApp.Repo.Migrations.CreateSites do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :brand, :string
      add :status, :boolean, default: false
      add :operator_id, references(:operators, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sites, [:brand])
    create index(:sites, [:operator_id])
  end
end
