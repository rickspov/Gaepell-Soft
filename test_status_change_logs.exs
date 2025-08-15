#!/usr/bin/env elixir

# Script de prueba para verificar que los logs se registran al cambiar estado
# Ejecutar con: mix run test_status_change_logs.exs

# Configurar la aplicación
Application.ensure_all_started(:evaa_crm_gaepell)

import Ecto.Query
alias EvaaCrmGaepell.{Repo, ActivityLog, MaintenanceTicket, User, Business, Fleet}

IO.puts("🧪 Probando logs de cambio de estado...")

# Obtener un usuario y business para las pruebas
user = Repo.one(from u in User, limit: 1)
business = Repo.one(from b in Business, limit: 1)

if user && business do
  IO.puts("✅ Usuario encontrado: #{user.email}")
  IO.puts("✅ Business encontrado: #{business.name}")
  
  # Crear un ticket de prueba
  IO.puts("\n📝 Creando ticket de prueba...")
  ticket_attrs = %{
    "title" => "Ticket de prueba para logs",
    "truck_id" => 1,
    "business_id" => business.id,
    "status" => "check_in",
    "user_id" => user.id
  }
  
  case Fleet.create_maintenance_ticket(ticket_attrs) do
    {:ok, ticket} ->
      IO.puts("✅ Ticket creado: #{ticket.title} (ID: #{ticket.id})")
      
      # Cambiar el estado del ticket
      IO.puts("\n🔄 Cambiando estado de 'check_in' a 'in_workshop'...")
      case Fleet.update_maintenance_ticket(ticket, %{"status" => "in_workshop"}, user.id) do
        {:ok, updated_ticket} ->
          IO.puts("✅ Estado cambiado exitosamente a: #{updated_ticket.status}")
          
          # Verificar que se creó el log
          IO.puts("\n📋 Verificando logs...")
          logs = ActivityLog.get_logs_for_entity("maintenance_ticket", ticket.id)
          IO.puts("✅ Encontrados #{length(logs)} logs para el ticket")
          
          Enum.each(logs, fn log ->
            IO.puts("  - #{log.description} (#{log.action}) - #{log.inserted_at}")
            if log.action == "status_changed" do
              IO.puts("    Estado anterior: #{log.old_values["status"]}")
              IO.puts("    Estado nuevo: #{log.new_values["status"]}")
            end
          end)
          
        {:error, reason} ->
          IO.puts("❌ Error cambiando estado: #{inspect(reason)}")
      end
      
    {:error, reason} ->
      IO.puts("❌ Error creando ticket: #{inspect(reason)}")
  end
  
else
  IO.puts("❌ No se encontraron usuarios o businesses para las pruebas")
  IO.puts("Asegúrate de tener datos en la base de datos")
end

IO.puts("\n🎉 Pruebas completadas!") 