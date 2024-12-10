defmodule MySuperApp.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :room_number, :integer
    end
  end
end
