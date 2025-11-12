defmodule EvaaCrmGaepell.Repo.Migrations.AddTicketCodeToTickets do
  use Ecto.Migration

  def change do
    # Migración idempotente: solo agrega columnas si no existen
    execute """
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'ticket_code') THEN
          ALTER TABLE maintenance_tickets ADD COLUMN ticket_code varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evaluations' AND column_name = 'ticket_code') THEN
          ALTER TABLE evaluations ADD COLUMN ticket_code varchar(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'production_orders' AND column_name = 'ticket_code') THEN
          ALTER TABLE production_orders ADD COLUMN ticket_code varchar(255);
        END IF;
      END $$;
    """

    # Crear índices solo si no existen (cada uno en un execute separado)
    execute "CREATE INDEX IF NOT EXISTS maintenance_tickets_ticket_code_index ON maintenance_tickets (ticket_code)"
    execute "CREATE INDEX IF NOT EXISTS evaluations_ticket_code_index ON evaluations (ticket_code)"
    execute "CREATE INDEX IF NOT EXISTS production_orders_ticket_code_index ON production_orders (ticket_code)"
  end
end

