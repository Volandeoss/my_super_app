defmodule MySuperApp.Repo.Migrations.AddTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :title, :string

      timestamps(type: :utc_datetime)
    end
  end
end
