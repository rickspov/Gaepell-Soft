defmodule EvaaCrmGaepell.Repo.Migrations.AddBoxTypeAndEstimatedDeliveryToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :box_type, :string
      add :estimated_delivery, :date
    end
  end
end
