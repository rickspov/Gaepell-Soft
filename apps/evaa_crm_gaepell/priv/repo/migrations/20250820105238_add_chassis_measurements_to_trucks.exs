defmodule EvaaCrmGaepell.Repo.Migrations.AddChassisMeasurementsToTrucks do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      add :chassis_width, :integer, comment: "Ancho de goma a goma traseras (cm)"
      add :chassis_length, :integer, comment: "Largo útil del chasis (cm)"
    end
  end
end
