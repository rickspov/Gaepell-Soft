#!/usr/bin/env elixir

# Test script to verify Kanban drag-and-drop functionality
# Run with: mix run test_kanban_drag_drop.exs

IO.puts("=== TESTING KANBAN DRAG-AND-DROP FUNCTIONALITY ===")

# Load the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Test 1: Check if Sortable.js is properly imported
IO.puts("\n1. Checking JavaScript setup...")
IO.puts("   - Sortable.js should be imported in app.js")
IO.puts("   - KanbanDragDrop hook should be registered")

# Test 2: Check if leads exist and have proper status
IO.puts("\n2. Checking leads in database...")
leads = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.Lead)
IO.puts("   Found #{length(leads)} leads")

Enum.each(leads, fn lead ->
  IO.puts("   - Lead #{lead.id}: #{lead.name} (status: #{lead.status})")
end)

# Test 3: Check if workflows exist
IO.puts("\n3. Checking workflows...")
workflows = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.Workflow)
IO.puts("   Found #{length(workflows)} workflows")

Enum.each(workflows, fn workflow ->
  states = EvaaCrmGaepell.Repo.preload(workflow, :workflow_states).workflow_states
  IO.puts("   - Workflow #{workflow.id}: #{workflow.name} (#{workflow.workflow_type})")
  IO.puts("     States: #{Enum.map_join(states, ", ", fn s -> s.name end)}")
end)

# Test 4: Simulate a lead status update
IO.puts("\n4. Testing lead status update...")
if length(leads) > 0 do
  lead = List.first(leads)
  old_status = lead.status
  new_status = case old_status do
    "new" -> "contacted"
    "contacted" -> "qualified"
    "qualified" -> "converted"
    _ -> "new"
  end
  
  IO.puts("   Updating lead #{lead.id} from '#{old_status}' to '#{new_status}'")
  
  changeset = EvaaCrmGaepell.Lead.changeset(lead, %{status: new_status})
  case EvaaCrmGaepell.Repo.update(changeset) do
    {:ok, updated_lead} ->
      IO.puts("   ✅ Lead status updated successfully")
      IO.puts("   New status: #{updated_lead.status}")
      
      # Test broadcast
      IO.puts("   Broadcasting update...")
      Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, new_status})
      IO.puts("   ✅ Broadcast sent")
      
    {:error, changeset} ->
      IO.puts("   ❌ Failed to update lead: #{inspect(changeset.errors)}")
  end
else
  IO.puts("   No leads found to test with")
end

# Test 5: Check if the Kanban LiveView can handle the kanban:move event
IO.puts("\n5. Testing kanban:move event handling...")
IO.puts("   The KanbanLive should handle 'kanban:move' events")
IO.puts("   Event should include: id, new_status, old_status, workflow_id")

# Test 6: Check HTML structure
IO.puts("\n6. Checking HTML structure requirements...")
IO.puts("   - Container should have phx-hook='KanbanDragDrop'")
IO.puts("   - Columns should have data-kanban-column attribute")
IO.puts("   - Columns should have data-status and data-workflow attributes")
IO.puts("   - Cards should have data-id attribute")
IO.puts("   - Cards container should have .kanban-col-cards class")

# Test 7: Check JavaScript console for errors
IO.puts("\n7. JavaScript debugging instructions:")
IO.puts("   Open browser console and look for:")
IO.puts("   - 'KanbanDragDrop hook mounted'")
IO.puts("   - 'Found columns with data-kanban-column: X'")
IO.puts("   - 'Creating sortable for column X'")
IO.puts("   - Any JavaScript errors")

# Test 8: Manual testing steps
IO.puts("\n8. Manual testing steps:")
IO.puts("   1. Open Kanban view in browser")
IO.puts("   2. Open browser console (F12)")
IO.puts("   3. Try to drag a lead card to a different column")
IO.puts("   4. Check console for drag events")
IO.puts("   5. Check if the card moves visually")
IO.puts("   6. Check if database is updated")
IO.puts("   7. Check if other views (Prospects) update")

IO.puts("\n=== TEST COMPLETE ===")
IO.puts("If drag-and-drop is not working, check:")
IO.puts("1. Browser console for JavaScript errors")
IO.puts("2. Network tab for failed requests")
IO.puts("3. That Sortable.js is properly loaded")
IO.puts("4. That the KanbanDragDrop hook is mounted")
IO.puts("5. That the HTML has the correct data attributes") 