#!/usr/bin/env elixir

# Script para crear workflows de leads
# Ejecutar con: mix run create_leads_workflows.exs

alias EvaaCrmGaepell.{Repo, WorkflowService}

IO.puts("=== CREANDO WORKFLOWS DE LEADS ===")

# Crear workflows de leads para cada empresa
[1, 2, 3] |> Enum.each(fn business_id ->
  IO.puts("Creando workflow de leads para business_id: #{business_id}")
  
  # Crear solo el workflow de leads
  workflow_data = %{
    name: "Pipeline de Leads",
    description: "Flujo de gestión de leads y prospectos",
    workflow_type: "leads",
    business_id: business_id,
    color: "#10B981",
    states: [
      %{name: "new", label: "Nuevo", order_index: 1, color: "#6B7280", icon: "user-plus", is_initial: true},
      %{name: "contacted", label: "Contactado", order_index: 2, color: "#3B82F6", icon: "phone"},
      %{name: "qualified", label: "Calificado", order_index: 3, color: "#F59E0B", icon: "star"},
      %{name: "converted", label: "Convertido", order_index: 4, color: "#10B981", icon: "check-circle", is_final: true},
      %{name: "lost", label: "Perdido", order_index: 5, color: "#EF4444", icon: "x-circle", is_final: true}
    ]
  }
  
  case WorkflowService.create_workflow_with_states(workflow_data) do
    {:ok, workflow} ->
      IO.puts("✅ Workflow de leads creado para business_id #{business_id}: #{workflow.id}")
    {:error, error} ->
      IO.puts("❌ Error creando workflow de leads para business_id #{business_id}: #{inspect(error)}")
  end
end)

IO.puts("=== FINALIZADO ===") 