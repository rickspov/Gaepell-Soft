defmodule EvaaCrmGaepell.Repo.Migrations.CreateMaintenanceTicketCheckouts do
  use Ecto.Migration

  def change do
    create table(:maintenance_ticket_checkouts) do
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :delete_all), null: false
      add :delivered_to_name, :string, null: false
      add :delivered_to_id_number, :string
      add :delivered_to_phone, :string
      add :delivered_at, :naive_datetime, null: false
      add :photos, {:array, :string}, default: []
      add :signature, :text
      add :notes, :text
      timestamps()
    end
    create index(:maintenance_ticket_checkouts, [:maintenance_ticket_id])
  end
end 