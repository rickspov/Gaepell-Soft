defmodule EvaaCrmGaepell.Repo.Migrations.AddFieldsToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      add :title, :string
      add :description, :text
      add :priority, :string, default: "medium"
      add :business_id, references(:businesses, on_delete: :delete_all)
      add :specialist_id, references(:specialists, on_delete: :nilify_all)
    end

    create index(:maintenance_tickets, [:business_id])
    create index(:maintenance_tickets, [:specialist_id])
  end
end 