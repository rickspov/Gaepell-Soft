# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     EvaaCrmGaepell.Repo.insert!(%EvaaCrmGaepell.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias EvaaCrmGaepell.{Repo, Business, User, Company, Contact, Lead, Activity}
import Ecto.Changeset

# Password hash helper (for demo, use Comeonin or Argon2 in real app)
defmodule EvaaCrmGaepell.SeedHelper do
  def hash_password("password"), do: "$2b$12$C6UzMDM.H6dfI/f/IKcEeO5r4C0Fq5rF1p/6JZ4G9F6z6F8Q8Q8Q8" # bcrypt for 'password'
  def hash_password(pw), do: pw
end

# Buscar o crear el negocio Spa Demo
spa =
  Repo.get_by(Business, name: "Spa Demo") ||
    Repo.insert!(Business.changeset(%Business{}, %{name: "Spa Demo"}))

# Buscar o crear usuarios demo
admin =
  Repo.get_by(User, email: "admin@eva.com") ||
    Repo.insert!(User.changeset(%User{}, %{
      email: "admin@eva.com",
      password_hash: Bcrypt.hash_pwd_salt("admin123"),
      role: "admin",
      business_id: spa.id
    }))

specialist =
  Repo.get_by(User, email: "especialista@eva.com") ||
    Repo.insert!(User.changeset(%User{}, %{
      email: "especialista@eva.com",
      password_hash: Bcrypt.hash_pwd_salt("especialista123"),
      role: "specialist",
      business_id: spa.id
    }))

patient =
  Repo.get_by(User, email: "paciente@eva.com") ||
    Repo.insert!(User.changeset(%User{}, %{
      email: "paciente@eva.com",
      password_hash: Bcrypt.hash_pwd_salt("paciente123"),
      role: "employee",
      business_id: spa.id
    }))

# Crear doctores demo
dr_garcia =
  Repo.get_by(Company, name: "Dr. María García", business_id: spa.id) ||
    Repo.insert!(Company.changeset(%Company{}, %{
      name: "Dr. María García",
      website: "https://drmariagarcia.com",
      phone: "+52 55 1234 5678",
      email: "dr.garcia@clinica.com",
      address: "Av. Insurgentes Sur 1234, Consultorio 5",
      city: "CDMX",
      state: "CDMX",
      country: "México",
      postal_code: "03800",
      industry: "Cirugía Plástica",
      size: "medium",
      description: "Especialista en cirugía plástica y reconstructiva con más de 15 años de experiencia.",
      status: "active",
      business_id: spa.id
    }))

dr_rodriguez =
  Repo.get_by(Company, name: "Dr. Carlos Rodríguez", business_id: spa.id) ||
    Repo.insert!(Company.changeset(%Company{}, %{
      name: "Dr. Carlos Rodríguez",
      website: "https://drcarlosrodriguez.com",
      phone: "+52 55 9876 5432",
      email: "dr.rodriguez@clinica.com",
      address: "Av. Reforma 567, Piso 3",
      city: "CDMX",
      state: "CDMX",
      country: "México",
      postal_code: "06500",
      industry: "Dermatología",
      size: "medium",
      description: "Dermatólogo especializado en medicina estética y tratamientos láser.",
      status: "active",
      business_id: spa.id
    }))

# Crear contacto demo (paciente)
john =
  Repo.get_by(Contact, email: "john.paciente@spa.com", business_id: spa.id) ||
    Repo.insert!(Contact.changeset(%Contact{}, %{
      first_name: "John",
      last_name: "Paciente",
      email: "john.paciente@spa.com",
      phone: "+52 55 9876 5432",
      job_title: "Paciente",
      department: "",
      address: "Calle Salud 456",
      city: "CDMX",
      state: "CDMX",
      country: "México",
      status: "active",
      source: "website",
      tags: ["Postquirúrgico", "VIP"],
      business_id: spa.id,
      company_id: dr_garcia.id
    }))

# Crear lead demo (nuevo prospecto)
lead =
  Repo.get_by(Lead, email: "jane.prospecto@spa.com", business_id: spa.id) ||
    Repo.insert!(Lead.changeset(%Lead{}, %{
      first_name: "Jane",
      last_name: "Prospecto",
      email: "jane.prospecto@spa.com",
      phone: "+52 55 1111 2222",
      company_name: "Paciente Particular",
      job_title: "Paciente",
      source: "event",
      status: "new",
      priority: "high",
      notes: "Interesada en tratamiento postquirúrgico facial.",
      expected_value: 12000.00,
      expected_close_date: ~D[2024-08-15],
      tags: ["Evento", "Facial"],
      business_id: spa.id,
      assigned_to_id: specialist.id,
      company_id: dr_rodriguez.id
    }))

