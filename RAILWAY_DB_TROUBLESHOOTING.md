# 🔧 Solución de Problemas de Base de Datos en Railway

## ❌ Error: "DBConnection.ConnectionError" o "timeout"

Este error indica que la aplicación no puede conectarse a PostgreSQL.

## ✅ Solución Paso a Paso

### 1. Verificar que PostgreSQL esté Agregado

En Railway Dashboard:

1. **Ve a tu proyecto**
2. **Verifica que veas DOS servicios:**
   - Tu aplicación (web service)
   - PostgreSQL (database service)

Si **NO** ves PostgreSQL:

1. Haz clic en **"+ New"**
2. Selecciona **"Database"** → **"Add PostgreSQL"**
3. Railway creará automáticamente una base de datos PostgreSQL

### 2. Conectar PostgreSQL con tu Aplicación

1. **Haz clic en el servicio PostgreSQL**
2. Ve a la pestaña **"Variables"**
3. **Copia el valor de `DATABASE_URL`** (debería verse algo como: `postgresql://postgres:password@host:port/railway`)

4. **Ve a tu servicio de aplicación web**
5. Ve a **"Variables"**
6. **Verifica que `DATABASE_URL` esté presente**

**O mejor aún, usa la función de Railway:**

1. En tu servicio de aplicación web
2. Ve a **"Settings"** → **"Connect"**
3. **Selecciona el servicio PostgreSQL**
4. Railway conectará automáticamente los servicios y configurará `DATABASE_URL`

### 3. Verificar Variables de Entorno

Asegúrate de tener estas variables en tu servicio web:

```bash
DATABASE_URL=<debe estar configurada automáticamente>
PHX_SERVER=true
SECRET_KEY_BASE=<tu-secret-key>
POOL_SIZE=10
MIX_ENV=prod
```

### 4. Verificar que PostgreSQL esté Corriendo

1. **Ve al servicio PostgreSQL**
2. **Revisa los logs** - deberías ver mensajes como:
   - "PostgreSQL is ready to accept connections"
   - "database system is ready to accept connections"

Si ves errores, el servicio puede estar iniciando. Espera 1-2 minutos.

### 5. Probar la Conexión Manualmente

Si todo lo anterior está bien pero sigue fallando:

1. **Ve al servicio PostgreSQL**
2. **Abre la terminal** (pestaña "Terminal" o "Shell")
3. **Ejecuta:**
   ```bash
   psql $DATABASE_URL
   ```
4. Si puedes conectarte, la BD está bien
5. Si no, hay un problema con PostgreSQL

### 6. Verificar el Formato de DATABASE_URL

Railway usa este formato:
```
postgresql://postgres:PASSWORD@HOST:PORT/railway
```

Pero Ecto espera:
```
postgresql://postgres:PASSWORD@HOST:PORT/railway
```

O a veces:
```
ecto://postgres:PASSWORD@HOST:PORT/railway
```

**Solución:** Railway debería configurarlo automáticamente, pero si hay problemas:

1. Copia `DATABASE_URL` del servicio PostgreSQL
2. Si empieza con `postgresql://`, está bien
3. Si empieza con `postgres://`, también está bien (Ecto lo acepta)

### 7. Ajustar Configuración del Pool

Si ves errores de "pool timeout", ajusta estas variables:

```bash
POOL_SIZE=5  # Reducir si hay problemas
```

O agrega estas variables (ya están en runtime.exs pero puedes ajustarlas):

```bash
DB_TIMEOUT=15000
DB_CONNECT_TIMEOUT=10000
```

### 8. Reiniciar los Servicios

A veces un reinicio ayuda:

1. **Ve a tu servicio de aplicación**
2. **Haz clic en los tres puntos (...)**
3. **Selecciona "Restart"**
4. **Espera a que reinicie**

## 🔍 Verificar en los Logs

Busca estos mensajes en los logs de tu aplicación:

### ✅ Mensajes Buenos:
- "Database migrations completed"
- "Running migrations..."
- "Server running on port..."

### ❌ Mensajes Malos:
- "DBConnection.ConnectionError"
- "timeout"
- "connection refused"
- "DATABASE_URL is missing"

## 📝 Checklist Rápido

- [ ] PostgreSQL está agregado como servicio
- [ ] PostgreSQL está conectado a tu aplicación (Settings → Connect)
- [ ] `DATABASE_URL` está en las variables de tu aplicación
- [ ] PostgreSQL está corriendo (revisa logs)
- [ ] Variables de entorno están configuradas
- [ ] Servicios están reiniciados

## 🚨 Si Nada Funciona

1. **Elimina el servicio PostgreSQL**
2. **Crea uno nuevo**
3. **Conéctalo a tu aplicación**
4. **Reinicia tu aplicación**

O contacta al soporte de Railway con:
- Screenshot de los logs
- Screenshot de las variables de entorno
- URL de tu proyecto

---

**Después de seguir estos pasos, tu aplicación debería conectarse correctamente a PostgreSQL** ✅

