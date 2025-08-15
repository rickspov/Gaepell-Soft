#!/usr/bin/env elixir

# Script para analizar workflows
# Ejecutar con: mix run check_workflows.exs

alias EvaaCrmGaepell.{Repo, Workflow, Lead, MaintenanceTicket, ProductionOrder, Activity}

IO.puts("=== ANÁLISIS DE WORKFLOWS ===")
IO.puts("")

# Obtener todos los workflows con sus estados
workflows = Repo.all(Workflow) |> Repo.preload(:workflow_states)

IO.puts("📊 RESUMEN GENERAL:")
IO.puts("Total workflows: #{length(workflows)}")
IO.puts("Workflows activos: #{Enum.count(workflows, & &1.is_active)}")
IO.puts("Workflows inactivos: #{Enum.count(workflows, & !&1.is_active)}")
IO.puts("")

# Agrupar por tipo
workflows_by_type = Enum.group_by(workflows, & &1.workflow_type)
IO.puts("📋 POR TIPO:")
Enum.each(workflows_by_type, fn {type, workflows} ->
  IO.puts("  #{type}: #{length(workflows)} workflows")
end)
IO.puts("")

# Agrupar por empresa
workflows_by_business = Enum.group_by(workflows, & &1.business_id)
IO.puts("🏢 POR EMPRESA:")
Enum.each(workflows_by_business, fn {business_id, workflows} ->
  company_name = case business_id do
    1 -> "Furcar"
    2 -> "Blidomca"
    3 -> "Polimat"
    _ -> "Empresa #{business_id}"
  end
  IO.puts("  #{company_name} (ID: #{business_id}): #{length(workflows)} workflows")
end)
IO.puts("")

IO.puts("🔍 DETALLE POR WORKFLOW:")
IO.puts("")

Enum.each(workflows, fn workflow ->
  # Contar elementos por tipo
  leads_count = Repo.aggregate(Lead, :count, where: [business_id: workflow.business_id])
  tickets_count = Repo.aggregate(MaintenanceTicket, :count, where: [business_id: workflow.business_id])
  production_count = Repo.aggregate(ProductionOrder, :count, where: [business_id: workflow.business_id])
  activities_count = Repo.aggregate(Activity, :count, where: [business_id: workflow.business_id])
  
  # Determinar si tiene elementos asociados
  has_elements = case workflow.workflow_type do
    "leads" -> leads_count > 0
    "maintenance" -> tickets_count > 0
    "production" -> production_count > 0
    "events" -> activities_count > 0
    _ -> false
  end
  
  status_icon = if workflow.is_active, do: "✅", else: "❌"
  elements_icon = if has_elements, do: "📦", else: "📭"
  
  company_name = case workflow.business_id do
    1 -> "Furcar"
    2 -> "Blidomca"
    3 -> "Polimat"
    _ -> "Empresa #{workflow.business_id}"
  end
  
  IO.puts("#{status_icon} #{elements_icon} ID: #{workflow.id}")
  IO.puts("   Nombre: #{workflow.name}")
  IO.puts("   Tipo: #{workflow.workflow_type}")
  IO.puts("   Empresa: #{company_name} (#{workflow.business_id})")
  IO.puts("   Estados: #{length(workflow.workflow_states)}")
  IO.puts("   Activo: #{workflow.is_active}")
  IO.puts("   Elementos asociados:")
  IO.puts("     - Leads: #{leads_count}")
  IO.puts("     - Tickets: #{tickets_count}")
  IO.puts("     - Producción: #{production_count}")
  IO.puts("     - Actividades: #{activities_count}")
  IO.puts("")
end)

# Identificar workflows candidatos a borrar
IO.puts("🗑️  WORKFLOWS CANDIDATOS A BORRAR:")
candidates = Enum.filter(workflows, fn workflow ->
  # Workflows inactivos sin elementos
  !workflow.is_active
end)

if length(candidates) > 0 do
  Enum.each(candidates, fn workflow ->
    company_name = case workflow.business_id do
      1 -> "Furcar"
      2 -> "Blidomca"
      3 -> "Polimat"
      _ -> "Empresa #{workflow.business_id}"
    end
    IO.puts("  - ID: #{workflow.id} | #{workflow.name} | #{workflow.workflow_type} | #{company_name}")
  end)
else
  IO.puts("  No hay workflows candidatos a borrar.")
end

IO.puts("")
IO.puts("=== FIN DEL ANÁLISIS ===") 