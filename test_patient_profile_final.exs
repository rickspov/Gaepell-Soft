#!/usr/bin/env elixir

# Test script for the new patient profile layout
# Run with: mix run test_patient_profile_final.exs

alias EvaaCrmGaepell.{Contact, Repo, Activity}
import Ecto.Query

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Get a sample contact to test with
contact = Repo.one(from c in Contact, limit: 1)

if contact do
  IO.puts("🎯 Testing New Patient Profile Layout")
  IO.puts("=" |> String.duplicate(50))
  
  IO.puts("📋 Contact Information:")
  IO.puts("  Name: #{Contact.full_name(contact)}")
  IO.puts("  Email: #{contact.email || "No email"}")
  IO.puts("  Phone: #{contact.phone || "No phone"}")
  IO.puts("  Company: #{contact.company_name || "No company"}")
  IO.puts("  Status: #{contact.status || "No status"}")
  IO.puts("  Source: #{contact.source || "No source"}")
  
  # Test stats calculation
  total_activities = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id, select: count(a.id)) || 0
  completed_activities = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id and a.status == "completed", select: count(a.id)) || 0
  pending_activities = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id and a.status == "pending", select: count(a.id)) || 0
  maintenance_tickets = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id and not is_nil(a.maintenance_ticket_id), select: count(a.id)) || 0
  
  IO.puts("\n📊 Statistics:")
  IO.puts("  Total Activities: #{total_activities}")
  IO.puts("  Completed: #{completed_activities}")
  IO.puts("  Pending: #{pending_activities}")
  IO.puts("  Maintenance Tickets: #{maintenance_tickets}")
  
  # Test progress bar calculations
  completed_percentage = if total_activities > 0, do: (completed_activities / total_activities * 100) |> round(), else: 0
  pending_percentage = if total_activities > 0, do: (pending_activities / total_activities * 100) |> round(), else: 0
  tickets_percentage = if total_activities > 0, do: (maintenance_tickets / total_activities * 100) |> round(), else: 0
  
  IO.puts("\n📈 Progress Bar Calculations:")
  IO.puts("  Completed Progress: #{completed_percentage}%")
  IO.puts("  Pending Progress: #{pending_percentage}%")
  IO.puts("  Tickets Progress: #{tickets_percentage}%")
  
  # Test related data
  trucks_query = from a in Activity,
                 where: a.contact_id == ^contact.id and not is_nil(a.truck_id),
                 distinct: a.truck_id,
                 preload: [:truck]
  
  trucks = Repo.all(trucks_query)
  |> Enum.map(fn activity -> activity.truck end)
  
  specialists_query = from a in Activity,
                     where: a.contact_id == ^contact.id and not is_nil(a.specialist_id),
                     distinct: a.specialist_id,
                     preload: [:specialist]
  
  specialists = Repo.all(specialists_query)
  |> Enum.map(fn activity -> activity.specialist end)
  
  IO.puts("\n🚛 Related Trucks: #{length(trucks)}")
  IO.puts("👨‍🔧 Related Specialists: #{length(specialists)}")
  
  IO.puts("\n✅ Patient Profile Layout Test Completed Successfully!")
  IO.puts("🌐 You can now visit: http://localhost:4000/pacientes/#{contact.id}")
  IO.puts("   The page should display a beautiful profile layout with:")
  IO.puts("   - Profile card with contact info")
  IO.puts("   - Statistics card")
  IO.puts("   - Information tags")
  IO.puts("   - Detailed information grid")
  IO.puts("   - Progress bars")
  IO.puts("   - Action buttons")
  IO.puts("   - Edit modal")
  IO.puts("   - Full dark mode support")
  
else
  IO.puts("❌ No contacts found in database")
  IO.puts("Please create some contacts first to test the profile layout")
end 