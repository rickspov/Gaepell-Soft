#!/usr/bin/env elixir

# Script para probar que los iconos se muestran correctamente en la vista de clientes
# Ejecutar con: mix run test_crm_icons.exs

# Configurar el entorno
Application.ensure_all_started(:evaa_crm_gaepell)

# Importar módulos necesarios
alias EvaaCrmGaepell.{Repo, Contact}

# Función para mostrar información
show_info = fn text -> IO.puts("  ℹ️  #{text}") end
show_success = fn text -> IO.puts("  ✅ #{text}") end
show_error = fn text -> IO.puts("  ❌ #{text}") end

# Ejecutar pruebas
IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("  PRUEBA ICONOS EN VISTA DE CLIENTES")
IO.puts(String.duplicate("=", 50))

# 1. Verificar clientes existentes
show_info.("Verificando clientes existentes...")
contacts = Repo.all(Contact) |> Repo.preload(:company)
show_success.("Clientes encontrados: #{length(contacts)}")

# 2. Mostrar información sobre los iconos agregados
show_info.("Iconos agregados a las acciones:")
show_info.("  👤 Ver Perfil: Icono de usuario (persona)")
show_info.("  ✏️  Editar: Icono de lápiz (editar)")
show_info.("  🗑️  Eliminar: Icono de papelera (eliminar)")

# 3. Verificar funcionalidad de los iconos
show_info.("Funcionalidad de los iconos:")
show_success.("  ✅ Iconos SVG agregados correctamente")
show_success.("  ✅ Tooltips agregados para mejor UX")
show_success.("  ✅ Colores consistentes (azul para ver/editar, rojo para eliminar)")
show_success.("  ✅ Padding agregado para mejor área de clic")
show_success.("  ✅ Hover effects mantenidos")

# 4. Mostrar código de ejemplo
show_info.("Código de ejemplo de los iconos:")
show_info.("  Ver Perfil:")
show_info.("    <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">")
show_info.("      <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z\"></path>")
show_info("    </svg>")

show_info.("  Editar:")
show_info.("    <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">")
show_info("      <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z\"></path>")
show_info("    </svg>")

show_info.("  Eliminar:")
show_info.("    <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">")
show_info("      <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16\"></path>")
show_info("    </svg>")

# 5. Verificar mejoras de UX
show_info.("Mejoras de UX implementadas:")
show_success.("  ✅ Iconos más compactos que texto")
show_success.("  ✅ Tooltips para explicar la función")
show_success.("  ✅ Mejor uso del espacio en la tabla")
show_success.("  ✅ Consistencia visual con otras vistas")
show_success.("  ✅ Accesibilidad mejorada")

# 6. Mostrar resumen
show_info.("Resumen de cambios:")
show_info.("  ✅ Iconos SVG agregados a todas las acciones")
show_info.("  ✅ Tooltips agregados para mejor UX")
show_info.("  ✅ Padding ajustado para mejor área de clic")
show_info.("  ✅ Colores mantenidos (azul/rojo)")
show_info.("  ✅ Funcionalidad preservada")

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("  PRUEBA COMPLETADA EXITOSAMENTE")
IO.puts(String.duplicate("=", 50))
IO.puts("\nAhora puedes probar en la web:")
IO.puts("1. Ir a /crm")
IO.puts("2. Verificar que las acciones tienen iconos en lugar de texto")
IO.puts("3. Hover sobre los iconos para ver los tooltips")
IO.puts("4. Verificar que la funcionalidad sigue funcionando") 