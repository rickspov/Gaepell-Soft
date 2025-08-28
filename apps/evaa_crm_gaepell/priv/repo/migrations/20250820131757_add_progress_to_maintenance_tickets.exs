defmodule EvaaCrmGaepell.Repo.Migrations.AddProgressToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :progress, :integer, default: 0
    end
  end
end
