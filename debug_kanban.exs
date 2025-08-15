# Debug script para el Kanban
alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, MaintenanceTicket, Activity, Lead}
import Ecto.Query

# Cargar workflows y estados
workflows = Repo.all(from w in Workflow, 
  where: w.is_active == true and w.business_id == 1,
  preload: [workflow_states: ^(from ws in WorkflowState, order_by: ws.order_index)])

IO.puts("=== WORKFLOWS ENCONTRADOS ===")
Enum.each(workflows, fn workflow ->
  IO.puts("Workflow: #{workflow.name} (#{workflow.workflow_type})")
  IO.puts("Estados:")
  Enum.each(workflow.workflow_states, fn state ->
    IO.puts("  - #{state.name} (#{state.label}) - Order: #{state.order_index}")
  end)
  IO.puts("")
end)

# Cargar tickets
tickets = Repo.all(from t in MaintenanceTicket, where: t.business_id == 1, limit: 5)

IO.puts("=== TICKETS ENCONTRADOS ===")
Enum.each(tickets, fn ticket ->
  IO.puts("Ticket ID: #{ticket.id}, Title: #{ticket.title}, Status: #{ticket.status}")
end)

# Probar el mapeo de estados
IO.puts("\n=== PRUEBA DE MAPEO DE ESTADOS ===")
maintenance_workflow = Enum.find(workflows, fn w -> w.workflow_type == "maintenance" end)

if maintenance_workflow do
  IO.puts("Workflow de mantenimiento encontrado: #{maintenance_workflow.name}")
  
  Enum.each(tickets, fn ticket ->
    ticket_status = case ticket.status do
      "open" -> "pending"
      "in_progress" -> "in_progress"
      "review" -> "review"
      "completed" -> "completed"
      "cancelled" -> "cancelled"
      _ -> "pending"
    end
    
    IO.puts("Ticket #{ticket.id} (#{ticket.status}) -> #{ticket_status}")
    
    # Verificar en qué estados del workflow debería aparecer
    matching_states = Enum.filter(maintenance_workflow.workflow_states, fn state ->
      case {ticket_status, state.name} do
        {"pending", "check_in"} -> true
        {"in_progress", "in_workshop"} -> true
        {"review", "final_review"} -> true
        {"completed", "car_wash"} -> true
        {"completed", "check_out"} -> true
        {"cancelled", "cancelled"} -> true
        _ -> false
      end
    end)
    
    IO.puts("  Estados coincidentes: #{Enum.map(matching_states, fn s -> s.name end)}")
  end)
else
  IO.puts("No se encontró workflow de mantenimiento")
end 