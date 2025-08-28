defmodule EvaaCrmGaepell.Repo.Migrations.CreateTruckDocuments do
  use Ecto.Migration

  def change do
    create table(:truck_documents) do
      add :file_path, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :document_type, :string, default: "pdf"
      add :uploaded_at, :utc_datetime
      add :truck_id, references(:trucks, on_delete: :delete_all), null: false
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:truck_documents, [:truck_id])
    create index(:truck_documents, [:maintenance_ticket_id])
    create index(:truck_documents, [:user_id])
    create index(:truck_documents, [:document_type])
  end
end
