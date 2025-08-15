defmodule EvaaCrmGaepell.Repo.Migrations.FixMultipleProductionWorkflows do
  use Ecto.Migration

  def change do
    # First, let's see what we have and clean up duplicates
    # Keep only the most recent production workflow for each business
    
    # For business_id = 1 (Furcar), keep the one with the correct states
    execute """
    DELETE FROM workflows 
    WHERE id NOT IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY inserted_at DESC) as rn
        FROM workflows 
        WHERE workflow_type = 'production' AND business_id = 1
      ) ranked 
      WHERE rn = 1
    ) AND workflow_type = 'production' AND business_id = 1;
    """
    
    # For business_id = 2 (Blidomca), keep only one
    execute """
    DELETE FROM workflows 
    WHERE id NOT IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY inserted_at DESC) as rn
        FROM workflows 
        WHERE workflow_type = 'production' AND business_id = 2
      ) ranked 
      WHERE rn = 1
    ) AND workflow_type = 'production' AND business_id = 2;
    """
    
    # For business_id = 3 (Polimat), keep only one
    execute """
    DELETE FROM workflows 
    WHERE id NOT IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY inserted_at DESC) as rn
        FROM workflows 
        WHERE workflow_type = 'production' AND business_id = 3
      ) ranked 
      WHERE rn = 1
    ) AND workflow_type = 'production' AND business_id = 3;
    """
    
    # Clean up orphaned workflow states
    execute """
    DELETE FROM workflow_states 
    WHERE workflow_id NOT IN (SELECT id FROM workflows);
    """
    
    # Ensure we have the correct production workflow states for Furcar (business_id = 1)
    # Get the workflow ID for Furcar production
    execute """
    DELETE FROM workflow_states 
    WHERE workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'production' AND business_id = 1
    );
    """
    
    # Insert the correct states for Furcar production workflow
    execute """
    INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) 
    SELECT 'new_order', 'Nueva Orden', '#6B7280', 1, id, NOW(), NOW() 
    FROM workflows WHERE workflow_type = 'production' AND business_id = 1;
    """
    
    execute """
    INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) 
    SELECT 'reception', 'Recepción', '#F59E0B', 2, id, NOW(), NOW() 
    FROM workflows WHERE workflow_type = 'production' AND business_id = 1;
    """
    
    execute """
    INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) 
    SELECT 'assembly', 'Ensamblaje', '#3B82F6', 3, id, NOW(), NOW() 
    FROM workflows WHERE workflow_type = 'production' AND business_id = 1;
    """
    
    execute """
    INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) 
    SELECT 'mounting', 'Montaje', '#8B5CF6', 4, id, NOW(), NOW() 
    FROM workflows WHERE workflow_type = 'production' AND business_id = 1;
    """
    
    execute """
    INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) 
    SELECT 'final_check', 'Final Check', '#10B981', 5, id, NOW(), NOW() 
    FROM workflows WHERE workflow_type = 'production' AND business_id = 1;
    """
    
    execute """
    INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) 
    SELECT 'check_out', 'Check Out', '#059669', 6, id, NOW(), NOW() 
    FROM workflows WHERE workflow_type = 'production' AND business_id = 1;
    """
  end
end
