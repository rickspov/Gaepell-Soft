defmodule EvaaCrmGaepell.Repo.Migrations.CreateActivityLogs do
  use Ecto.Migration

  def change do
    create table(:activity_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :entity_type, :string, null: false  # "maintenance_ticket", "truck", "user", etc.
      add :entity_id, :integer, null: false   # ID del registro relacionado
      add :action, :string, null: false       # "created", "updated", "status_changed", "commented", etc.
      add :description, :text, null: false    # Descripción legible de la acción
      add :old_values, :map                   # Valores anteriores (opcional)
      add :new_values, :map                   # Valores nuevos (opcional)
      add :metadata, :map                     # Datos adicionales (comentarios, archivos, etc.)
      add :user_id, references(:users), null: false
      add :business_id, references(:businesses), null: false

      timestamps()
    end

    # Índices para optimizar consultas
    create index(:activity_logs, [:entity_type, :entity_id])
    create index(:activity_logs, [:user_id])
    create index(:activity_logs, [:business_id])
    create index(:activity_logs, [:inserted_at])
    create index(:activity_logs, [:action])
  end
end
