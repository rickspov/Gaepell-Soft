# 🔧 Solución: DATABASE_URL is missing

## ❌ Error

```
** (RuntimeError) environment variable DATABASE_URL is missing.
```

## ✅ Solución Rápida

### Opción 1: Conectar Servicios (Recomendado)

1. **Ve a tu servicio de aplicación web** (Gaepell-Soft)
2. **Ve a "Settings"** → **"Connect"** o **"Variables"**
3. **Busca "Connected Services"** o **"Service Connections"**
4. **Haz clic en "Connect"** junto al servicio PostgreSQL
5. Railway automáticamente expondrá `DATABASE_URL` a tu aplicación

### Opción 2: Configurar Manualmente

Si la opción 1 no funciona:

1. **Ve a tu servicio PostgreSQL**
2. **Ve a "Variables"**
3. **Busca `DATABASE_URL`** (debe estar resuelta, sin `${{...}}`)
4. **Copia el valor completo** (debe verse así):
   ```
   postgresql://postgres:PASSWORD@postgres.railway.internal:5432/railway
   ```

5. **Ve a tu servicio de aplicación web** (Gaepell-Soft)
6. **Ve a "Variables"**
7. **Haz clic en "New Variable"**
8. **Agrega:**
   - **Nombre:** `DATABASE_URL`
   - **Valor:** Pega la URL que copiaste del servicio PostgreSQL
   - **Marca como "Secret"** (opcional pero recomendado)

9. **Guarda y reinicia** el servicio web

## 🔍 Verificar que Funciona

Después de configurar `DATABASE_URL`:

1. **Reinicia tu servicio web**
2. **Revisa los logs** - deberías ver:
   - ✅ "Running migrations..."
   - ✅ "Database migrations completed"
   - ✅ "Server running on port..."

3. **El healthcheck debería pasar**

## 📝 Formato Correcto de DATABASE_URL

La URL debe verse así (resuelta):

```
postgresql://postgres:shtGCfBnOoZoSXUAVERCXRMdUGtyHCSD@postgres.railway.internal:5432/railway
```

**NO debe tener:**
- ❌ `${{PGUSER}}`
- ❌ `${{POSTGRES_PASSWORD}}`
- ❌ `${{RAILWAY_PRIVATE_DOMAIN}}`
- ❌ Cualquier template `${{...}}`

**Debe tener:**
- ✅ `postgresql://` al inicio
- ✅ Usuario: `postgres`
- ✅ Contraseña: La contraseña real (no template)
- ✅ Host: `postgres.railway.internal` o similar
- ✅ Puerto: `5432`
- ✅ Base de datos: `railway`

## 🚨 Si Sigue Fallando

1. **Verifica que PostgreSQL esté corriendo:**
   - Ve al servicio PostgreSQL
   - Revisa los logs - debe decir "ready to accept connections"

2. **Verifica el formato de la URL:**
   - Debe empezar con `postgresql://`
   - No debe tener espacios
   - Debe estar completa

3. **Prueba la conexión manualmente:**
   - Ve a la terminal de Railway (en tu servicio web)
   - Ejecuta: `echo $DATABASE_URL`
   - Debe mostrar la URL completa

---

**Una vez configurada `DATABASE_URL`, la aplicación debería iniciar correctamente** ✅

