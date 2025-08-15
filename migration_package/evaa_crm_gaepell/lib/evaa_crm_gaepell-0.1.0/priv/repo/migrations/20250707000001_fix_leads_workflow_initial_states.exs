defmodule EvaaCrmGaepell.Repo.Migrations.FixLeadsWorkflowInitialStates do
  use Ecto.Migration

  def change do
    # Marcar el estado "new" como inicial en todos los workflows de leads
    execute """
    UPDATE workflow_states 
    SET is_initial = true 
    WHERE name = 'new' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads'
    );
    """, """
    UPDATE workflow_states 
    SET is_initial = false 
    WHERE name = 'new' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads'
    );
    """
  end
end 