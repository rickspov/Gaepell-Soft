defmodule EvaaCrmGaepell.Repo.Migrations.AddMissingWorkflowsForAllCompanies do
  use Ecto.Migration

  def change do
    # Workflow de Mantenimiento para Furcar (business_id = 1)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Mantenimiento de Camiones', 'Workflow para mantenimiento y reparación de camiones', 'maintenance', true, 1, NOW(), NOW());"
    
    # Estados del workflow de mantenimiento para Furcar
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'open', 'Abierto', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'maintenance' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'in_progress', 'En Progreso', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'maintenance' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'review', 'En Revisión', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'maintenance' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'completed', 'Completado', '#10B981', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'maintenance' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'cancelled', 'Cancelado', '#EF4444', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'maintenance' AND business_id = 1;"

    # Workflow de Producción para Furcar (business_id = 1)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Producción de Cajas', 'Workflow para fabricación de cajas para camiones', 'production', true, 1, NOW(), NOW());"
    
    # Estados del workflow de producción para Furcar
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'planning', 'Planificación', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'cutting', 'Corte', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'assembly', 'Ensamblaje', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'welding', 'Soldadura', '#8B5CF6', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'finishing', 'Acabado', '#10B981', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'completed', 'Completado', '#059669', 6, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'production' AND business_id = 1;"

    # Workflow de Eventos para Polimat (business_id = 3)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Eventos de Polimat', 'Workflow para gestión de eventos y actividades especiales', 'events', true, 3, NOW(), NOW());"
    
    # Estados del workflow de eventos para Polimat
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'planning', 'Planificación', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'events' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'preparation', 'Preparación', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'events' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'execution', 'Ejecución', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'events' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'follow_up', 'Seguimiento', '#8B5CF6', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'events' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'completed', 'Completado', '#10B981', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'events' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'cancelled', 'Cancelado', '#EF4444', 6, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'events' AND business_id = 3;"
  end
end
