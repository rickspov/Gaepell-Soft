defmodule EvaaCrmGaepell.Repo.Migrations.UpdateProductionWorkflowStatesFurcar do
  use Ecto.Migration

  def change do
    # Primero eliminamos los estados actuales del workflow de producción de Furcar
    execute """
    DELETE FROM workflow_states 
    WHERE workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'production' AND business_id = 1
    );
    """

    # Insertamos los nuevos estados según el flujo requerido
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