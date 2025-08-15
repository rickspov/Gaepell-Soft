defmodule EvaaCrmGaepell.Repo.Migrations.CreateLeadsWorkflow do
  use Ecto.Migration

  def change do
    # business_id = 1 (Furcar)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Leads Pipeline', 'Workflow para gestión de leads desde captura hasta conversión', 'leads', true, 1, NOW(), NOW());"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'new', 'Nuevo Lead', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'contacted', 'Contactado', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'qualified', 'Calificado', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'proposal', 'Propuesta', '#8B5CF6', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'converted', 'Convertido', '#10B981', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 1;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'lost', 'Perdido', '#EF4444', 6, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 1;"

    # business_id = 2 (Blidomca)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Leads Pipeline', 'Workflow para gestión de leads desde captura hasta conversión', 'leads', true, 2, NOW(), NOW());"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'new', 'Nuevo Lead', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'contacted', 'Contactado', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'qualified', 'Calificado', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'proposal', 'Propuesta', '#8B5CF6', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'converted', 'Convertido', '#10B981', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 2;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'lost', 'Perdido', '#EF4444', 6, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 2;"

    # business_id = 3 (Polimat)
    execute "INSERT INTO workflows (name, description, workflow_type, is_active, business_id, inserted_at, updated_at) VALUES ('Leads Pipeline', 'Workflow para gestión de leads desde captura hasta conversión', 'leads', true, 3, NOW(), NOW());"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'new', 'Nuevo Lead', '#6B7280', 1, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'contacted', 'Contactado', '#F59E0B', 2, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'qualified', 'Calificado', '#3B82F6', 3, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'proposal', 'Propuesta', '#8B5CF6', 4, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'converted', 'Convertido', '#10B981', 5, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 3;"
    execute "INSERT INTO workflow_states (name, label, color, order_index, workflow_id, inserted_at, updated_at) SELECT 'lost', 'Perdido', '#EF4444', 6, id, NOW(), NOW() FROM workflows WHERE workflow_type = 'leads' AND business_id = 3;"
  end
end
