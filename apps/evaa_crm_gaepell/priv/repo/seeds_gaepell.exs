# Gaepell CRM Seeds - Datos empresariales para manufactura y logística
alias EvaaCrmGaepell.{Repo, Business, User, Company, Contact, Lead, Activity, Service, Specialist, Truck, MaintenanceTicket}
import Ecto.Query

# Crear el negocio principal (Gaepell)
gaepell = case Repo.get_by(Business, name: "Gaepell Consortium") do
  nil ->
    %Business{}
    |> Business.changeset(%{
      name: "Gaepell Consortium",
      description: "Consorcio dominicano especializado en manufactura y logística",
      industry: "Manufactura y Logística",
      address: "Santo Domingo, República Dominicana",
      phone: "+1-809-555-0100",
      email: "info@gaepell.com",
      website: "https://gaepell.com"
    })
    |> Repo.insert!()
  
  existing -> existing
end

# Crear usuarios administradores
admin_user = case Repo.get_by(User, email: "admin@eva.com") do
  nil ->
    %User{}
    |> User.changeset(%{
      email: "admin@eva.com",
      password: "admin123",
      password_confirmation: "admin123",
      role: "admin",
      business_id: gaepell.id
    })
    |> Repo.insert!()
  
  existing -> existing
end

manager_user = case Repo.get_by(User, email: "manager@gaepell.com") do
  nil ->
    %User{}
    |> User.changeset(%{
      email: "manager@gaepell.com",
      password: "manager123",
      password_confirmation: "manager123",
      role: "manager",
      business_id: gaepell.id
    })
    |> Repo.insert!()
  
  existing -> existing
end

# Crear empresas del Grupo Gaepell
companies_data = [
  %{
    name: "Furcar",
    description: "Empresa especializada en fabricación de cajas para camiones y servicios de mantenimiento",
    industry: "Manufactura y Mantenimiento",
    address: "Santiago, República Dominicana",
    phone: "+1-809-555-0200",
    email: "contacto@furcar.com",
    website: "https://furcar.com"
  },
  %{
    name: "Blidomca",
    description: "Empresa especializada en servicios de blindaje y protección vehicular",
    industry: "Blindaje y Seguridad",
    address: "Santo Domingo, República Dominicana",
    phone: "+1-809-555-0300",
    email: "info@blidomca.com",
    website: "https://blidomca.com"
  },
  %{
    name: "Grupo Gaepell",
    description: "Consorcio dominicano especializado en manufactura y logística",
    industry: "Consorcio",
    address: "Santo Domingo, República Dominicana",
    phone: "+1-809-555-0100",
    email: "info@gaepell.com",
    website: "https://gaepell.com"
  }
]

companies = Enum.map(companies_data, fn company_attrs ->
  case Repo.get_by(Company, name: company_attrs.name, business_id: gaepell.id) do
    nil ->
      %Company{}
      |> Company.changeset(Map.put(company_attrs, :business_id, gaepell.id))
      |> Repo.insert!()
    
    existing -> existing
  end
end)

# Crear contactos de las empresas Gaepell
contacts_data = [
  %{
    first_name: "Carlos",
    last_name: "Rodríguez",
    email: "carlos.rodriguez@furcar.com",
    phone: "+1-809-555-0201",
    job_title: "Director de Operaciones",
    status: "active",
    source: "referral",
    company_id: Enum.find(companies, &(&1.name == "Furcar")).id
  },
  %{
    first_name: "María",
    last_name: "González",
    email: "maria.gonzalez@furcar.com",
    phone: "+1-809-555-0202",
    job_title: "Gerente de Mantenimiento",
    status: "active",
    source: "website",
    company_id: Enum.find(companies, &(&1.name == "Furcar")).id
  },
  %{
    first_name: "Roberto",
    last_name: "Martínez",
    email: "roberto.martinez@blidomca.com",
    phone: "+1-809-555-0301",
    job_title: "Director de Blindaje",
    status: "active",
    source: "event",
    company_id: Enum.find(companies, &(&1.name == "Blidomca")).id
  },
  %{
    first_name: "Ana",
    last_name: "López",
    email: "ana.lopez@blidomca.com",
    phone: "+1-809-555-0302",
    job_title: "Gerente de Instalaciones",
    status: "active",
    source: "referral",
    company_id: Enum.find(companies, &(&1.name == "Blidomca")).id
  },
  %{
    first_name: "José",
    last_name: "Hernández",
    email: "jose.hernandez@gaepell.com",
    phone: "+1-809-555-0101",
    job_title: "Director General",
    status: "active",
    source: "referral",
    company_id: Enum.find(companies, &(&1.name == "Grupo Gaepell")).id
  }
]

Enum.each(contacts_data, fn contact_attrs ->
  case Repo.get_by(Contact, email: contact_attrs.email, business_id: gaepell.id) do
    nil ->
      %Contact{}
      |> Contact.changeset(Map.put(contact_attrs, :business_id, gaepell.id))
      |> Repo.insert!()
    
    _existing -> :ok
  end
end)

