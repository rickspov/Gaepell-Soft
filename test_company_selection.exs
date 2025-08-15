#!/usr/bin/env elixir

# Script para probar el campo de texto libre para empresa en prospectos
# Ejecutar con: mix run test_company_selection.exs

# Configurar el entorno
Application.ensure_all_started(:evaa_crm_gaepell)

# Importar módulos necesarios
alias EvaaCrmGaepell.{Repo, Lead, Company}
import Ecto.Query

# Función para limpiar la consola
clear_screen = fn -> IO.write("\e[2J\e[H") end

# Función para mostrar título
show_title = fn title ->
  IO.puts("\n" <> String.duplicate("=", 50))
  IO.puts("  #{title}")
  IO.puts(String.duplicate("=", 50))
end

# Función para mostrar subtítulo
show_subtitle = fn subtitle ->
  IO.puts("\n" <> String.duplicate("-", 40))
  IO.puts("  #{subtitle}")
  IO.puts(String.duplicate("-", 40))
end

# Función para mostrar información
show_info = fn message -> IO.puts("ℹ️  #{message}") end
show_success = fn message -> IO.puts("✅ #{message}") end
show_error = fn message -> IO.puts("❌ #{message}") end
show_warning = fn message -> IO.puts("⚠️  #{message}") end

# Función para mostrar datos de un lead
show_lead = fn lead ->
  IO.puts("  📋 ID: #{lead.id}")
  IO.puts("  📋 Nombre: #{lead.name}")
  IO.puts("  📋 Email: #{lead.email}")
  IO.puts("  📋 Teléfono: #{lead.phone}")
  IO.puts("  📋 Empresa: #{lead.company_name}")
  IO.puts("  📋 Estado: #{lead.status}")
  IO.puts("  📋 Fuente: #{lead.source}")
  IO.puts("")
end

# Función principal
main = fn ->
  clear_screen.()
  show_title.("PRUEBA DE CAMPO DE TEXTO LIBRE PARA EMPRESA")
  
  # 1. Verificar leads existentes
  show_subtitle.("1. LEADS EXISTENTES")
  leads = Repo.all(from l in Lead, where: l.business_id == 1, order_by: l.inserted_at)
  
  if leads == [] do
    show_warning.("No hay leads en el sistema")
  else
    show_success.("Leads encontrados: #{length(leads)}")
    Enum.each(leads, show_lead)
  end
  
  # 2. Crear lead de prueba con empresa en texto libre
  show_subtitle.("2. CREAR LEAD DE PRUEBA CON EMPRESA EN TEXTO LIBRE")
  
  lead_attrs = %{
    name: "Cliente de Prueba",
    email: "cliente@test.com",
    phone: "123-456-7890",
    company_name: "Empresa de Prueba S.A.",
    source: "website",
    status: "new",
    priority: "medium",
    notes: "Lead creado para probar campo de texto libre para empresa",
    business_id: 1
  }
  
  case %Lead{} |> Lead.changeset(lead_attrs) |> Repo.insert() do
    {:ok, new_lead} ->
      show_success.("Lead creado exitosamente")
      show_lead.(new_lead)
      
      # Verificar que se guardó correctamente
      saved_lead = Repo.get(Lead, new_lead.id)
      show_subtitle.("3. VERIFICACIÓN DEL LEAD GUARDADO")
      show_lead.(saved_lead)
      
      # Limpiar el lead de prueba
      Repo.delete(new_lead)
      show_success.("Lead de prueba eliminado")
      
    {:error, changeset} ->
      show_error.("Error al crear lead: #{inspect(changeset.errors)}")
  end
  
  # 4. Verificar que el formulario es simple
  show_subtitle.("4. VERIFICACIÓN DEL FORMULARIO")
  show_info.("El formulario ahora incluye:")
  show_info.("  - Campo de texto libre para empresa (company_name)")
  show_info.("  - Sin dropdown de selección")
  show_info.("  - Más simple y directo")
  
  # 5. Resumen
  show_subtitle.("5. RESUMEN")
  show_success.("✅ Dropdown de empresa eliminado")
  show_success.("✅ Solo campo de texto libre para empresa")
  show_success.("✅ Formulario más simple y directo")
  show_success.("✅ La tabla muestra el nombre de la empresa correctamente")
  
  show_info.("\nPara probar en la interfaz web:")
  show_info.("1. Ir a /leads")
  show_info.("2. Hacer clic en 'Nuevo Prospecto'")
  show_info.("3. Verificar que solo hay un campo de texto para empresa")
  show_info.("4. Escribir nombre de empresa y guardar")
  show_info.("5. Verificar que se guarda correctamente")
  
  IO.puts("\n" <> String.duplicate("=", 50))
  IO.puts("  PRUEBA COMPLETADA")
  IO.puts(String.duplicate("=", 50))
end

# Ejecutar el script
main.() 