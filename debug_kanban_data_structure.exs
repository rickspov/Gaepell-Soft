#!/usr/bin/env elixir

# Debug script for Kanban data structure
# Run with: mix run debug_kanban_data_structure.exs

import Ecto.Query

IO.puts("=== DEBUGGING KANBAN DATA STRUCTURE ===")

# Load the application
Application.ensure_all_started(:evaa_crm_gaepell)

IO.puts("\n1. Checking leads in database...")
leads = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.Lead)
IO.puts("   Found #{length(leads)} leads")

Enum.each(leads, fn lead ->
  IO.puts("   - Lead #{lead.id}: #{lead.name} (status: #{lead.status}, business_id: #{lead.business_id})")
end)

IO.puts("\n2. Checking workflows...")
workflows = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.Workflow)
IO.puts("   Found #{length(workflows)} workflows")

leads_workflows = workflows |> Enum.filter(fn w -> w.workflow_type == "leads" end)
IO.puts("   Found #{length(leads_workflows)} leads workflows")

Enum.each(leads_workflows, fn workflow ->
  states = EvaaCrmGaepell.Repo.preload(workflow, :workflow_states).workflow_states
  IO.puts("   - Workflow #{workflow.id}: #{workflow.name} (business_id: #{workflow.business_id})")
  IO.puts("     States: #{Enum.map_join(states, ", ", fn s -> s.name end)}")
end)

IO.puts("\n3. Testing Kanban data structure...")
filters = %{tipo: "todos", workflow: "todos", compania: "1", camion: "todos", fecha: nil}

# Simulate the load_kanban_items function
IO.puts("   Loading items with filters: #{inspect(filters)}")

# Get workflows
workflows = EvaaCrmGaepell.Repo.all(from w in EvaaCrmGaepell.Workflow, 
  where: w.is_active == true,
  preload: [workflow_states: ^(from ws in EvaaCrmGaepell.WorkflowState, order_by: ws.order_index)])

# Filter workflows by company
selected_company_id = 1
filtered_workflows = workflows
|> Enum.filter(fn workflow -> 
  workflow.workflow_type in ["maintenance", "production", "leads"] and workflow.business_id == selected_company_id
end)

IO.puts("   Filtered workflows: #{length(filtered_workflows)}")

# Load leads
leads = EvaaCrmGaepell.Repo.all(from l in EvaaCrmGaepell.Lead, 
  where: l.business_id == ^selected_company_id,
  order_by: l.inserted_at)

IO.puts("   Leads for company #{selected_company_id}: #{length(leads)}")

# Process leads for each workflow
Enum.each(filtered_workflows, fn workflow ->
  IO.puts("\n   Processing workflow: #{workflow.name} (#{workflow.workflow_type})")
  
  workflow_items = case workflow.workflow_type do
    "leads" -> 
      leads
      |> Enum.map(fn lead -> 
        %{
          id: "l-#{lead.id}",
          title: lead.name || "Lead #{lead.id}",
          description: lead.notes || "Lead",
          status: lead.status || "new",
          workflow_id: nil,
          workflow_type: "leads",
          color: "#10B981",
          company_name: "Furcar",
          truck_name: nil,
          due_date: lead.next_follow_up,
          priority: "medium",
          specialist_name: nil,
          created_at: lead.inserted_at
        }
      end)
    _ -> []
  end
  
  IO.puts("     Created #{length(workflow_items)} items")
  
  # Group by state
  workflow_states = workflow.workflow_states
  items_by_state = workflow_states
  |> Enum.map(fn state ->
    state_items = workflow_items
    |> Enum.filter(fn item -> 
      item.status == state.name
    end)
    
    IO.puts("     State '#{state.name}': #{length(state_items)} items")
    Enum.each(state_items, fn item ->
      IO.puts("       - #{item.id}: #{item.title} (status: #{item.status})")
    end)
    
    %{
      workflow_id: workflow.id,
      workflow_name: workflow.name,
      workflow_type: workflow.workflow_type,
      state: state,
      items: state_items,
      count: length(state_items)
    }
  end)
  
  IO.puts("     Total items: #{length(workflow_items)}")
end)

IO.puts("\n4. Testing HTML structure...")
IO.puts("   Each lead card should have:")
IO.puts("   - data-id='l-{lead_id}'")
IO.puts("   - draggable='true'")
IO.puts("   - class containing 'kanban-card'")

IO.puts("\n5. Testing JavaScript detection...")
IO.puts("   JavaScript should find:")
IO.puts("   - Columns with data-kanban-column")
IO.puts("   - Cards with data-id attributes")
IO.puts("   - Cards with draggable='true'")

IO.puts("\n6. Manual verification steps:")
IO.puts("   a) Open browser console")
IO.puts("   b) Run: document.querySelectorAll('[data-id^=\"l-\"]')")
IO.puts("   c) Should return lead cards")
IO.puts("   d) Run: document.querySelectorAll('[data-kanban-column]')")
IO.puts("   e) Should return Kanban columns")

IO.puts("\n=== DEBUG COMPLETE ===") 