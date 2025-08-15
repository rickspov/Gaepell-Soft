defmodule EvaaCrmGaepell.Repo.Migrations.UpdateMaintenanceTicketStatuses do
  use Ecto.Migration

  def change do
    # Update existing tickets to use workflow states
    execute """
    UPDATE maintenance_tickets 
    SET status = CASE 
      WHEN status = 'open' THEN 'check_in'
      WHEN status = 'in_progress' THEN 'in_workshop'
      WHEN status = 'completed' THEN 'check_out'
      WHEN status = 'cancelled' THEN 'cancelled'
      ELSE 'check_in'
    END
    """, """
    UPDATE maintenance_tickets 
    SET status = CASE 
      WHEN status = 'check_in' THEN 'open'
      WHEN status = 'in_workshop' THEN 'in_progress'
      WHEN status = 'check_out' THEN 'completed'
      WHEN status = 'cancelled' THEN 'cancelled'
      ELSE 'open'
    END
    """
  end
end
