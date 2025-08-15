#!/usr/bin/env elixir

# Script para probar el drag and drop del Kanban
# Ejecutar con: elixir test_drag_drop.exs

# Cargar la aplicación
Application.ensure_all_started(:evaa_crm_gaepell)

# Verificar que hay datos para probar
alias EvaaCrmGaepell.{Repo, Activity, MaintenanceTicket, Lead}

IO.puts("=== PRUEBA DE DRAG AND DROP KANBAN ===")

# Verificar actividades
activities = Repo.all(Activity)
IO.puts("Actividades encontradas: #{length(activities)}")
Enum.each(activities, fn activity ->
  IO.puts("  - Actividad #{activity.id}: #{activity.title} (status: #{activity.status})")
end)

# Verificar tickets
tickets = Repo.all(MaintenanceTicket)
IO.puts("Tickets encontrados: #{length(tickets)}")
Enum.each(tickets, fn ticket ->
  IO.puts("  - Ticket #{ticket.id}: #{ticket.title} (status: #{ticket.status})")
end)

# Verificar leads
leads = Repo.all(Lead)
IO.puts("Leads encontrados: #{length(leads)}")
Enum.each(leads, fn lead ->
  IO.puts("  - Lead #{lead.id}: #{lead.name} (status: #{lead.status})")
end)

# Verificar workflows
alias EvaaCrmGaepell.{Workflow, WorkflowState}
workflows = Repo.all(Workflow) |> Repo.preload(:workflow_states)
IO.puts("Workflows encontrados: #{length(workflows)}")
Enum.each(workflows, fn workflow ->
  IO.puts("  - Workflow #{workflow.id}: #{workflow.name} (#{workflow.workflow_type})")
  Enum.each(workflow.workflow_states, fn state ->
    IO.puts("    * Estado: #{state.name} (#{state.label})")
  end)
end)

IO.puts("\n=== INSTRUCCIONES PARA PROBAR ===")
IO.puts("1. Ve a http://localhost:4001")
IO.puts("2. Abre la consola del navegador (F12)")
IO.puts("3. Busca los logs de 'KanbanDragDrop'")
IO.puts("4. Intenta arrastrar un item de una columna a otra")
IO.puts("5. Verifica que los logs muestren el evento 'kanban:move'")

IO.puts("\n=== VERIFICACIÓN DE DATOS ===")
IO.puts("Asegúrate de que hay items en diferentes estados para poder probar el drag and drop.") 