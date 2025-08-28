defmodule EvaaCrmGaepell.Repo.Migrations.AddWarrantyDetailsToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :warranty_details, :text
    end
  end
end
