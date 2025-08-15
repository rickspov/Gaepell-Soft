defmodule EvaaCrm.Repo.Migrations.CreateMaintenanceTickets do
  use Ecto.Migration

  def change do
    create table(:maintenance_tickets) do
      add :truck_id, references(:trucks, on_delete: :delete_all)
      add :entry_date, :utc_datetime
      add :mileage, :integer
      add :fuel_level, :string
      add :visible_damage, :text
      add :damage_photos, {:array, :string}, default: []
      add :responsible_signature, :text
      add :status, :string
      add :exit_date, :utc_datetime
      add :exit_notes, :text
      timestamps()
    end
    create index(:maintenance_tickets, [:truck_id])
  end
end
