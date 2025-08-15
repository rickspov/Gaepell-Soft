defmodule EvaaCrmGaepell.Repo.Migrations.AddTruckAndMaintenanceTicketToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :truck_id, references(:trucks, on_delete: :nilify_all)
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :nilify_all)
    end
  end
end 