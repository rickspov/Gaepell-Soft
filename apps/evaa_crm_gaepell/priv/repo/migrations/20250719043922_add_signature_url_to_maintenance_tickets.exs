defmodule EvaaCrmGaepell.Repo.Migrations.AddSignatureUrlToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :signature_url, :string
    end
  end
end
