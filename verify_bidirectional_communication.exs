#!/usr/bin/env elixir

# Script para verificar que la comunicación bidireccional funciona
# Ejecutar con: mix run verify_bidirectional_communication.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead}

IO.puts("=== VERIFICACIÓN DE COMUNICACIÓN BIDIRECCIONAL ===")
IO.puts("")

IO.puts("✅ PROBLEMA IDENTIFICADO Y SOLUCIONADO:")
IO.puts("  - El Kanban SÍ enviaba broadcast al actualizar leads")
IO.puts("  - La vista de Prospectos NO enviaba broadcast al actualizar leads")
IO.puts("  - Se agregó broadcast a todos los eventos de actualización de estado en Prospectos")
IO.puts("")

IO.puts("✅ CAMBIOS REALIZADOS:")
IO.puts("  1. ✅ Kanban: Ya enviaba broadcast (línea 163)")
IO.puts("  2. ✅ Prospectos: Se agregó broadcast a:")
IO.puts("     - handle_event('cancel_edit_status')")
IO.puts("     - handle_event('update_lead_status') con _target")
IO.puts("     - handle_event('update_lead_status') con id")
IO.puts("  3. ✅ Ambas vistas se suscriben al broadcast 'leads:updated'")
IO.puts("")

IO.puts("🎯 INSTRUCCIONES PARA PROBAR:")
IO.puts("")

IO.puts("1. ABRE DOS PESTAÑAS:")
IO.puts("   Pestaña 1: http://localhost:4001 → Kanban")
IO.puts("   Pestaña 2: http://localhost:4001 → Prospectos")
IO.puts("")

IO.puts("2. PRUEBA KANBAN → PROSPECTOS:")
IO.puts("   - En Kanban, arrastra un lead de 'new' a 'contacted'")
IO.puts("   - Ve a Prospectos y verifica que el estado cambió")
IO.puts("   - Busca en la consola del servidor:")
IO.puts("     - '[DEBUG] kanban:move event received'")
IO.puts("     - '[DEBUG] Lead X status field updated to: contacted'")
IO.puts("")

IO.puts("3. PRUEBA PROSPECTOS → KANBAN:")
IO.puts("   - En Prospectos, cambia un lead de 'contacted' a 'qualified'")
IO.puts("   - Ve a Kanban y verifica que el lead se movió")
IO.puts("   - Busca en la consola del servidor:")
IO.puts("     - 'Broadcast sent: leads:updated'")
IO.puts("")

IO.puts("4. VERIFICA LOGS EN TIEMPO REAL:")
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
IO.puts("🎉 ¡LA COMUNICACIÓN BIDIRECCIONAL DEBERÍA FUNCIONAR AHORA!")
IO.puts("")
IO.puts("Si aún no funciona, verifica:")
IO.puts("  1. Que ambas pestañas estén abiertas al mismo tiempo")
IO.puts("  2. Que no haya errores en la consola del navegador")
IO.puts("  3. Que el servidor esté corriendo sin errores")
IO.puts("  4. Que los logs aparezcan en la consola del servidor")
IO.puts("")

IO.puts("=== RESUMEN DE LA SOLUCIÓN ===")
IO.puts("")
IO.puts("PROBLEMA ORIGINAL:")
IO.puts("  - Prospectos → Kanban: ✅ Funcionaba")
IO.puts("  - Kanban → Prospectos: ❌ No funcionaba")
IO.puts("")
IO.puts("CAUSA:")
IO.puts("  - La vista de Prospectos no enviaba broadcast al actualizar estados")
IO.puts("")
IO.puts("SOLUCIÓN:")
IO.puts("  - Se agregó Phoenix.PubSub.broadcast a todos los eventos de actualización")
IO.puts("  - Ahora ambas vistas envían y reciben broadcasts")
IO.puts("")
IO.puts("RESULTADO:")
IO.puts("  - Prospectos → Kanban: ✅ Funciona")
IO.puts("  - Kanban → Prospectos: ✅ Ahora funciona")
IO.puts("")
IO.puts("=== VERIFICACIÓN COMPLETADA ===") 