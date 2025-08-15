Mix.Task.run("app.start")

alias EvaaCrmGaepell.{Repo, Lead, WorkflowService, WorkflowState}
import Ecto.Query

# Obtener un lead para probar
lead = Repo.get(Lead, 3)  # María González
IO.puts("=== TESTING LEAD DRAG & DROP ===")
IO.puts("Lead: #{lead.name}")
IO.puts("Status actual: #{lead.status}")

# Obtener la asignación de workflow
assignment = WorkflowService.get_current_state("lead", lead.id)
if assignment do
  current_state = Repo.get(WorkflowState, assignment.current_state_id)
  IO.puts("Estado actual del workflow: #{current_state.name}")
  IO.puts("Assignment ID: #{assignment.id}")
  
  # Simular cambio de estado de "contacted" a "qualified"
  new_status = "qualified"
  IO.puts("\n--- SIMULANDO CAMBIO A '#{new_status}' ---")
  
  # Buscar el nuevo estado
  new_state = Repo.one(from ws in WorkflowState, 
    where: ws.workflow_id == ^assignment.workflow_id and ws.name == ^new_status)
  
  if new_state do
    IO.puts("Nuevo estado encontrado: #{new_state.name} (ID: #{new_state.id})")
    
    # Simular el cambio usando WorkflowService
    case WorkflowService.change_state(assignment.id, new_state.id, 1) do
      {:ok, updated_assignment} ->
        IO.puts("✅ WorkflowService.change_state exitoso")
        IO.puts("Nuevo assignment: #{inspect(updated_assignment)}")
        
        # Actualizar el campo status del lead
        changeset = Lead.changeset(lead, %{status: new_status})
        case Repo.update(changeset) do
          {:ok, updated_lead} ->
            IO.puts("✅ Campo status del lead actualizado a: #{updated_lead.status}")
          {:error, changeset} ->
            IO.puts("❌ Error actualizando status del lead: #{inspect(changeset.errors)}")
        end
        
      {:error, error} ->
        IO.puts("❌ Error en WorkflowService.change_state: #{inspect(error)}")
    end
  else
    IO.puts("❌ Estado '#{new_status}' no encontrado en el workflow")
  end
else
  IO.puts("❌ No se encontró assignment de workflow para el lead")
end

# Verificar el estado final
IO.puts("\n--- ESTADO FINAL ---")
updated_lead = Repo.get(Lead, 3)
updated_assignment = WorkflowService.get_current_state("lead", 3)
if updated_assignment do
  final_state = Repo.get(WorkflowState, updated_assignment.current_state_id)
  IO.puts("Status del lead: #{updated_lead.status}")
  IO.puts("Estado del workflow: #{final_state.name}")
  IO.puts("¿Sincronizados?: #{updated_lead.status == final_state.name}")
else
  IO.puts("❌ No se pudo obtener el assignment final")
end 