defmodule EvaaCrmGaepell.Repo.Migrations.AddDurationToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :duration_minutes, :integer, default: 60
    end
  end
end
