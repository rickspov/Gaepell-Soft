#!/usr/bin/env elixir

# Script de prueba para el sistema de logs de actividad
# Ejecutar con: mix run test_activity_logs.exs

# Configurar la aplicación
Application.ensure_all_started(:evaa_crm_gaepell)

import Ecto.Query
alias EvaaCrmGaepell.{Repo, ActivityLog, MaintenanceTicket, User, Business}

IO.puts("🧪 Probando sistema de logs de actividad...")

# Obtener un usuario y business para las pruebas
user = Repo.one(from u in User, limit: 1)
business = Repo.one(from b in Business, limit: 1)

if user && business do
  IO.puts("✅ Usuario encontrado: #{user.email}")
  IO.puts("✅ Business encontrado: #{business.name}")
  
  # Probar creación de log
  IO.puts("\n📝 Probando creación de log...")
  case ActivityLog.log_creation("maintenance_ticket", 1, "Ticket de prueba", user.id, business.id) do
    {:ok, log} ->
      IO.puts("✅ Log creado exitosamente: #{log.description}")
    {:error, changeset} ->
      IO.puts("❌ Error creando log: #{inspect(changeset.errors)}")
  end
  
  # Probar cambio de estado
  IO.puts("\n🔄 Probando cambio de estado...")
  case ActivityLog.log_status_change("maintenance_ticket", 1, "check_in", "in_workshop", user.id, business.id) do
    {:ok, log} ->
      IO.puts("✅ Log de cambio de estado creado: #{log.description}")
    {:error, changeset} ->
      IO.puts("❌ Error creando log de cambio: #{inspect(changeset.errors)}")
  end
  
  # Probar comentario
  IO.puts("\n💬 Probando comentario...")
  case ActivityLog.log_comment("maintenance_ticket", 1, "Este es un comentario de prueba", user.id, business.id) do
    {:ok, log} ->
      IO.puts("✅ Log de comentario creado: #{log.description}")
    {:error, changeset} ->
      IO.puts("❌ Error creando log de comentario: #{inspect(changeset.errors)}")
  end
  
  # Obtener logs para la entidad
  IO.puts("\n📋 Obteniendo logs para maintenance_ticket #1...")
  logs = ActivityLog.get_logs_for_entity("maintenance_ticket", 1)
  IO.puts("✅ Encontrados #{length(logs)} logs")
  
  Enum.each(logs, fn log ->
    IO.puts("  - #{log.description} (#{log.action}) - #{log.inserted_at}")
  end)
  
else
  IO.puts("❌ No se encontraron usuarios o businesses para las pruebas")
  IO.puts("Asegúrate de tener datos en la base de datos")
end

IO.puts("\n🎉 Pruebas completadas!") 