# Crear especialistas (mecánicos, técnicos)
specialists_data = [
  %{
    first_name: "Miguel",
    last_name: "Santos",
    email: "miguel.santos@gaepell.com",
    phone: "+1-809-555-0601",
    specialization: "Mecánico",
    status: "active",
    business_id: gaepell.id
  },
  %{
    first_name: "Pedro",
    last_name: "Ramírez",
    email: "pedro.ramirez@gaepell.com",
    phone: "+1-809-555-0602",
    specialization: "Eléctrico",
    status: "active",
    business_id: gaepell.id
  },
  %{
    first_name: "Luis",
    last_name: "Fernández",
    email: "luis.fernandez@gaepell.com",
    phone: "+1-809-555-0603",
    specialization: "Técnico",
    status: "active",
    business_id: gaepell.id
  }
]

Enum.each(specialists_data, fn specialist_attrs ->
  case Repo.get_by(Specialist, email: specialist_attrs.email, business_id: gaepell.id) do
    nil ->
      %Specialist{}
      |> Specialist.changeset(specialist_attrs)
      |> Repo.insert!()
    
    _existing -> :ok
  end
end)

# Crear servicios de mantenimiento
services_data = [
  %{
    name: "Mantenimiento Preventivo",
    description: "Servicio de mantenimiento preventivo para flota de camiones",
    price: 500.00,
    duration: 120,
    service_type: "individual",
    category: "mantenimiento",
    business_id: gaepell.id
  },
  %{
    name: "Reparación de Motor",
    description: "Servicio de reparación y diagnóstico de motores",
    price: 1500.00,
    duration: 240,
    service_type: "individual",
    category: "reparacion",
    business_id: gaepell.id
  },
  %{
    name: "Reparación de Sistema Eléctrico",
    description: "Diagnóstico y reparación de sistemas eléctricos",
    price: 800.00,
    duration: 180,
    service_type: "individual",
    category: "reparacion",
    business_id: gaepell.id
  },
  %{
    name: "Cambio de Aceite y Filtros",
    description: "Servicio de cambio de aceite y filtros",
    price: 200.00,
    duration: 60,
    service_type: "individual",
    category: "mantenimiento",
    business_id: gaepell.id
  },
  %{
    name: "Reparación de Frenos",
    description: "Servicio de reparación y mantenimiento de frenos",
    price: 600.00,
    duration: 150,
    service_type: "individual",
    category: "reparacion",
    business_id: gaepell.id
  }
]

Enum.each(services_data, fn service_attrs ->
  case Repo.get_by(Service, name: service_attrs.name, business_id: gaepell.id) do
    nil ->
      %Service{}
      |> Service.changeset(service_attrs)
      |> Repo.insert!()
    
    _existing -> :ok
  end
end)

# Crear camiones de ejemplo
trucks_data = [
  %{
    license_plate: "ABC-123",
    brand: "Volvo",
    model: "FH16",
    year: 2020,
    capacity: "20 toneladas",
    fuel_type: "diesel",
    status: "active",
    business_id: gaepell.id
  },
  %{
    license_plate: "XYZ-456",
    brand: "Mercedes-Benz",
    model: "Actros",
    year: 2019,
    capacity: "15 toneladas",
    fuel_type: "diesel",
    status: "maintenance",
    business_id: gaepell.id
  },
  %{
    license_plate: "DEF-789",
    brand: "Scania",
    model: "R500",
    year: 2021,
    capacity: "25 toneladas",
    fuel_type: "diesel",
    status: "active",
    business_id: gaepell.id
  }
]

Enum.each(trucks_data, fn truck_attrs ->
  case Repo.get_by(Truck, license_plate: truck_attrs.license_plate, business_id: gaepell.id) do
    nil ->
      %Truck{}
      |> Truck.changeset(truck_attrs)
      |> Repo.insert!()
    
    _existing -> :ok
  end
end)

# Crear tickets de mantenimiento de ejemplo
trucks = Repo.all(from t in Truck, where: t.business_id == ^gaepell.id)
specialists = Repo.all(from s in Specialist, where: s.business_id == ^gaepell.id)

if length(trucks) > 0 and length(specialists) > 0 do
  maintenance_tickets_data = [
    %{
      title: "Mantenimiento preventivo programado",
      description: "Mantenimiento preventivo mensual del camión",
      priority: "medium",
      status: "open",
      truck_id: List.first(trucks).id,
      specialist_id: List.first(specialists).id,
      business_id: gaepell.id
    },
    %{
      title: "Reparación de sistema de frenos",
      description: "El camión presenta problemas en el sistema de frenos",
      priority: "high",
      status: "in_progress",
      truck_id: Enum.at(trucks, 1).id,
      specialist_id: Enum.at(specialists, 1).id,
      business_id: gaepell.id
    }
  ]

  Enum.each(maintenance_tickets_data, fn ticket_attrs ->
    case Repo.get_by(MaintenanceTicket, title: ticket_attrs.title, truck_id: ticket_attrs.truck_id) do
      nil ->
        %MaintenanceTicket{}
        |> MaintenanceTicket.changeset(ticket_attrs)
        |> Repo.insert!()
      
      _existing -> :ok
    end
  end)
end

IO.puts("✅ Seeds de Gaepell CRM creados exitosamente!")
IO.puts("📧 Usuario admin: admin@eva.com / admin123")
IO.puts("📧 Usuario manager: manager@gaepell.com / manager123")
IO.puts("🏢 Empresas cliente creadas: #{length(companies)}")
IO.puts("👥 Contactos creados: #{length(contacts_data)}")
IO.puts("🔧 Especialistas creados: #{length(specialists_data)}")
IO.puts("🚛 Camiones creados: #{length(trucks_data)}") 