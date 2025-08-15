defmodule EvaaCrmGaepell.Repo.Migrations.CreateTruckPhotos do
  use Ecto.Migration

  def change do
    create table(:truck_photos) do
      add :photo_path, :string, null: false
      add :description, :text
      add :photo_type, :string, default: "general" # "general", "damage", "maintenance", "before", "after"
      add :truck_id, references(:trucks, on_delete: :delete_all), null: false
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :nilify_all)
      add :uploaded_at, :utc_datetime, null: false, default: fragment("NOW()")

      timestamps()
    end

    create index(:truck_photos, [:truck_id])
    create index(:truck_photos, [:maintenance_ticket_id])
    create index(:truck_photos, [:user_id])
    create index(:truck_photos, [:photo_type])
    create index(:truck_photos, [:uploaded_at])
  end
end
