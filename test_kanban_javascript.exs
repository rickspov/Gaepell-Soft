#!/usr/bin/env elixir

# Script para verificar que el JavaScript del Kanban funciona
# Ejecutar con: mix run test_kanban_javascript.exs

IO.puts("=== VERIFICACIÓN DE JAVASCRIPT DEL KANBAN ===")
IO.puts("")

IO.puts("PASO 1: Verificar que el servidor esté corriendo")
IO.puts("  - El servidor debe estar en http://localhost:4001")
IO.puts("  - Si no está corriendo, ejecuta: mix phx.server")
IO.puts("")

IO.puts("PASO 2: Verificar en el navegador")
IO.puts("  1. Abre http://localhost:4001")
IO.puts("  2. Ve al Kanban")
IO.puts("  3. Abre las herramientas de desarrollador (F12)")
IO.puts("  4. Ve a la pestaña Console")
IO.puts("  5. Busca estos logs:")
IO.puts("     - 'KanbanDragDrop hook mounted'")
IO.puts("     - 'Found columns with data-kanban-column: X'")
IO.puts("     - 'Creating sortable for column X'")
IO.puts("")

IO.puts("PASO 3: Si no aparecen los logs, verificar:")
IO.puts("  1. Que el archivo app.js se esté cargando")
IO.puts("  2. Que Sortable.js esté disponible")
IO.puts("  3. Que no haya errores de JavaScript")
IO.puts("")

IO.puts("PASO 4: Verificar la estructura del HTML")
IO.puts("  En el inspector del navegador, busca:")
IO.puts("  - Elementos con data-kanban-column")
IO.puts("  - Contenedores con clase .kanban-col-cards")
IO.puts("  - Cards con data-id")
IO.puts("")

IO.puts("PASO 5: Si todo está bien, probar drag and drop")
IO.puts("  1. Intenta arrastrar un lead de una columna a otra")
IO.puts("  2. Busca estos logs en la consola:")
IO.puts("     - 'Drag started'")
IO.puts("     - 'Sortable onEnd'")
IO.puts("     - 'Status changed, sending kanban:move event'")
IO.puts("")

IO.puts("PASO 6: Verificar en el servidor")
IO.puts("  En la consola del servidor, busca:")
IO.puts("  - '[DEBUG] kanban:move event received'")
IO.puts("  - '[DEBUG] id: l-X'")
IO.puts("  - '[DEBUG] new_status: X'")
IO.puts("")

IO.puts("=== POSIBLES PROBLEMAS Y SOLUCIONES ===")
IO.puts("")

IO.puts("PROBLEMA 1: No aparecen logs de 'KanbanDragDrop hook mounted'")
IO.puts("SOLUCIÓN: El hook no se está aplicando al elemento")
IO.puts("  - Verificar que el elemento tenga phx-hook='KanbanDragDrop'")
IO.puts("  - Verificar que no haya errores de JavaScript")
IO.puts("")

IO.puts("PROBLEMA 2: Aparece 'Found columns with data-kanban-column: 0'")
IO.puts("SOLUCIÓN: No se encuentran las columnas del Kanban")
IO.puts("  - Verificar que el HTML tenga data-kanban-column")
IO.puts("  - Verificar que el hook se aplique al elemento correcto")
IO.puts("")

IO.puts("PROBLEMA 3: Aparece 'No .kanban-col-cards found in column'")
IO.puts("SOLUCIÓN: La estructura del HTML no es correcta")
IO.puts("  - Verificar que las columnas tengan .kanban-col-cards")
IO.puts("")

IO.puts("PROBLEMA 4: No aparecen logs de 'Drag started'")
IO.puts("SOLUCIÓN: Sortable.js no se está inicializando")
IO.puts("  - Verificar que Sortable esté disponible")
IO.puts("  - Verificar que no haya errores de JavaScript")
IO.puts("")

IO.puts("PROBLEMA 5: No aparecen logs de 'Sortable onEnd'")
IO.puts("SOLUCIÓN: El evento onEnd no se está disparando")
IO.puts("  - Verificar que el drag and drop funcione visualmente")
IO.puts("  - Verificar que no haya errores en la consola")
IO.puts("")

IO.puts("PROBLEMA 6: No aparecen logs del servidor")
IO.puts("SOLUCIÓN: El evento no llega al servidor")
IO.puts("  - Verificar que el evento se esté enviando")
IO.puts("  - Verificar que no haya errores de red")
IO.puts("")

IO.puts("=== VERIFICACIÓN COMPLETADA ===") 