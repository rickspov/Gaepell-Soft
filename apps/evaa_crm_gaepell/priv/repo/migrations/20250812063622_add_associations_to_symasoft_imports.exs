defmodule EvaaCrmGaepell.Repo.Migrations.AddAssociationsToSymasoftImports do
  use Ecto.Migration

  def change do
    alter table(:symasoft_imports) do
      # Vincular con camión
      add :truck_id, references(:trucks, on_delete: :nilify_all)
      
      # Vincular con tickets (mantenimiento, evaluación, orden de producción)
      add :maintenance_ticket_id, references(:maintenance_tickets, on_delete: :nilify_all)
      add :production_order_id, references(:production_orders, on_delete: :nilify_all)
      
      # Campos adicionales para la cotización
      add :quotation_number, :string
      add :quotation_date, :date
      add :quotation_amount, :decimal, precision: 10, scale: 2
      add :quotation_status, :string, default: "pending"
      add :quotation_notes, :text
    end

    # Crear índices para mejorar el rendimiento
    create index(:symasoft_imports, [:truck_id])
    create index(:symasoft_imports, [:maintenance_ticket_id])
    create index(:symasoft_imports, [:production_order_id])
    create index(:symasoft_imports, [:quotation_number])
    create index(:symasoft_imports, [:quotation_status])
  end
end
