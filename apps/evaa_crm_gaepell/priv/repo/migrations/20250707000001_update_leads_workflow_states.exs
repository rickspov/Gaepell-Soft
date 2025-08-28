defmodule EvaaCrmGaepell.Repo.Migrations.UpdateLeadsWorkflowStates do
  use Ecto.Migration

  def change do
    # Eliminar el estado "proposal" que no se usa en la página de prospectos
    execute """
    DELETE FROM workflow_states 
    WHERE name = 'proposal' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads'
    );
    """

    # Actualizar el orden de los estados restantes para que coincidan con la página de prospectos
    # Los estados que se usan en prospectos son: new, contacted, qualified, converted, lost
    
    # Actualizar el orden de los estados para Furcar (business_id = 1)
    execute """
    UPDATE workflow_states 
    SET order_index = 1, label = 'Nuevo Lead'
    WHERE name = 'new' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 1
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 2, label = 'Contactado'
    WHERE name = 'contacted' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 1
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 3, label = 'Calificado'
    WHERE name = 'qualified' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 1
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 4, label = 'Convertido'
    WHERE name = 'converted' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 1
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 5, label = 'Perdido'
    WHERE name = 'lost' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 1
    );
    """

    # Actualizar el orden de los estados para Blidomca (business_id = 2)
    execute """
    UPDATE workflow_states 
    SET order_index = 1, label = 'Nuevo Lead'
    WHERE name = 'new' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 2
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 2, label = 'Contactado'
    WHERE name = 'contacted' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 2
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 3, label = 'Calificado'
    WHERE name = 'qualified' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 2
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 4, label = 'Convertido'
    WHERE name = 'converted' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 2
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 5, label = 'Perdido'
    WHERE name = 'lost' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 2
    );
    """

    # Actualizar el orden de los estados para Polimat (business_id = 3)
    execute """
    UPDATE workflow_states 
    SET order_index = 1, label = 'Nuevo Lead'
    WHERE name = 'new' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 3
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 2, label = 'Contactado'
    WHERE name = 'contacted' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 3
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 3, label = 'Calificado'
    WHERE name = 'qualified' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 3
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 4, label = 'Convertido'
    WHERE name = 'converted' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 3
    );
    """
    
    execute """
    UPDATE workflow_states 
    SET order_index = 5, label = 'Perdido'
    WHERE name = 'lost' AND workflow_id IN (
      SELECT id FROM workflows 
      WHERE workflow_type = 'leads' AND business_id = 3
    );
    """
  end
end 