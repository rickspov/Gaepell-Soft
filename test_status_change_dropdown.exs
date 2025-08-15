#!/usr/bin/env elixir

# Test script to verify status change via dropdown works correctly
# Run with: mix run test_status_change_dropdown.exs

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Import Ecto.Query
import Ecto.Query

# Get a test ticket
ticket = EvaaCrmGaepell.Repo.get_by(EvaaCrmGaepell.MaintenanceTicket, id: 1)
if ticket do
  IO.puts("=== Testing Status Change via Dropdown ===")
  IO.puts("Current ticket status: #{ticket.status}")
  
  # Test changing status to different values
  test_statuses = ["in_workshop", "final_review", "car_wash", "check_out"]
  
  Enum.each(test_statuses, fn new_status ->
    IO.puts("\n--- Testing change to #{new_status} ---")
    
    # Simulate the update via Fleet context (same as dropdown does)
    case EvaaCrmGaepell.Fleet.update_maintenance_ticket(ticket, %{status: new_status}, 1) do
      {:ok, updated_ticket} ->
        IO.puts("✅ Status changed from #{ticket.status} to #{updated_ticket.status}")
        
        # Check if log was created
        logs = EvaaCrmGaepell.Repo.all(
          from l in EvaaCrmGaepell.ActivityLog,
          where: l.entity_type == "maintenance_ticket" and l.entity_id == ^ticket.id,
          order_by: [desc: l.inserted_at],
          limit: 1
        )
        
        if length(logs) > 0 do
          latest_log = List.first(logs)
          IO.puts("✅ Log created: #{latest_log.action} - #{latest_log.description}")
        else
          IO.puts("❌ No log found for status change")
        end
        
        # Update ticket for next iteration
        ticket = updated_ticket
        
      {:error, changeset} ->
        IO.puts("❌ Error changing status: #{inspect(changeset.errors)}")
    end
  end)
  
  IO.puts("\n=== Test Complete ===")
else
  IO.puts("❌ No ticket found with ID 1")
end 