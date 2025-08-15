defmodule EvaaCrmGaepell.Repo.Migrations.AddMissingBusinessPolimat do
  use Ecto.Migration

  def change do
    execute "INSERT INTO businesses (id, name, inserted_at, updated_at) VALUES (3, 'Polimat', NOW(), NOW()) ON CONFLICT (id) DO NOTHING;"
  end
end
