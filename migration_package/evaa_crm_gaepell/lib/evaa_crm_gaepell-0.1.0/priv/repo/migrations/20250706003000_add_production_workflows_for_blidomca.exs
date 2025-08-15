defmodule EvaaCrmGaepell.Repo.Migrations.AddProductionWorkflowsForBlidomca do
  use Ecto.Migration

  def change do
    # Workflow de Producción para Blidomca (business_id = 2)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Producción de Blindaje', 'Workflow para procesos de blindaje y protección vehicular', 'production', true, 2, NOW(), NOW());"
    
    # Estados del workflow de producción para Blidomca
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'planning', 'Planificación', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'preparation', 'Preparación', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'assembly', 'Ensamblaje', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'testing', 'Pruebas', '#8B5CF6', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'quality_check', 'Control de Calidad', '#10B981', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'completed', 'Completado', '#059669', 6, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 2;"
  end
end
