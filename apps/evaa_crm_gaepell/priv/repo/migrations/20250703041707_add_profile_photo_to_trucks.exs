defmodule EvaaCrmGaepell.Repo.Migrations.AddProfilePhotoToTrucks do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      add :profile_photo, :string
    end
  end
end