# Crear actividades demo
Repo.get_by(Activity, title: "Llamada de seguimiento a John Paciente", business_id: spa.id) ||
  Repo.insert!(Activity.changeset(%Activity{}, %{
    type: "call",
    title: "Llamada de seguimiento a John Paciente",
    description: "Llamada para verificar evolución postquirúrgica y agendar cita de revisión.",
    due_date: ~U[2024-07-01 10:00:00Z],
    priority: "medium",
    status: "completed",
    business_id: spa.id,
    user_id: specialist.id,
    contact_id: john.id,
    lead_id: nil,
    company_id: dr_garcia.id
  }))

Repo.get_by(Activity, title: "Nota sobre lead Jane Prospecto", business_id: spa.id) ||
  Repo.insert!(Activity.changeset(%Activity{}, %{
    type: "note",
    title: "Nota sobre lead Jane Prospecto",
    description: "Solicitó información sobre paquetes de recuperación postquirúrgica.",
    due_date: ~U[2024-07-02 12:00:00Z],
    priority: "low",
    status: "pending",
    business_id: spa.id,
    user_id: specialist.id,
    contact_id: nil,
    lead_id: lead.id,
    company_id: dr_rodriguez.id
  }))

# Crear servicios de Bodhi
services = [
  # Masajes
  %{
    name: "Masaje Relajante",
    description: "Masaje terapéutico para relajación muscular y reducción del estrés",
    price: Decimal.new("45.00"),
    duration_minutes: 60,
    service_type: "individual",
    category: "masaje",
    business_id: spa.id
  },
  %{
    name: "Masaje Reductor",
    description: "Masaje especializado para reducir grasa localizada y mejorar la circulación",
    price: Decimal.new("55.00"),
    duration_minutes: 60,
    service_type: "individual",
    category: "masaje",
    business_id: spa.id
  },
  %{
    name: "Masaje Deportivo",
    description: "Masaje para deportistas, recuperación muscular y prevención de lesiones",
    price: Decimal.new("50.00"),
    duration_minutes: 60,
    service_type: "individual",
    category: "masaje",
    business_id: spa.id
  },
  %{
    name: "Masaje Post-Quirúrgico",
    description: "Masaje especializado para recuperación post-cirugía estética",
    price: Decimal.new("60.00"),
    duration_minutes: 60,
    service_type: "individual",
    category: "masaje",
    business_id: spa.id
  },
  # Terapias
  %{
    name: "Cámara Hiperbárica",
    description: "Terapia de oxigenación hiperbárica para acelerar la recuperación",
    price: Decimal.new("80.00"),
    duration_minutes: 90,
    service_type: "individual",
    category: "terapia",
    business_id: spa.id
  },
  %{
    name: "Indiba",
    description: "Terapia de radiofrecuencia para regeneración celular y drenaje linfático",
    price: Decimal.new("70.00"),
    duration_minutes: 45,
    service_type: "individual",
    category: "terapia",
    business_id: spa.id
  },
  # Psicología
  %{
    name: "Consulta Psicológica Pre-Quirúrgica",
    description: "Evaluación psicológica previa a cirugía estética",
    price: Decimal.new("65.00"),
    duration_minutes: 60,
    service_type: "individual",
    category: "psicologia",
    business_id: spa.id
  },
  %{
    name: "Consulta Psicológica Post-Quirúrgica",
    description: "Seguimiento psicológico post-cirugía estética",
    price: Decimal.new("65.00"),
    duration_minutes: 60,
    service_type: "individual",
    category: "psicologia",
    business_id: spa.id
  },
  # Otros servicios
  %{
    name: "Limpieza de Vendaje",
    description: "Limpieza y cambio de vendajes post-quirúrgicos",
    price: Decimal.new("35.00"),
    duration_minutes: 30,
    service_type: "individual",
    category: "limpieza",
    business_id: spa.id
  },
  %{
    name: "Tratamiento Láser",
    description: "Tratamiento láser para cicatrices y rejuvenecimiento",
    price: Decimal.new("120.00"),
    duration_minutes: 45,
    service_type: "individual",
    category: "laser",
    business_id: spa.id
  }
]

Enum.each(services, fn service_attrs ->
  case Repo.get_by(EvaaCrmGaepell.Service, name: service_attrs.name, business_id: spa.id) do
  nil ->
    %EvaaCrmGaepell.Service{}
    |> EvaaCrmGaepell.Service.changeset(service_attrs)
      |> Repo.insert!()
    _existing ->
      :ok
  end
end)

