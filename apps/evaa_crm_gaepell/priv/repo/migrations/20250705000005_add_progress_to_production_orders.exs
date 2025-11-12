defmodule EvaaCrmGaepell.Repo.Migrations.AddProgressToProductionOrders do
  use Ecto.Migration

  def change do
    # Verificar si la columna ya existe antes de agregarla
    # Esto hace la migración idempotente (segura de ejecutar múltiples veces)
    execute """
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'production_orders' 
          AND column_name = 'progress'
        ) THEN
          ALTER TABLE production_orders ADD COLUMN progress integer DEFAULT 0;
        END IF;
      END $$;
    """
  end
end

