#!/usr/bin/env elixir

# Script para debuggear paso a paso el drag and drop del Kanban
# Ejecutar con: mix run debug_kanban_step_by_step.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead, Workflow, WorkflowState}

IO.puts("=== DIAGNÓSTICO PASO A PASO DEL KANBAN DRAG AND DROP ===")
IO.puts("")

# PASO 1: Verificar que hay leads en la base de datos
IO.puts("PASO 1: Verificando leads en la base de datos")
leads = Repo.all(Lead)
IO.puts("✅ Leads encontrados: #{length(leads)}")
Enum.each(leads, fn lead ->
  IO.puts("  - Lead #{lead.id}: #{lead.name} | Estado: #{lead.status} | Empresa: #{lead.business_id}")
end)

# PASO 2: Verificar workflows de leads
IO.puts("")
IO.puts("PASO 2: Verificando workflows de leads")
leads_workflows = Repo.all(from w in Workflow, where: w.workflow_type == "leads")
IO.puts("✅ Workflows de leads encontrados: #{length(leads_workflows)}")
Enum.each(leads_workflows, fn workflow ->
  states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow.id, order_by: ws.order_index)
  IO.puts("  - Workflow #{workflow.id}: #{workflow.name} | Empresa: #{workflow.business_id} | Estados: #{length(states)}")
end)

# PASO 3: Verificar que los leads tienen estados válidos
IO.puts("")
IO.puts("PASO 3: Verificando estados de leads")
valid_states = ["new", "contacted", "qualified", "converted", "lost"]
leads_with_invalid_status = Enum.filter(leads, fn lead -> lead.status not in valid_states end)
if length(leads_with_invalid_status) > 0 do
  IO.puts("❌ Leads con estados inválidos:")
  Enum.each(leads_with_invalid_status, fn lead ->
    IO.puts("  - Lead #{lead.id}: #{lead.name} | Estado inválido: #{lead.status}")
  end)
else
  IO.puts("✅ Todos los leads tienen estados válidos")
end

# PASO 4: Simular un evento de drag and drop completo
IO.puts("")
IO.puts("PASO 4: Simulando evento de drag and drop")
if length(leads) > 0 do
  lead = List.first(leads)
  old_status = lead.status
  new_status = case old_status do
    "new" -> "contacted"
    "contacted" -> "qualified"
    "qualified" -> "converted"
    "converted" -> "lost"
    "lost" -> "new"
    _ -> "contacted"
  end
  
  IO.puts("Lead seleccionado: #{lead.name} (ID: #{lead.id})")
  IO.puts("Estado actual: #{old_status}")
  IO.puts("Nuevo estado: #{new_status}")
  
  # Simular el evento que enviaría el JavaScript
  event_data = %{
    "id" => "l-#{lead.id}",
    "new_status" => new_status,
    "old_status" => old_status,
    "workflow_id" => "14"  # Workflow de leads de Furcar
  }
  
  IO.puts("Evento que se enviaría:")
  IO.inspect(event_data)
  
  # Simular la actualización
  changeset = Lead.changeset(lead, %{status: new_status})
  case Repo.update(changeset) do
    {:ok, updated_lead} ->
      IO.puts("✅ Lead actualizado exitosamente")
      IO.puts("  Estado anterior: #{old_status}")
      IO.puts("  Estado nuevo: #{updated_lead.status}")
      
      # Verificar que se guardó
      reloaded_lead = Repo.get(Lead, lead.id)
      IO.puts("  Estado en BD: #{reloaded_lead.status}")
      
      if reloaded_lead.status == new_status do
        IO.puts("✅ Estado persistido correctamente en la base de datos")
      else
        IO.puts("❌ ERROR: Estado no se persistió correctamente")
      end
      
    {:error, changeset} ->
      IO.puts("❌ Error al actualizar:")
      IO.inspect(changeset.errors)
  end
else
  IO.puts("❌ No hay leads para probar")
end

# PASO 5: Verificar la estructura del HTML
IO.puts("")
IO.puts("PASO 5: Verificando estructura del HTML")
IO.puts("El HTML debe tener:")
IO.puts("  - Elementos con data-kanban-column")
IO.puts("  - Elementos con data-status")
IO.puts("  - Elementos con data-workflow")
IO.puts("  - Contenedores con clase .kanban-col-cards")
IO.puts("  - Cards con data-id")

# PASO 6: Verificar JavaScript
IO.puts("")
IO.puts("PASO 6: Verificando JavaScript")
IO.puts("El JavaScript debe:")
IO.puts("  - Encontrar elementos con data-kanban-column")
IO.puts("  - Crear Sortable.js para cada columna")
IO.puts("  - Manejar eventos onStart y onEnd")
IO.puts("  - Enviar evento kanban:move al servidor")

# PASO 7: Verificar el servidor
IO.puts("")
IO.puts("PASO 7: Verificando el servidor")
IO.puts("El servidor debe:")
IO.puts("  - Recibir evento kanban:move")
IO.puts("  - Procesar el ID del item (l-123)")
IO.puts("  - Actualizar el lead en la base de datos")
IO.puts("  - Recargar los items del Kanban")

# PASO 8: Instrucciones para debugging en el navegador
IO.puts("")
IO.puts("PASO 8: INSTRUCCIONES PARA DEBUGGING EN EL NAVEGADOR")
IO.puts("1. Abre http://localhost:4001")
IO.puts("2. Ve al Kanban")
IO.puts("3. Abre las herramientas de desarrollador (F12)")
IO.puts("4. Ve a la pestaña Console")
IO.puts("5. Busca estos logs:")
IO.puts("   - 'KanbanDragDrop hook mounted'")
IO.puts("   - 'Found columns with data-kanban-column: X'")
IO.puts("   - 'Creating sortable for column X'")
IO.puts("   - 'Drag started'")
IO.puts("   - 'Sortable onEnd'")
IO.puts("   - 'Status changed, sending kanban:move event'")
IO.puts("6. Intenta arrastrar un lead")
IO.puts("7. Verifica si aparecen los logs")

# PASO 9: Verificar en el servidor
IO.puts("")
IO.puts("PASO 9: VERIFICAR EN EL SERVIDOR")
IO.puts("En la consola del servidor, busca estos logs:")
IO.puts("  - '[DEBUG] kanban:move event received'")
IO.puts("  - '[DEBUG] id: l-X'")
IO.puts("  - '[DEBUG] new_status: X'")
IO.puts("  - '[DEBUG] Lead X status field updated to: X'")

IO.puts("")
IO.puts("=== DIAGNÓSTICO COMPLETADO ===")
IO.puts("Si todos los pasos anteriores están correctos, el problema podría estar en:")
IO.puts("1. JavaScript no se está cargando correctamente")
IO.puts("2. Sortable.js no está disponible")
IO.puts("3. El evento no llega al servidor")
IO.puts("4. El servidor no procesa correctamente el evento")
IO.puts("5. La página no se recarga después del evento") 