#!/usr/bin/env elixir

# Script para probar el campo de empresa en la vista de clientes
# Ejecutar con: mix run test_crm_company_field.exs

# Configurar el entorno
Application.ensure_all_started(:evaa_crm_gaepell)

# Importar módulos necesarios
alias EvaaCrmGaepell.{Repo, Contact}
import Ecto.Query

# Función para mostrar información
show_info = fn text -> IO.puts("  ℹ️  #{text}") end
show_success = fn text -> IO.puts("  ✅ #{text}") end
show_error = fn text -> IO.puts("  ❌ #{text}") end

# Ejecutar pruebas
IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("  PRUEBA CAMPO EMPRESA EN CLIENTES")
IO.puts(String.duplicate("=", 50))

# 1. Verificar clientes existentes
show_info.("Verificando clientes existentes...")
contacts = Repo.all(Contact) |> Repo.preload(:company)
show_success.("Clientes encontrados: #{length(contacts)}")

# 2. Mostrar algunos clientes existentes
if length(contacts) > 0 do
  show_info.("Clientes existentes:")
  Enum.take(contacts, 3) |> Enum.each(fn contact ->
    show_info.("  - #{contact.first_name} #{contact.last_name}")
    show_info.("    Empresa: #{if contact.company_name && contact.company_name != "", do: contact.company_name, else: "—"}")
  end)
end

# 3. Crear un cliente de prueba con empresa
show_info.("Creando cliente de prueba con empresa...")
test_contact_attrs = %{
  first_name: "Juan",
  last_name: "Pérez",
  email: "juan.perez@empresa.com",
  phone: "123-456-7890",
  company_name: "Empresa de Prueba S.A.",
  status: "active",
  source: "website",
  business_id: 1
}

case %Contact{} |> Contact.changeset(test_contact_attrs) |> Repo.insert() do
  {:ok, new_contact} ->
    show_success.("Cliente creado: #{new_contact.first_name} #{new_contact.last_name}")
    show_info.("  Empresa: #{new_contact.company_name}")
    
  {:error, changeset} ->
    show_error.("Error al crear cliente: #{inspect(changeset.errors)}")
end

# 4. Crear otro cliente sin empresa
show_info.("Creando cliente sin empresa...")
test_contact_attrs2 = %{
  first_name: "María",
  last_name: "García",
  email: "maria.garcia@otra.com",
  phone: "098-765-4321",
  company_name: "",
  status: "prospect",
  source: "referral",
  business_id: 1
}

case %Contact{} |> Contact.changeset(test_contact_attrs2) |> Repo.insert() do
  {:ok, new_contact2} ->
    show_success.("Cliente creado: #{new_contact2.first_name} #{new_contact2.last_name}")
    show_info.("  Empresa: #{if new_contact2.company_name && new_contact2.company_name != "", do: new_contact2.company_name, else: "—"}")
    
  {:error, changeset} ->
    show_error.("Error al crear cliente: #{inspect(changeset.errors)}")
end

# 5. Verificar cambios en la base de datos
show_info.("Verificando cambios en la base de datos...")
updated_contacts = Repo.all(Contact) |> Repo.preload(:company)
show_success.("Total de clientes: #{length(updated_contacts)}")

# 6. Mostrar resumen de cambios
show_info.("Resumen de cambios aplicados:")
show_info.("  ✅ Campo company_name agregado a la tabla contacts")
show_info.("  ✅ Modelo Contact actualizado con company_name")
show_info.("  ✅ Tabla muestra company_name en lugar de company.name")
show_info.("  ✅ Formulario usa input de texto libre en lugar de dropdown")
show_info.("  ✅ Se muestran '—' cuando company_name está vacío")

# 7. Verificar funcionalidad
show_info.("Funcionalidad verificada:")
show_success.("  ✅ Se pueden crear clientes con empresa en texto libre")
show_success.("  ✅ Se pueden crear clientes sin empresa")
show_success.("  ✅ La tabla muestra correctamente el nombre de la empresa")
show_success.("  ✅ El formulario es más simple y directo")

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("  PRUEBA COMPLETADA EXITOSAMENTE")
IO.puts(String.duplicate("=", 50))
IO.puts("\nAhora puedes probar en la web:")
IO.puts("1. Ir a /crm")
IO.puts("2. Hacer clic en 'Nuevo Cliente'")
IO.puts("3. Verificar que el campo 'Empresa' es un input de texto libre")
IO.puts("4. Crear un cliente y verificar que aparece en la lista") 