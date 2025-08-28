defmodule EvaaCrmGaepell.Repo.Migrations.AddTechnicalMeasurementsToTrucks do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      add :rear_tire_width, :integer, comment: "Ancho gomas traseras (cm)"
      add :useful_length, :integer, comment: "Largo útil (cm)"
    end
  end
end
