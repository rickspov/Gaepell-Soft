defmodule EvaaCrm.Repo.Migrations.CreateTrucks do
  use Ecto.Migration

  def change do
    create table(:trucks) do
      add :brand, :string
      add :model, :string
      add :license_plate, :string
      add :chassis_number, :string
      add :vin, :string
      add :color, :string
      add :year, :integer
      add :owner, :string
      add :general_notes, :text
      timestamps()
    end
  end
end
