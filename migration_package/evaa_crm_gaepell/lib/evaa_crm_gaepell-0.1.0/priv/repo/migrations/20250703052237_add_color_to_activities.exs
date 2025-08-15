defmodule EvaaCrmGaepell.Repo.Migrations.AddColorToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :color, :string
    end
  end
end
