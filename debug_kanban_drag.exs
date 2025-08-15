#!/usr/bin/env elixir

# Script para debuggear el drag and drop del Kanban
# Ejecutar con: mix run debug_kanban_drag.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead, Workflow, WorkflowState}

IO.puts("=== DEBUG KANBAN DRAG AND DROP ===")
IO.puts("")

# Verificar que hay leads para probar
leads = Repo.all(Lead)
IO.puts("Leads disponibles: #{length(leads)}")
Enum.each(leads, fn lead ->
  IO.puts("  - Lead #{lead.id}: #{lead.name} | Estado: #{lead.status} | Empresa: #{lead.business_id}")
end)

# Verificar workflows de leads
leads_workflows = Repo.all(from w in Workflow, where: w.workflow_type == "leads")
IO.puts("")
IO.puts("Workflows de leads:")
Enum.each(leads_workflows, fn workflow ->
  states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow.id, order_by: ws.order_index)
  IO.puts("  - Workflow #{workflow.id}: #{workflow.name} | Empresa: #{workflow.business_id}")
  Enum.each(states, fn state ->
    IO.puts("    * Estado: #{state.name} (#{state.label}) | Color: #{state.color}")
  end)
end)

# Simular un evento de drag and drop
IO.puts("")
IO.puts("=== SIMULANDO EVENTO DE DRAG AND DROP ===")

# Tomar el primer lead
if length(leads) > 0 do
  lead = List.first(leads)
  IO.puts("Lead seleccionado: #{lead.name} (ID: #{lead.id})")
  IO.puts("Estado actual: #{lead.status}")
  
  # Simular cambio de "new" a "contacted"
  new_status = "contacted"
  IO.puts("Nuevo estado: #{new_status}")
  
  # Simular el evento que enviaría el JavaScript
  event_data = %{
    "id" => "l-#{lead.id}",
    "new_status" => new_status,
    "old_status" => lead.status,
    "workflow_id" => "14"  # Workflow de leads de Furcar
  }
  
  IO.puts("Evento que se enviaría:")
  IO.inspect(event_data)
  
  # Simular la actualización
  changeset = Lead.changeset(lead, %{status: new_status})
  case Repo.update(changeset) do
    {:ok, updated_lead} ->
      IO.puts("✅ Lead actualizado exitosamente")
      IO.puts("  Estado anterior: #{lead.status}")
      IO.puts("  Estado nuevo: #{updated_lead.status}")
      
      # Verificar que se guardó
      reloaded_lead = Repo.get(Lead, lead.id)
      IO.puts("  Estado en BD: #{reloaded_lead.status}")
      
    {:error, changeset} ->
      IO.puts("❌ Error al actualizar:")
      IO.inspect(changeset.errors)
  end
else
  IO.puts("❌ No hay leads para probar")
end

IO.puts("")
IO.puts("=== INSTRUCCIONES PARA DEBUGGING ===")
IO.puts("1. Abre el navegador en http://localhost:4001")
IO.puts("2. Ve al Kanban")
IO.puts("3. Abre las herramientas de desarrollador (F12)")
IO.puts("4. Ve a la pestaña Console")
IO.puts("5. Busca los logs de 'KanbanDragDrop'")
IO.puts("6. Intenta arrastrar un lead de una columna a otra")
IO.puts("7. Verifica si aparecen los logs de 'Sortable onEnd'")
IO.puts("8. Verifica si se envía el evento 'kanban:move'")

IO.puts("")
IO.puts("=== POSIBLES PROBLEMAS ===")
IO.puts("1. JavaScript no encuentra las columnas con data-kanban-column")
IO.puts("2. Sortable.js no se inicializa correctamente")
IO.puts("3. El evento onEnd no se dispara")
IO.puts("4. El evento kanban:move no llega al servidor")
IO.puts("5. El servidor no procesa correctamente el evento")

IO.puts("")
IO.puts("=== DEBUG COMPLETADO ===") 