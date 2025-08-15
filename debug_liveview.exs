# Debug script para replicar la lógica del LiveView
alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, MaintenanceTicket, Activity, Lead}
import Ecto.Query

# Simular los filtros del LiveView
filters = %{tipo: "todos", workflow: "todos", compania: "1", camion: "todos", fecha: nil}
current_view = "integrated"

IO.puts("=== SIMULANDO CARGA DEL LIVEVIEW ===")
IO.puts("Filtros: #{inspect(filters)}")
IO.puts("Vista: #{current_view}")

# Obtener empresa seleccionada
selected_company_id = case filters[:compania] do
  "1" -> 1  # Furcar
  "2" -> 2  # Blidomca
  "3" -> 3  # Polimat
  _ -> 1    # Default a Furcar
end

IO.puts("Empresa seleccionada: #{selected_company_id}")

# Obtener workflows activos filtrados por empresa
workflows = Repo.all(from w in Workflow, 
  where: w.is_active == true,
  preload: [workflow_states: ^(from ws in WorkflowState, order_by: ws.order_index)])

IO.puts("Total workflows encontrados: #{length(workflows)}")

# Filtrar workflows por empresa
filtered_workflows = workflows
|> Enum.filter(fn workflow -> workflow.business_id == selected_company_id end)

IO.puts("Workflows filtrados por empresa #{selected_company_id}: #{length(filtered_workflows)}")

# Cargar actividades y tickets
activities = Repo.all(from a in Activity, 
  where: a.business_id == ^selected_company_id,
  order_by: a.due_date)

tickets = Repo.all(from t in MaintenanceTicket, 
  where: t.business_id == ^selected_company_id,
  order_by: t.inserted_at)

IO.puts("Actividades cargadas: #{length(activities)}")
IO.puts("Tickets cargados: #{length(tickets)}")

# Procesar datos como en el LiveView
maintenance_workflow = Enum.find(filtered_workflows, fn w -> w.workflow_type == "maintenance" end)

if maintenance_workflow do
  IO.puts("\n=== PROCESANDO WORKFLOW DE MANTENIMIENTO ===")
  IO.puts("Workflow: #{maintenance_workflow.name}")
  IO.puts("Estados del workflow:")
  Enum.each(maintenance_workflow.workflow_states, fn state ->
    IO.puts("  - #{state.name} (#{state.label}) - Order: #{state.order_index}")
  end)
  
  # Procesar tickets como en el LiveView
  workflow_items = tickets
  |> Enum.map(fn ticket -> 
    %{
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: case ticket.status do
        "open" -> "pending"
        "in_progress" -> "in_progress"
        "review" -> "review"
        "completed" -> "completed"
        "cancelled" -> "cancelled"
        _ -> "pending"
      end,
      workflow_type: "maintenance",
      business_id: ticket.business_id,
      specialist_id: ticket.specialist_id,
      due_date: ticket.entry_date,
      priority: ticket.priority,
      company_name: case ticket.business_id do
        1 -> "Furcar"
        2 -> "Blidomca" 
        3 -> "Polimat"
        _ -> "Empresa #{ticket.business_id}"
      end,
      truck_name: nil,
      created_at: ticket.inserted_at
    }
  end)
  
  IO.puts("\nTickets procesados: #{length(workflow_items)}")
  Enum.each(workflow_items, fn item ->
    IO.puts("  Ticket #{item.id}: #{item.title} -> Status: #{item.status}")
  end)
  
  # Agrupar items por estado del workflow
  items_by_state = maintenance_workflow.workflow_states
  |> Enum.map(fn state ->
    state_items = workflow_items
    |> Enum.filter(fn item -> 
      # Mapear estados de items a estados del workflow específicos
      case {item.status, state.name} do
        {"pending", "check_in"} -> true
        {"in_progress", "in_workshop"} -> true
        {"review", "final_review"} -> true
        {"completed", "car_wash"} -> true
        {"completed", "check_out"} -> true
        {"cancelled", "cancelled"} -> true
        _ -> false
      end
    end)
    
    %{
      workflow_id: maintenance_workflow.id,
      workflow_name: maintenance_workflow.name,
      workflow_type: maintenance_workflow.workflow_type,
      state: state,
      items: state_items,
      count: length(state_items)
    }
  end)
  
  IO.puts("\n=== RESULTADO FINAL ===")
  Enum.each(items_by_state, fn state_data ->
    IO.puts("Estado: #{state_data.state.label} (#{state_data.state.name})")
    IO.puts("  Items: #{state_data.count}")
    Enum.each(state_data.items, fn item ->
      IO.puts("    - #{item.title} (ID: #{item.id})")
    end)
  end)
  
  # Crear estructura final como en el LiveView
  final_result = %{
    workflow: maintenance_workflow,
    states: items_by_state,
    total_items: length(workflow_items)
  }
  
  IO.puts("\n=== ESTRUCTURA FINAL ===")
  IO.puts("Total items en workflow: #{final_result.total_items}")
  IO.puts("Estados con items: #{Enum.count(final_result.states, fn s -> s.count > 0 end)}")
  
else
  IO.puts("No se encontró workflow de mantenimiento para la empresa #{selected_company_id}")
end 