#!/usr/bin/env elixir

# Script para probar la comunicación bidireccional via broadcast
# Ejecutar con: mix run test_broadcast_bidirectional.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead}

IO.puts("=== PRUEBA DE COMUNICACIÓN BIDIRECCIONAL ===")
IO.puts("")

IO.puts("PASO 1: Verificar que el servidor esté corriendo")
IO.puts("  - El servidor debe estar en http://localhost:4001")
IO.puts("  - Si no está corriendo, ejecuta: mix phx.server")
IO.puts("")

IO.puts("PASO 2: Verificar que ambas vistas estén abiertas")
IO.puts("  1. Abre http://localhost:4001 en una pestaña")
IO.puts("  2. Ve al Kanban (vista integrada)")
IO.puts("  3. Abre otra pestaña con http://localhost:4001")
IO.puts("  4. Ve a Prospectos")
IO.puts("")

IO.puts("PASO 3: Probar comunicación Kanban → Prospectos")
IO.puts("  1. En el Kanban, arrastra un lead de una columna a otra")
IO.puts("  2. Verifica en la consola del servidor que aparezca:")
IO.puts("     - '[DEBUG] kanban:move event received'")
IO.puts("     - '[DEBUG] Lead X status field updated to: X'")
IO.puts("  3. Ve a la pestaña de Prospectos")
IO.puts("  4. Verifica que el estado del lead se haya actualizado")
IO.puts("")

IO.puts("PASO 4: Probar comunicación Prospectos → Kanban")
IO.puts("  1. En Prospectos, cambia el estado de un lead via chips")
IO.puts("  2. Ve a la pestaña del Kanban")
IO.puts("  3. Verifica que el lead se haya movido a la columna correcta")
IO.puts("")

IO.puts("PASO 5: Verificar logs en tiempo real")
IO.puts("  En la consola del servidor, busca estos logs:")
IO.puts("  - '[DEBUG] kanban:move event received' (desde Kanban)")
IO.puts("  - '[DEBUG] Lead X status field updated to: X' (desde Kanban)")
IO.puts("  - 'Broadcast sent: leads:updated' (desde Prospectos)")
IO.puts("")

IO.puts("📊 DATOS ACTUALES PARA PRUEBA:")
leads = Repo.all(Lead)
IO.puts("  - Leads disponibles: #{length(leads)}")
Enum.each(leads, fn lead ->
  IO.puts("    - Lead #{lead.id}: #{lead.name} | Estado: #{lead.status} | Empresa: #{lead.business_id}")
end)

IO.puts("")
IO.puts("🎯 INSTRUCCIONES DETALLADAS:")
IO.puts("")

IO.puts("1. ABRE DOS PESTAÑAS:")
IO.puts("   Pestaña 1: http://localhost:4001 → Kanban")
IO.puts("   Pestaña 2: http://localhost:4001 → Prospectos")
IO.puts("")

IO.puts("2. PRUEBA KANBAN → PROSPECTOS:")
IO.puts("   - En Kanban, arrastra un lead de 'new' a 'contacted'")
IO.puts("   - Ve a Prospectos y verifica que el estado cambió")
IO.puts("")

IO.puts("3. PRUEBA PROSPECTOS → KANBAN:")
IO.puts("   - En Prospectos, cambia un lead de 'contacted' a 'qualified'")
IO.puts("   - Ve a Kanban y verifica que el lead se movió")
IO.puts("")

IO.puts("4. SI NO FUNCIONA, VERIFICA:")
IO.puts("   - Que ambas pestañas estén abiertas al mismo tiempo")
IO.puts("   - Que no haya errores en la consola del navegador")
IO.puts("   - Que el servidor esté corriendo sin errores")
IO.puts("   - Que los logs aparezcan en la consola del servidor")
IO.puts("")

IO.puts("=== POSIBLES PROBLEMAS ===")
IO.puts("")

IO.puts("PROBLEMA 1: No se actualiza Prospectos desde Kanban")
IO.puts("CAUSA: La vista de Prospectos no está suscrita al broadcast")
IO.puts("SOLUCIÓN: Verificar que la línea 8 en leads_live.ex esté presente")
IO.puts("")

IO.puts("PROBLEMA 2: No se actualiza Kanban desde Prospectos")
IO.puts("CAUSA: El broadcast no se está enviando desde Prospectos")
IO.puts("SOLUCIÓN: Verificar que se envíe el broadcast al cambiar estado")
IO.puts("")

IO.puts("PROBLEMA 3: No funciona en ninguna dirección")
IO.puts("CAUSA: El servidor no está corriendo o hay errores")
IO.puts("SOLUCIÓN: Reiniciar el servidor y verificar logs")
IO.puts("")

IO.puts("=== VERIFICACIÓN COMPLETADA ===") 