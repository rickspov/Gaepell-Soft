defmodule EvaaCrmGaepell.Repo.Migrations.AddExitDateToProductionOrders do
  use Ecto.Migration

  def change do
    # Migración idempotente: solo agrega la columna si no existe
    execute """
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'production_orders' 
          AND column_name = 'exit_date'
        ) THEN
          ALTER TABLE production_orders ADD COLUMN exit_date timestamp(0);
        END IF;
      END $$;
    """
  end
end


