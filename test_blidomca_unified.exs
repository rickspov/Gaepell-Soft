#!/usr/bin/env elixir

# Script para verificar que Blidomca funciona correctamente con la vista unificada
# Ejecutar con: mix run test_blidomca_unified.exs

alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, Lead, ProductionOrder, Contact}

IO.puts("=== VERIFICANDO BLIDOMCA CON VISTA UNIFICADA ===")

# 1. Verificar workflows de Blidomca
IO.puts("\n1. Verificando workflows de Blidomca...")
blidomca_workflows = Repo.all(from w in Workflow, 
  where: w.business_id == 2 and w.is_active == true,
  preload: [workflow_states: ^(from ws in WorkflowState, order_by: ws.order_index)])

IO.puts("Workflows encontrados: #{length(blidomca_workflows)}")
Enum.each(blidomca_workflows, fn workflow ->
  IO.puts("  - #{workflow.name} (#{workflow.workflow_type}) - #{length(workflow.workflow_states)} estados")
  Enum.each(workflow.workflow_states, fn state ->
    IO.puts("    * #{state.name}")
  end)
end)

# 2. Verificar leads de Blidomca
IO.puts("\n2. Verificando leads de Blidomca...")
blidomca_leads = Repo.all(from l in Lead, where: l.business_id == 2)
IO.puts("Leads encontrados: #{length(blidomca_leads)}")
Enum.each(blidomca_leads, fn lead ->
  IO.puts("  - #{lead.name} (status: #{lead.status})")
end)

# 3. Verificar órdenes de producción de Blidomca
IO.puts("\n3. Verificando órdenes de producción de Blidomca...")
blidomca_orders = Repo.all(from po in ProductionOrder, where: po.business_id == 2)
IO.puts("Órdenes encontradas: #{length(blidomca_orders)}")
Enum.each(blidomca_orders, fn order ->
  IO.puts("  - #{order.client_name} (status: #{order.status})")
end)

# 4. Verificar contactos de Blidomca
IO.puts("\n4. Verificando contactos de Blidomca...")
blidomca_contacts = Repo.all(from c in Contact, where: c.business_id == 2)
IO.puts("Contactos encontrados: #{length(blidomca_contacts)}")
Enum.each(blidomca_contacts, fn contact ->
  IO.puts("  - #{contact.first_name} #{contact.last_name}")
end)

IO.puts("\n=== VERIFICACIÓN COMPLETADA ===")
IO.puts("Blidomca debería funcionar correctamente con la vista unificada.")
IO.puts("Accede a: http://localhost:4000/?compania=2&view=individual") 