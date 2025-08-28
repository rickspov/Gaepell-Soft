defmodule EvaaCrmGaepell.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :title, :string, null: false
      add :description, :text
      add :category, :string, null: false
      add :files, {:array, :map}, default: []
      add :tags, {:array, :string}, default: []
      add :total_files, :integer, default: 0
      add :total_size, :bigint, default: 0
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :truck_id, references(:trucks, on_delete: :nilify_all)
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :nilify_all)
      add :evaluation_id, references(:evaluations, on_delete: :nilify_all)
      add :production_order_id, references(:production_orders, on_delete: :nilify_all)

      timestamps()
    end

    create index(:documents, [:business_id])
    create index(:documents, [:created_by_id])
    create index(:documents, [:truck_id])
    create index(:documents, [:maintenance_ticket_id])
    create index(:documents, [:evaluation_id])
    create index(:documents, [:production_order_id])
    create index(:documents, [:category])
    create index(:documents, [:inserted_at])
  end
end
