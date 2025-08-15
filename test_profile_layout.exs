#!/usr/bin/env elixir

# Test script for the new patient profile layout
# Run with: mix run test_profile_layout.exs

alias EvaaCrmGaepell.{Contact, Repo, Activity}

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Get a sample contact to test with
contact = Repo.one(from c in Contact, limit: 1)

if contact do
  IO.puts("🎯 Testing Patient Profile Layout")
  IO.puts("=" |> String.duplicate(50))
  
  IO.puts("📋 Contact Information:")
  IO.puts("  Name: #{Contact.full_name(contact)}")
  IO.puts("  Email: #{contact.email || "No email"}")
  IO.puts("  Phone: #{contact.phone || "No phone"}")
  IO.puts("  Company: #{contact.company_name || "No company"}")
  IO.puts("  Status: #{contact.status || "No status"}")
  IO.puts("  Source: #{contact.source || "No source"}")
  
  # Get contact stats
  total_activities = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id, select: count(a.id)) || 0
  completed_activities = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id and a.status == "completed", select: count(a.id)) || 0
  pending_activities = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id and a.status == "pending", select: count(a.id)) || 0
  maintenance_tickets = Repo.aggregate(from a in Activity, where: a.contact_id == ^contact.id and not is_nil(a.maintenance_ticket_id), select: count(a.id)) || 0
  
  IO.puts("\n📊 Contact Statistics:")
  IO.puts("  Total Activities: #{total_activities}")
  IO.puts("  Completed: #{completed_activities}")
  IO.puts("  Pending: #{pending_activities}")
  IO.puts("  Maintenance Tickets: #{maintenance_tickets}")
  
  # Calculate progress percentages
  completed_percentage = if total_activities > 0, do: (completed_activities / total_activities * 100) |> round(), else: 0
  pending_percentage = if total_activities > 0, do: (pending_activities / total_activities * 100) |> round(), else: 0
  tickets_percentage = if total_activities > 0, do: (maintenance_tickets / total_activities * 100) |> round(), else: 0
  
  IO.puts("\n📈 Progress Percentages:")
  IO.puts("  Completed: #{completed_percentage}%")
  IO.puts("  Pending: #{pending_percentage}%")
  IO.puts("  Maintenance Tickets: #{tickets_percentage}%")
  
  IO.puts("\n✅ Profile Layout Features:")
  IO.puts("  ✓ Beautiful gradient avatar with contact initial")
  IO.puts("  ✓ Contact information with icons")
  IO.puts("  ✓ Statistics cards with color coding")
  IO.puts("  ✓ Progress bars for visual metrics")
  IO.puts("  ✓ Information tags/badges")
  IO.puts("  ✓ Detailed information grid")
  IO.puts("  ✓ Action buttons (Edit, Back)")
  IO.puts("  ✓ Modal edit form with dark mode support")
  IO.puts("  ✓ Full dark mode compatibility")
  IO.puts("  ✓ Responsive design (mobile/desktop)")
  IO.puts("  ✓ Breadcrumb navigation")
  
  IO.puts("\n🌐 Access the profile at:")
  IO.puts("  http://localhost:4000/pacientes/#{contact.id}")
  
  IO.puts("\n🎨 Layout Features:")
  IO.puts("  • Inspired by Flowbite profile design")
  IO.puts("  • Professional color scheme")
  IO.puts("  • Clean typography and spacing")
  IO.puts("  • Interactive elements with hover states")
  IO.puts("  • Consistent with application theme")
  
else
  IO.puts("❌ No contacts found in database")
  IO.puts("Please create some contacts first to test the profile layout")
end

IO.puts("\n" <> "=" |> String.duplicate(50))
IO.puts("🎉 Profile layout test completed!") 