# Crear especialistas
specialists = [
  %{
    first_name: "María",
    last_name: "González",
    email: "maria.gonzalez@bodhi.com",
    phone: "+1-555-0101",
    specialization: "Masaje Terapéutico",
    business_id: spa.id
  },
  %{
    first_name: "Ana",
    last_name: "Rodríguez",
    email: "ana.rodriguez@bodhi.com",
    phone: "+1-555-0102",
    specialization: "Terapia Física",
    business_id: spa.id
  },
  %{
    first_name: "Dr. Laura",
    last_name: "Martínez",
    email: "laura.martinez@bodhi.com",
    phone: "+1-555-0103",
    specialization: "Psicología",
    business_id: spa.id
  },
  %{
    first_name: "Carmen",
    last_name: "López",
    email: "carmen.lopez@bodhi.com",
    phone: "+1-555-0104",
    specialization: "Enfermería",
    business_id: spa.id
  }
]

Enum.each(specialists, fn specialist_attrs ->
  case Repo.get_by(EvaaCrmGaepell.Specialist, email: specialist_attrs.email, business_id: spa.id) do
  nil ->
    %EvaaCrmGaepell.Specialist{}
    |> EvaaCrmGaepell.Specialist.changeset(specialist_attrs)
      |> Repo.insert!()
    _existing ->
      :ok
  end
end)

# Crear paquetes de ejemplo
packages = [
  %{
    name: "Paquete Post-Cirugía Básico",
    description: "Paquete básico de recuperación post-cirugía estética",
    total_price: Decimal.new("280.00"),
    discount_percentage: Decimal.new("15.0"),
    business_id: spa.id
  },
  %{
    name: "Paquete Post-Cirugía Premium",
    description: "Paquete completo de recuperación post-cirugía estética",
    total_price: Decimal.new("450.00"),
    discount_percentage: Decimal.new("20.0"),
    business_id: spa.id
  },
  %{
    name: "Paquete Bienestar",
    description: "Paquete de servicios de bienestar y relajación",
    total_price: Decimal.new("180.00"),
    discount_percentage: Decimal.new("10.0"),
    business_id: spa.id
  }
]

Enum.each(packages, fn package_attrs ->
  case Repo.get_by(EvaaCrmGaepell.Package, name: package_attrs.name, business_id: spa.id) do
  nil ->
    %EvaaCrmGaepell.Package{}
    |> EvaaCrmGaepell.Package.changeset(package_attrs)
      |> Repo.insert!()
    _existing ->
      :ok
  end
end)

# Asignar servicios a paquetes
package_services = [
  # Paquete Básico: 2 masajes post-quirúrgicos + 1 cámara hiperbárica + 1 consulta psicológica
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Básico").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Masaje Post-Quirúrgico").id,
    quantity: 2,
    service_order: 1
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Básico").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Cámara Hiperbárica").id,
    quantity: 1,
    service_order: 2
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Básico").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Consulta Psicológica Post-Quirúrgica").id,
    quantity: 1,
    service_order: 3
  },
  # Paquete Premium: 4 masajes post-quirúrgicos + 2 cámaras hiperbáricas + 2 indiba + 2 consultas psicológicas + 2 limpiezas
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Premium").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Masaje Post-Quirúrgico").id,
    quantity: 4,
    service_order: 1
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Premium").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Cámara Hiperbárica").id,
    quantity: 2,
    service_order: 2
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Premium").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Indiba").id,
    quantity: 2,
    service_order: 3
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Premium").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Consulta Psicológica Post-Quirúrgica").id,
    quantity: 2,
    service_order: 4
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Post-Cirugía Premium").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Limpieza de Vendaje").id,
    quantity: 2,
    service_order: 5
  },
  # Paquete Bienestar: 2 masajes relajantes + 1 masaje deportivo
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Bienestar").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Masaje Relajante").id,
    quantity: 2,
    service_order: 1
  },
  %{
          package_id: Repo.get_by!(EvaaCrmGaepell.Package, name: "Paquete Bienestar").id,
      service_id: Repo.get_by!(EvaaCrmGaepell.Service, name: "Masaje Deportivo").id,
    quantity: 1,
    service_order: 2
  }
]

Enum.each(package_services, fn package_service_attrs ->
  case Repo.get_by(EvaaCrmGaepell.PackageService, package_id: package_service_attrs.package_id, service_id: package_service_attrs.service_id) do
  nil ->
    %EvaaCrmGaepell.PackageService{}
    |> EvaaCrmGaepell.PackageService.changeset(package_service_attrs)
      |> Repo.insert!()
    _existing ->
      :ok
  end
end)

IO.puts("✅ Datos de Bodhi creados exitosamente!")
IO.puts("   - #{length(services)} servicios creados")
IO.puts("   - #{length(specialists)} especialistas creados")
IO.puts("   - #{length(packages)} paquetes creados")
IO.puts("   - #{length(package_services)} servicios asignados a paquetes")
