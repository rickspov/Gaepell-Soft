#!/usr/bin/env elixir

# Script para verificar el estado de workflows después de la limpieza
# Ejecutar con: mix run verify_workflows.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState}

IO.puts("=== VERIFICACIÓN DE WORKFLOWS DESPUÉS DE LIMPIEZA ===")
IO.puts("")

# Obtener todos los workflows activos
workflows = Repo.all(from w in Workflow, where: w.is_active == true, order_by: w.id)

IO.puts("📊 WORKFLOWS ACTIVOS (#{length(workflows)}):")
IO.puts("")

Enum.each(workflows, fn workflow ->
  company_name = case workflow.business_id do
    1 -> "Furcar"
    2 -> "Blidomca"
    3 -> "Polimat"
    _ -> "Empresa #{workflow.business_id}"
  end
  
  states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow.id, order_by: ws.order_index)
  
  IO.puts("   ID: #{workflow.id}")
  IO.puts("   Nombre: #{workflow.name}")
  IO.puts("   Tipo: #{workflow.workflow_type}")
  IO.puts("   Empresa: #{company_name}")
  IO.puts("   Estados: #{length(states)}")
  IO.puts("   Estados: #{Enum.map_join(states, ", ", fn s -> s.name end)}")
  IO.puts("")
end)

# Verificar que no existe el workflow problemático (ID 4)
problematic_workflow = Repo.get(Workflow, 4)
if problematic_workflow do
  IO.puts("❌ ERROR: Workflow problemático ID 4 aún existe")
else
  IO.puts("✅ Workflow problemático ID 4 eliminado correctamente")
end

IO.puts("")
IO.puts("=== VERIFICACIÓN COMPLETADA ===") 