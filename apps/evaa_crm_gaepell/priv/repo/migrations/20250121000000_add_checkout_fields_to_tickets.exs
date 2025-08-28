defmodule EvaaCrmGaepell.Repo.Migrations.AddCheckoutFieldsToTickets do
  use Ecto.Migration

  def change do
    # Agregar campos de check-out a maintenance_tickets
    alter table(:maintenance_tickets) do
      add :checkout_driver_cedula, :string
      add :checkout_driver_name, :string
      add :checkout_details, :text
      add :checkout_photos, {:array, :string}, default: []
      add :checkout_signature, :text
      add :checkout_signature_url, :string
      add :checkout_date, :utc_datetime
      add :checkout_notes, :text
    end

    # Agregar campos de check-out a evaluations
    alter table(:evaluations) do
      add :checkout_driver_cedula, :string
      add :checkout_driver_name, :string
      add :checkout_details, :text
      add :checkout_photos, {:array, :string}, default: []
      add :checkout_signature, :text
      add :checkout_signature_url, :string
      add :checkout_date, :utc_datetime
      add :checkout_notes, :text
    end

    # Agregar campos de check-out a production_orders
    alter table(:production_orders) do
      add :checkout_driver_cedula, :string
      add :checkout_driver_name, :string
      add :checkout_details, :text
      add :checkout_photos, {:array, :string}, default: []
      add :checkout_signature, :text
      add :checkout_signature_url, :string
      add :checkout_date, :utc_datetime
      add :checkout_notes, :text
    end

    # Crear índices para mejorar el rendimiento
    create index(:maintenance_tickets, [:checkout_date])
    create index(:evaluations, [:checkout_date])
    create index(:production_orders, [:checkout_date])
  end
end
