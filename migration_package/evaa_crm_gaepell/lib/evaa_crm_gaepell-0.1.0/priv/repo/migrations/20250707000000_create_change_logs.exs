defmodule EvaaCrmGaepell.Repo.Migrations.CreateChangeLogs do
  use Ecto.Migration

  def change do
    create table(:change_logs) do
      add :entity_type, :string, null: false
      add :entity_id, :integer, null: false
      add :field, :string, null: false
      add :old_value, :string
      add :new_value, :string
      add :user_id, references(:users)
      timestamps()
    end
    create index(:change_logs, [:entity_type, :entity_id])
    create index(:change_logs, [:user_id])
  end
end 