defmodule EvaaCrmGaepell.Repo.Migrations.AddKilometrajeToTrucks do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      add :kilometraje, :integer, default: 0, null: false
    end
  end
end
