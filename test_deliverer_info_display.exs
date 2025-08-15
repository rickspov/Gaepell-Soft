# Test script to verify deliverer information display in ticket profile modal
# Run with: mix run test_deliverer_info_display.exs

alias EvaaCrmGaepell.{Repo, MaintenanceTicket, Truck, Business}

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Create a test business if it doesn't exist
business = case Repo.get_by(Business, name: "Test Business") do
  nil -> 
    case %Business{}
    |> Business.changeset(%{name: "Test Business", description: "Test business for deliverer info"})
    |> Repo.insert() do
      {:ok, business} -> business
      {:error, changeset} -> 
        IO.puts("⚠️  Could not create business: #{inspect(changeset.errors)}")
        # Try to get an existing business instead
        case Repo.all(Business) |> List.first() do
          nil -> 
            IO.puts("❌ No businesses found in database. Please create a business first.")
            System.halt(1)
          existing_business -> existing_business
        end
    end
  existing -> existing
end

# Create a test truck if it doesn't exist
truck = case Repo.get_by(Truck, license_plate: "TEST123") do
  nil ->
    %Truck{}
    |> Truck.changeset(%{
      brand: "Test Brand",
      model: "Test Model",
      license_plate: "TEST123",
      year: 2020,
      business_id: business.id
    })
    |> Repo.insert!()
  existing -> existing
end

# Create a test ticket with deliverer information
ticket_params = %{
  title: "Test Ticket with Deliverer Info",
  description: "Entregador: Juan Pérez | Doc: DNI 12345678 | Tel: +51 999 888 777 | Email: juan.perez@test.com | Empresa: Test Company | Cargo: Conductor | Autorización: Propietario | KM: 50000 | Combustible: Lleno",
  priority: "medium",
  status: "check_in",
  entry_date: DateTime.utc_now(),
  mileage: 50000,
  fuel_level: "full",
  visible_damage: "Sin daños visibles",
  business_id: business.id,
  truck_id: truck.id,
  # Deliverer information
  deliverer_name: "Juan Pérez",
  document_type: "dni",
  document_number: "12345678",
  deliverer_phone: "+51 999 888 777",
  deliverer_email: "juan.perez@test.com",
  deliverer_address: "Av. Test 123, Lima, Perú",
  company_name: "Test Company",
  position: "Conductor",
  employee_number: "EMP001",
  authorization_type: "propietario",
  special_conditions: "Manejar con cuidado, vehículo nuevo"
}

# Create the ticket
case Repo.get_by(MaintenanceTicket, title: "Test Ticket with Deliverer Info") do
  nil ->
    ticket = %MaintenanceTicket{}
    |> MaintenanceTicket.changeset(ticket_params)
    |> Repo.insert!()
    
    IO.puts("✅ Test ticket created successfully!")
    IO.puts("   - Ticket ID: #{ticket.id}")
    IO.puts("   - Title: #{ticket.title}")
    IO.puts("   - Deliverer: #{ticket.deliverer_name}")
    IO.puts("   - Document: #{ticket.document_type} #{ticket.document_number}")
    IO.puts("   - Phone: #{ticket.deliverer_phone}")
    IO.puts("   - Email: #{ticket.deliverer_email}")
    IO.puts("   - Company: #{ticket.company_name}")
    IO.puts("   - Position: #{ticket.position}")
    IO.puts("   - Authorization: #{ticket.authorization_type}")
    IO.puts("   - Special Conditions: #{ticket.special_conditions}")
    IO.puts("")
    IO.puts("🎯 To test the modal:")
    IO.puts("   1. Go to /maintenance_tickets")
    IO.puts("   2. Click on the truck name in the table")
    IO.puts("   3. You should see the 'Información del Entregador' section")
    IO.puts("   4. All deliverer information should be displayed correctly")
    
  existing ->
    IO.puts("ℹ️  Test ticket already exists with ID: #{existing.id}")
    IO.puts("   - Deliverer: #{existing.deliverer_name}")
    IO.puts("   - Document: #{existing.document_type} #{existing.document_number}")
    IO.puts("")
    IO.puts("🎯 To test the modal:")
    IO.puts("   1. Go to /maintenance_tickets")
    IO.puts("   2. Click on the truck name in the table")
    IO.puts("   3. You should see the 'Información del Entregador' section")
end

# Also test a ticket without deliverer info
case Repo.get_by(MaintenanceTicket, title: "Test Ticket without Deliverer Info") do
  nil ->
    ticket_without_deliverer = %MaintenanceTicket{}
    |> MaintenanceTicket.changeset(%{
      title: "Test Ticket without Deliverer Info",
      description: "Regular ticket without deliverer information",
      priority: "medium",
      status: "check_in",
      entry_date: DateTime.utc_now(),
      mileage: 30000,
      fuel_level: "half",
      visible_damage: "Sin daños visibles",
      business_id: business.id,
      truck_id: truck.id
    })
    |> Repo.insert!()
    
    IO.puts("✅ Test ticket without deliverer info created!")
    IO.puts("   - Ticket ID: #{ticket_without_deliverer.id}")
    IO.puts("   - This ticket should NOT show the deliverer section in the modal")
    
  existing ->
    IO.puts("ℹ️  Test ticket without deliverer info already exists with ID: #{existing.id}")
end

IO.puts("")
IO.puts("🎉 Test setup complete!")
IO.puts("   - Ticket with deliverer info: ID #{case Repo.get_by(MaintenanceTicket, title: "Test Ticket with Deliverer Info") do nil -> "N/A"; ticket -> ticket.id end}")
IO.puts("   - Ticket without deliverer info: ID #{case Repo.get_by(MaintenanceTicket, title: "Test Ticket without Deliverer Info") do nil -> "N/A"; ticket -> ticket.id end}")
IO.puts("")
IO.puts("📋 Test both tickets to verify:")
IO.puts("   1. Ticket WITH deliverer info should show the red 'Información del Entregador' section")
IO.puts("   2. Ticket WITHOUT deliverer info should NOT show the deliverer section")
IO.puts("   3. All deliverer fields should display correctly when present") 