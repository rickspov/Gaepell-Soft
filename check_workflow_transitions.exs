Mix.Task.run("app.start")

alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, WorkflowTransition}
import Ecto.Query

IO.puts("=== VERIFICANDO TRANSICIONES DEL WORKFLOW DE LEADS ===")

# Obtener todos los workflows de leads
workflows = Repo.all(from w in Workflow, where: w.workflow_type == "leads")

for workflow <- workflows do
  IO.puts("\n--- Workflow ID #{workflow.id} (Business ID: #{workflow.business_id}) ---")
  
  # Obtener todos los estados del workflow
  states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow.id, order_by: ws.order_index)
  IO.puts("Estados:")
  for state <- states do
    IO.puts("  - #{state.name} (ID: #{state.id}, Order: #{state.order_index})")
  end
  
  # Obtener todas las transiciones del workflow
  transitions = Repo.all(from wt in WorkflowTransition, where: wt.workflow_id == ^workflow.id)
  IO.puts("Transiciones:")
  for transition <- transitions do
    from_state = Repo.get(WorkflowState, transition.from_state_id)
    to_state = Repo.get(WorkflowState, transition.to_state_id)
    IO.puts("  - #{from_state.name} -> #{to_state.name}")
  end
  
  if Enum.empty?(transitions) do
    IO.puts("  ❌ NO HAY TRANSICIONES DEFINIDAS")
  end
end 