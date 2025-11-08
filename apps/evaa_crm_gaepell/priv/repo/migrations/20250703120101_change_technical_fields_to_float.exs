defmodule EvaaCrmGaepell.Repo.Migrations.ChangeTechnicalFieldsToFloat do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      modify :rear_tire_width, :float
      modify :useful_length, :float
      modify :chassis_length, :float
      modify :chassis_width, :float
    end
  end
end