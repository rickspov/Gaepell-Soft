# Script para generar SECRET_KEY_BASE
# Ejecutar con: mix run scripts/generate_secret.exs

IO.puts("🔑 Generando SECRET_KEY_BASE...")
secret = Base.encode64(:crypto.strong_rand_bytes(64))
IO.puts("")
IO.puts("SECRET_KEY_BASE=#{secret}")
IO.puts("")
IO.puts("📋 Copia esta línea y configúrala en Railway como variable de entorno")
