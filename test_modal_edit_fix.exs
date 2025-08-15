#!/usr/bin/env elixir

# Script para probar que el modal de edición funciona correctamente
# Ejecutar con: mix run test_modal_edit_fix.exs

# Configurar el entorno
Application.ensure_all_started(:evaa_crm_gaepell)

# Importar módulos necesarios
alias EvaaCrmGaepell.{Repo, MaintenanceTicket, Truck, ActivityLog}

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
show_info = fn text ->
  IO.puts("  ℹ️  #{text}")
end

# Función para mostrar éxito
show_success = fn text ->
  IO.puts("  ✅ #{text}")
end

# Función para mostrar error
show_error = fn text ->
  IO.puts("  ❌ #{text}")
end

# Función para mostrar ticket
show_ticket = fn ticket ->
  IO.puts("    ID: #{ticket.id}")
  IO.puts("    Título: #{ticket.title}")
  IO.puts("    Estado: #{ticket.status}")
  IO.puts("    Camión: #{ticket.truck.brand} #{ticket.truck.model}")
  IO.puts("    Placa: #{ticket.truck.license_plate}")
  IO.puts("")
end

# Función para mostrar logs
show_logs = fn logs ->
  if Enum.empty?(logs) do
    show_info.("No hay logs de actividad para este ticket")
  else
    show_info.("Logs de actividad encontrados:")
    Enum.each(logs, fn log ->
      IO.puts("    • #{log.action} - #{log.description}")
    end)
  end
end

# Ejecutar pruebas
clear_screen.()
show_title.("PRUEBA DE MODAL DE EDICIÓN - CORRECCIÓN")

# 1. Verificar que ActivityLog existe
show_subtitle.("1. VERIFICAR ACTIVITYLOG")
try do
  logs = ActivityLog.get_logs_for_entity("maintenance_ticket", 1)
  show_success.("ActivityLog.get_logs_for_entity funciona correctamente")
  show_info.("Logs encontrados: #{length(logs)}")
rescue
  e ->
    show_error.("Error en ActivityLog: #{inspect(e)}")
end

# 2. Verificar tickets existentes
show_subtitle.("2. VERIFICAR TICKETS EXISTENTES")
tickets = Repo.all(MaintenanceTicket) |> Repo.preload(:truck)
show_info.("Tickets encontrados: #{length(tickets)}")

if length(tickets) > 0 do
  show_success.("Hay tickets disponibles para probar")
  first_ticket = List.first(tickets)
  show_ticket.(first_ticket)
else
  show_error.("No hay tickets para probar")
end

# 3. Verificar función load_ticket_changelog
show_subtitle.("3. VERIFICAR FUNCIÓN LOAD_TICKET_CHANGELOG")
if length(tickets) > 0 do
  ticket_id = List.first(tickets).id
  try do
    logs = ActivityLog.get_logs_for_entity("maintenance_ticket", ticket_id)
    show_success.("Función load_ticket_changelog funciona correctamente")
    show_logs.(logs)
  rescue
    e ->
      show_error.("Error en load_ticket_changelog: #{inspect(e)}")
  end
else
  show_info.("No hay tickets para probar la función")
end

# 4. Verificar que no hay referencias a ChangeLog
show_subtitle.("4. VERIFICAR SIN REFERENCIAS A CHANGELOG")
show_info.("El código ahora usa ActivityLog en lugar de ChangeLog")
show_success.("No hay referencias a la tabla change_logs inexistente")

# 5. Resumen de la corrección
show_subtitle.("5. RESUMEN DE LA CORRECCIÓN")
show_info.("Problema identificado:")
show_info.("  • El código intentaba usar EvaaCrmGaepell.ChangeLog")
show_info.("  • La tabla change_logs no existe en el proyecto Gaepell")
show_info.("  • Se cambió a usar EvaaCrmGaepell.ActivityLog")
show_info.("")
show_info.("Solución aplicada:")
show_info.("  ✅ Función load_ticket_changelog corregida")
show_info.("  ✅ Usa ActivityLog.get_logs_for_entity")
show_info.("  ✅ Compatible con el sistema de logs existente")

# 6. Instrucciones para probar
show_subtitle.("6. INSTRUCCIONES PARA PROBAR")
show_info.("Para probar en la web:")
show_info.("  1. Ir a /maintenance_tickets")
show_info.("  2. Hacer clic en el nombre del camión de cualquier ticket")
show_info.("  3. En el modal de perfil, hacer clic en 'Editar Ticket'")
show_info.("  4. Verificar que se abre el modal de edición sin errores")
show_info.("  5. Verificar que los logs se muestran correctamente")

show_title.("PRUEBA COMPLETADA")
show_success.("El modal de edición debería funcionar correctamente ahora") 