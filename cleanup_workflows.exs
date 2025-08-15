#!/usr/bin/env elixir

# Script para limpiar workflows problemáticos
# Ejecutar con: mix run cleanup_workflows.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, WorkflowTransition, WorkflowAssignment}

IO.puts("=== LIMPIEZA DE WORKFLOWS ===")
IO.puts("")

# Workflows a eliminar (problemáticos)
workflows_to_delete = [4]  # "Eventos Polimat" en Furcar (mal configurado)

Enum.each(workflows_to_delete, fn workflow_id ->
  workflow = Repo.get(Workflow, workflow_id)
  
  if workflow do
    IO.puts("🗑️  ELIMINANDO WORKFLOW PROBLEMÁTICO:")
    IO.puts("   ID: #{workflow.id}")
    IO.puts("   Nombre: #{workflow.name}")
    IO.puts("   Tipo: #{workflow.workflow_type}")
    IO.puts("   Empresa: #{workflow.business_id}")
    IO.puts("")
    
    # Eliminar en orden correcto (por foreign keys)
    Repo.transaction(fn ->
      # 1. Eliminar asignaciones de workflow
      assignments = Repo.all(from wa in WorkflowAssignment, where: wa.workflow_id == ^workflow_id)
      IO.puts("   - Eliminando #{length(assignments)} asignaciones...")
      Enum.each(assignments, fn assignment ->
        Repo.delete(assignment)
      end)
      
      # 2. Eliminar transiciones
      transitions = Repo.all(from wt in WorkflowTransition, where: wt.workflow_id == ^workflow_id)
      IO.puts("   - Eliminando #{length(transitions)} transiciones...")
      Enum.each(transitions, fn transition ->
        Repo.delete(transition)
      end)
      
      # 3. Eliminar estados
      states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow_id)
      IO.puts("   - Eliminando #{length(states)} estados...")
      Enum.each(states, fn state ->
        Repo.delete(state)
      end)
      
      # 4. Eliminar workflow
      Repo.delete(workflow)
      IO.puts("   - Eliminando workflow...")
    end)
    
    IO.puts("   ✅ Workflow #{workflow_id} eliminado exitosamente")
    IO.puts("")
  else
    IO.puts("   ⚠️  Workflow #{workflow_id} no encontrado")
    IO.puts("")
  end
end)

# Verificar workflows de leads
IO.puts("🔍 VERIFICANDO WORKFLOWS DE LEADS:")
leads_workflows = Repo.all(from w in Workflow, where: w.workflow_type == "leads")
Enum.each(leads_workflows, fn workflow ->
  company_name = case workflow.business_id do
    1 -> "Furcar"
    2 -> "Blidomca"
    3 -> "Polimat"
    _ -> "Empresa #{workflow.business_id}"
  end
  
  states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow.id)
  IO.puts("   ✅ ID: #{workflow.id} | #{workflow.name} | #{company_name} | #{length(states)} estados")
end)

IO.puts("")
IO.puts("=== LIMPIEZA COMPLETADA ===") 