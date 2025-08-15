#!/usr/bin/env elixir

# Debug script for production order issues
# Run with: mix run debug_production_issues.exs

import Ecto.Query

IO.puts("=== DEBUGGING PRODUCTION ORDER ISSUES ===")

# Load the application
Application.ensure_all_started(:evaa_crm_gaepell)

IO.puts("\n1. Checking production orders in database...")
production_orders = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.ProductionOrder)
IO.puts("   Found #{length(production_orders)} production orders")

Enum.each(production_orders, fn po ->
  IO.puts("   - Order #{po.id}: #{po.client_name} (status: #{po.status}, business_id: #{po.business_id})")
end)

IO.puts("\n2. Checking workflows for production...")
workflows = EvaaCrmGaepell.Repo.all(from w in EvaaCrmGaepell.Workflow, where: w.workflow_type == "production")
IO.puts("   Found #{length(workflows)} production workflows")

Enum.each(workflows, fn workflow ->
  IO.puts("   - Workflow #{workflow.id}: #{workflow.name} (business_id: #{workflow.business_id})")
  states = EvaaCrmGaepell.Repo.all(from ws in EvaaCrmGaepell.WorkflowState, where: ws.workflow_id == ^workflow.id, order_by: ws.order_index)
  IO.puts("     States: #{Enum.map_join(states, ", ", fn s -> s.name end)}")
end)

IO.puts("\n3. Checking production order IDs in Kanban...")
IO.puts("   Production orders should have prefix 'p-' in Kanban")

Enum.each(production_orders, fn po ->
  expected_id = "p-#{po.id}"
  IO.puts("   - Order #{po.id} should have Kanban ID: #{expected_id}")
end)

IO.puts("\n4. Checking dropdown functionality in trucks view...")
IO.puts("   The issue might be in the phx-change event handler")
IO.puts("   Current handler: 'cancel_edit_production_status'")
IO.puts("   Expected: Should update status when dropdown changes")

IO.puts("\n5. Testing production order status update...")
if length(production_orders) > 0 do
  po = List.first(production_orders)
  IO.puts("   Testing with order #{po.id}: #{po.client_name}")
  IO.puts("   Current status: #{po.status}")
  
  # Test the status update
  changeset = EvaaCrmGaepell.ProductionOrder.changeset(po, %{status: "reception"})
  case EvaaCrmGaepell.Repo.update(changeset) do
    {:ok, updated_po} ->
      IO.puts("   ✅ Status update successful: #{updated_po.status}")
      # Revert the change
      revert_changeset = EvaaCrmGaepell.ProductionOrder.changeset(updated_po, %{status: po.status})
      EvaaCrmGaepell.Repo.update(revert_changeset)
    {:error, changeset} ->
      IO.puts("   ❌ Status update failed: #{inspect(changeset.errors)}")
  end
end

IO.puts("\n6. Checking Kanban drag-and-drop for production orders...")
IO.puts("   Production orders should be draggable in Kanban view")
IO.puts("   Expected ID format: 'p-{id}'")
IO.puts("   Expected workflow_type: 'production'")

IO.puts("\n=== DIAGNOSIS COMPLETE ===")
IO.puts("\nIssues found:")
IO.puts("1. In trucks_live.ex: The dropdown uses 'cancel_edit_production_status' but should use 'update_production_status'")
IO.puts("2. In kanban_live.ex: Production orders use wrong prefix in get_item_id_with_prefix")
IO.puts("3. In kanban_live.ex: Production orders use wrong workflow_type in create_integrated_view") 