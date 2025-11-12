defmodule EvaaCrmGaepell.Repo.Migrations.AddCheckoutFieldsToTickets do
  use Ecto.Migration

  def change do
    # Migración idempotente: solo agrega columnas si no existen
    execute """
      DO $$
      BEGIN
        -- maintenance_tickets
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_driver_cedula') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_driver_cedula varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_driver_name') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_driver_name varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_details') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_details text;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_photos') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_photos varchar(255)[] DEFAULT '{}';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_signature') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_signature text;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_signature_url') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_signature_url varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_date') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_date timestamp(0);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'checkout_notes') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN checkout_notes text;
        END IF;

        -- evaluations
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_driver_cedula') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_driver_cedula varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_driver_name') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_driver_name varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_details') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_details text;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_photos') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_photos varchar(255)[] DEFAULT '{}';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_signature') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_signature text;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_signature_url') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_signature_url varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_date') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_date timestamp(0);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'checkout_notes') THEN
          ALTER TABLE evaluations ADD COLUMN checkout_notes text;
        END IF;

        -- production_orders
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_driver_cedula') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_driver_cedula varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_driver_name') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_driver_name varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_details') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_details text;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_photos') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_photos varchar(255)[] DEFAULT '{}';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_signature') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_signature text;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_signature_url') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_signature_url varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_date') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_date timestamp(0);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'checkout_notes') THEN
          ALTER TABLE production_orders ADD COLUMN checkout_notes text;
        END IF;
      END $$;
    """

    # Crear índices solo si no existen
    execute """
      CREATE INDEX IF NOT EXISTS maintenance_tickets_checkout_date_index ON maintenance_tickets (checkout_date);
      CREATE INDEX IF NOT EXISTS evaluations_checkout_date_index ON evaluations (checkout_date);
      CREATE INDEX IF NOT EXISTS production_orders_checkout_date_index ON production_orders (checkout_date);
    """
  end
end
