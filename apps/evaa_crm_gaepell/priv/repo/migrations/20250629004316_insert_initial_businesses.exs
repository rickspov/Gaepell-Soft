defmodule EvaaCrm.Repo.Migrations.InsertInitialBusinesses do
  use Ecto.Migration

  def change do
    # Insertar businesses iniciales
    execute "INSERT INTO businesses (id, name, inserted_at, updated_at) VALUES (1, 'Furcar', NOW(), NOW()) ON CONFLICT (id) DO NOTHING;"
    execute "INSERT INTO businesses (id, name, inserted_at, updated_at) VALUES (2, 'Blidomca', NOW(), NOW()) ON CONFLICT (id) DO NOTHING;"
    execute "INSERT INTO businesses (id, name, inserted_at, updated_at) VALUES (3, 'Polimat', NOW(), NOW()) ON CONFLICT (id) DO NOTHING;"
  end
end
