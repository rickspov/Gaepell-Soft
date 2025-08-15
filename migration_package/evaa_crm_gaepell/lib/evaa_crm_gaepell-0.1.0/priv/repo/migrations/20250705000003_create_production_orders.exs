defmodule EvaaCrmGaepell.Repo.Migrations.CreateProductionOrders do
  use Ecto.Migration

  def change do
    create table(:production_orders) do
      add :client_name, :string, null: false
      add :truck_brand, :string, null: false
      add :truck_model, :string, null: false
      add :license_plate, :string, null: false
      add :box_type, :string, null: false
      add :specifications, :text
      add :estimated_delivery, :date, null: false
      add :status, :string, default: "new_order", null: false
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :specialist_id, references(:specialists, on_delete: :nilify_all)
      add :workflow_id, references(:workflows, on_delete: :nilify_all)
      add :workflow_state_id, references(:workflow_states, on_delete: :nilify_all)
      add :notes, :text
      add :actual_delivery_date, :date
      add :total_cost, :decimal, precision: 10, scale: 2
      add :materials_used, :text
      add :quality_check_notes, :text
      add :customer_signature, :text
      add :photos, {:array, :string}

      timestamps()
    end

    create index(:production_orders, [:business_id])
    create index(:production_orders, [:status])
    create index(:production_orders, [:workflow_id])
    create index(:production_orders, [:workflow_state_id])
    create index(:production_orders, [:specialist_id])
  end
end 