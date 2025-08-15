defmodule EvaaCrmGaepell.Repo.Migrations.AddColorToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :color, :string
    end
  end
end
