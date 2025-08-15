defmodule EvaaCrmGaepell.Repo.Migrations.CreateTruckNotes do
  use Ecto.Migration

  def change do
    create table(:truck_notes) do
      add :content, :text, null: false
      add :note_type, :string, default: "general"  # general, maintenance, production, etc.
      add :truck_id, references(:trucks, on_delete: :delete_all), null: false
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :nilify_all)
      add :production_order_id, references(:production_orders, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :nilify_all), null: false
      add :business_id, references(:businesses, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:truck_notes, [:truck_id])
    create index(:truck_notes, [:maintenance_ticket_id])
    create index(:truck_notes, [:production_order_id])
    create index(:truck_notes, [:user_id])
    create index(:truck_notes, [:business_id])
    create index(:truck_notes, [:inserted_at])
  end
end
