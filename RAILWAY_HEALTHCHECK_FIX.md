# 🔧 Solución de Problemas de Healthcheck en Railway

## ❌ Error: "service unavailable" en Healthcheck

Si ves este error, significa que la aplicación no está respondiendo en `/health`.

## 🔍 Diagnóstico

### 1. Verificar Logs de la Aplicación

**En Railway Dashboard:**

1. Ve a tu servicio de aplicación web
2. Ve a la pestaña **"Deployments"**
3. Haz clic en el deployment más reciente
4. Revisa los **logs completos**

**Busca estos mensajes:**

✅ **Mensajes Buenos:**
- "Running migrations..."
- "Database migrations completed"
- "Server running on port..."
- "Application started"

❌ **Mensajes Malos:**
- "DBConnection.ConnectionError"
- "DATABASE_URL is missing"
- "SECRET_KEY_BASE is missing"
- "Application failed to start"
- Cualquier error de Erlang/Elixir

### 2. Verificar Variables de Entorno

Asegúrate de tener estas variables configuradas:

```bash
✅ SECRET_KEY_BASE=<tu-secret-key>
✅ PHX_SERVER=true
✅ DATABASE_URL=<url-de-postgresql>
✅ POOL_SIZE=10
✅ MIX_ENV=prod
```

### 3. Verificar que PostgreSQL esté Conectado

1. Ve a tu servicio PostgreSQL
2. Verifica que esté corriendo (logs muestran "ready to accept connections")
3. Ve a tu servicio web → Settings → Connect
4. Verifica que PostgreSQL esté conectado

## 🚨 Problemas Comunes y Soluciones

### Problema 1: Migraciones Fallan

**Síntoma:** Logs muestran errores de migraciones

**Solución:**
1. Verifica que `DATABASE_URL` esté configurada
2. Verifica que PostgreSQL esté corriendo
3. Intenta ejecutar migraciones manualmente desde la terminal de Railway

### Problema 2: Aplicación No Inicia

**Síntoma:** No hay mensaje "Server running"

**Solución:**
1. Revisa los logs completos
2. Verifica que todas las variables de entorno estén configuradas
3. Verifica que no haya errores de compilación

### Problema 3: Error de Conexión a Base de Datos

**Síntoma:** "DBConnection.ConnectionError" o "timeout"

**Solución:**
1. Verifica que PostgreSQL esté conectado a tu aplicación
2. Verifica que `DATABASE_URL` esté resuelta (sin `${{...}}`)
3. Revisa [RAILWAY_DB_TROUBLESHOOTING.md](./RAILWAY_DB_TROUBLESHOOTING.md)

### Problema 4: Healthcheck Falla pero la App Funciona

**Síntoma:** Puedes acceder a la URL pero healthcheck falla

**Solución:**
1. Verifica que el endpoint `/health` esté accesible
2. Prueba manualmente: `https://tu-app.railway.app/health`
3. Debería devolver: `{"status":"ok","service":"evaa_crm"}`

## 🔧 Soluciones Rápidas

### Opción 1: Reiniciar el Servicio

1. Ve a tu servicio web
2. Haz clic en los tres puntos (...)
3. Selecciona **"Restart"**
4. Espera a que reinicie

### Opción 2: Verificar Variables Manualmente

1. Ve a Variables
2. Verifica cada una:
   - `SECRET_KEY_BASE` ✅
   - `PHX_SERVER=true` ✅
   - `DATABASE_URL` ✅
   - `POOL_SIZE=10` ✅
   - `MIX_ENV=prod` ✅

### Opción 3: Ejecutar Migraciones Manualmente

Si las migraciones fallan:

1. Ve a la terminal de Railway (en tu servicio web)
2. Ejecuta:
   ```bash
   mix ecto.migrate
   ```
3. Revisa los errores si los hay

### Opción 4: Deshabilitar SSL Temporalmente

Si hay problemas de SSL con la base de datos:

1. En `config/runtime.exs`, cambia temporalmente:
   ```elixir
   ssl: false,  # Cambiar a false temporalmente
   ```
2. Haz commit y push
3. Prueba de nuevo

## 📝 Checklist de Verificación

- [ ] Build completó exitosamente
- [ ] Todas las variables de entorno están configuradas
- [ ] PostgreSQL está corriendo
- [ ] PostgreSQL está conectado a la aplicación
- [ ] Logs muestran "Server running on port..."
- [ ] Puedes acceder a `/health` manualmente
- [ ] No hay errores críticos en los logs

## 🆘 Si Nada Funciona

1. **Revisa los logs completos** - busca cualquier error
2. **Verifica las variables de entorno** - todas deben estar configuradas
3. **Prueba la conexión a la BD** - desde la terminal de Railway
4. **Contacta soporte de Railway** - con los logs y screenshots

---

**El healthcheck debería pasar una vez que la aplicación inicie correctamente** ✅

