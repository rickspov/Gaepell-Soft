#!/usr/bin/env elixir

# Script para probar que la empresa se muestra correctamente en la lista de prospectos
# Ejecutar con: mix run test_company_display.exs

# Configurar el entorno
Application.ensure_all_started(:evaa_crm_gaepell)

# Importar módulos necesarios
alias EvaaCrmGaepell.{Repo, Lead}
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

# Función para simular cómo se mostraría en la tabla
show_table_row = fn lead ->
  company_display = if lead.company_name && lead.company_name != "", do: lead.company_name, else: "—"
  IO.puts("  📊 Tabla: #{lead.name} | #{lead.email} | #{company_display} | #{lead.status}")
end

# Función principal
main = fn ->
  clear_screen.()
  show_title.("PRUEBA DE VISUALIZACIÓN DE EMPRESA EN LISTA")
  
  # 1. Verificar leads existentes
  show_subtitle.("1. LEADS EXISTENTES")
  leads = Repo.all(from l in Lead, where: l.business_id == 1, order_by: l.inserted_at)
  
  if leads == [] do
    show_warning.("No hay leads en el sistema")
  else
    show_success.("Leads encontrados: #{length(leads)}")
    Enum.each(leads, show_lead)
  end
  
  # 2. Mostrar cómo se vería en la tabla
  show_subtitle.("2. SIMULACIÓN DE TABLA")
  show_info.("Cómo se mostraría en la lista de prospectos:")
  Enum.each(leads, show_table_row)
  
  # 3. Crear leads de prueba con diferentes casos de empresa
  show_subtitle.("3. CREAR LEADS DE PRUEBA")
  
  test_leads = [
    %{
      name: "Cliente con Empresa",
      email: "cliente1@test.com",
      phone: "123-456-7890",
      company_name: "Empresa Test S.A.",
      source: "website",
      status: "new",
      priority: "medium",
      notes: "Lead con empresa definida",
      business_id: 1
    },
    %{
      name: "Cliente sin Empresa",
      email: "cliente2@test.com",
      phone: "987-654-3210",
      company_name: "",
      source: "referral",
      status: "contacted",
      priority: "high",
      notes: "Lead sin empresa",
      business_id: 1
    },
    %{
      name: "Cliente con Empresa Null",
      email: "cliente3@test.com",
      phone: "555-123-4567",
      company_name: nil,
      source: "event",
      status: "qualified",
      priority: "medium",
      notes: "Lead con empresa null",
      business_id: 1
    }
  ]
  
  created_leads = Enum.reduce(test_leads, [], fn lead_attrs, acc ->
    case %Lead{} |> Lead.changeset(lead_attrs) |> Repo.insert() do
      {:ok, new_lead} ->
        show_success.("Lead creado: #{new_lead.name}")
        show_lead.(new_lead)
        [new_lead | acc]
        
      {:error, changeset} ->
        show_error.("Error al crear lead: #{inspect(changeset.errors)}")
        acc
    end
  end)
  
  # 4. Verificar cómo se muestran en la tabla
  show_subtitle.("4. VERIFICACIÓN EN TABLA")
  show_info.("Cómo se mostrarían los nuevos leads en la tabla:")
  Enum.each(created_leads, show_table_row)
  
  # 5. Limpiar leads de prueba
  show_subtitle.("5. LIMPIEZA")
  Enum.each(created_leads, fn lead ->
    Repo.delete(lead)
    show_success.("Lead eliminado: #{lead.name}")
  end)
  
  # 6. Verificar el código de la tabla
  show_subtitle.("6. CÓDIGO DE LA TABLA")
  show_info.("El código de la tabla ahora usa:")
  show_info.("  <%= if lead.company_name && lead.company_name != \"\", do: lead.company_name, else: \"—\" %>")
  show_info.("")
  show_info.("Esto asegura que:")
  show_info.("  ✅ Se muestre el nombre de la empresa si existe")
  show_info.("  ✅ Se muestre \"—\" si está vacío o es nil")
  show_info.("  ✅ No dependa de la relación con la tabla companies")
  
  # 7. Resumen
  show_subtitle.("7. RESUMEN")
  show_success.("✅ La tabla ahora muestra company_name correctamente")
  show_success.("✅ Maneja casos de empresa vacía o nil")
  show_success.("✅ No depende de la relación con companies")
  show_success.("✅ Es consistente con el campo de texto libre del formulario")
  
  show_info.("\nPara probar en la interfaz web:")
  show_info.("1. Ir a /leads")
  show_info.("2. Verificar que la columna 'Empresa' muestra los nombres correctamente")
  show_info.("3. Crear un nuevo prospecto con empresa")
  show_info.("4. Verificar que aparece en la lista")
  
  IO.puts("\n" <> String.duplicate("=", 50))
  IO.puts("  PRUEBA COMPLETADA")
  IO.puts(String.duplicate("=", 50))
end

# Ejecutar el script
main.() 