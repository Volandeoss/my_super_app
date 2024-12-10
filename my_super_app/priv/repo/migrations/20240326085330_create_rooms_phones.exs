defmodule MySuperApp.Repo.Migrations.CreateRoomsPhones do
  use Ecto.Migration

  def change do
    create table(:rooms_phones, primary_key: false) do
      add :room_id, references(:rooms)
      add :phone_id, references(:phones)
    end

    create unique_index(:rooms_phones, [:room_id, :phone_id])
  end
end
