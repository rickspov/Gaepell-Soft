defmodule EvaaCrmGaepell.Repo.Migrations.AddFichaToTrucks do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      add :ficha, :string
    end
  end
end
