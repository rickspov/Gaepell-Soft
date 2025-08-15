defmodule EvaaCrmGaepell.Repo.Migrations.AddEntryTypeToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :entry_type, :string, default: "maintenance" # "maintenance" | "production"
      add :quotation_id, references(:quotations) # Para órdenes de producción
      add :production_status, :string, default: "pending_quote" # Para órdenes de producción
    end
  end
end
