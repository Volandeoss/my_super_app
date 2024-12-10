defmodule MySuperApp.Repo.Migrations.CreatePictures do
  use Ecto.Migration

  def change do
    create table(:pictures) do
      add :file_name, :string
      add :path, :string
      add :post_id, references(:posts, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end
  end
end
