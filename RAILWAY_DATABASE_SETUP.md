# 🔗 Configuración de Base de Datos en Railway

## 📋 Variables de PostgreSQL en Railway

Railway crea estas variables en el servicio PostgreSQL:

```
DATABASE_URL="postgresql://${{PGUSER}}:${{POSTGRES_PASSWORD}}@${{RAILWAY_PRIVATE_DOMAIN}}:5432/${{PGDATABASE}}"
DATABASE_PUBLIC_URL="postgresql://${{PGUSER}}:${{POSTGRES_PASSWORD}}@${{RAILWAY_TCP_PROXY_DOMAIN}}:${{RAILWAY_TCP_PROXY_PORT}}/${{PGDATABASE}}"
```

**Estas variables usan templates `${{...}}` que Railway resuelve automáticamente.**

## ✅ Pasos para Conectar la Base de Datos

### Opción 1: Conectar Servicios (Recomendado)

1. **Ve a tu servicio de aplicación web** (no el de PostgreSQL)
2. **Ve a "Settings"** → **"Connect"** o **"Variables"**
3. **Busca la sección "Connected Services"** o **"Service Connections"**
4. **Haz clic en "Connect"** junto al servicio PostgreSQL
5. Railway automáticamente:
   - Expondrá `DATABASE_URL` a tu aplicación
   - Resolverá los templates `${{...}}`
   - Conectará los servicios

### Opción 2: Configurar Manualmente (Si la opción 1 no funciona)

1. **Ve a tu servicio PostgreSQL**
2. **Ve a "Variables"**
3. **Copia el valor de `DATABASE_URL`** (debería verse resuelto, no con `${{...}}`)
4. **Ve a tu servicio de aplicación web**
5. **Ve a "Variables"**
6. **Agrega una nueva variable:**
   - Nombre: `DATABASE_URL`
   - Valor: Pega la URL que copiaste

**IMPORTANTE:** La URL debe verse así (resuelta):
```
postgresql://postgres:shtGCfBnOoZoSXUAVERCXRMdUGtyHCSD@postgres.railway.internal:5432/railway
```

NO debe tener `${{...}}` en la URL final.

## 🔍 Verificar que Funciona

### En Railway Dashboard:

1. **Ve a tu servicio de aplicación web**
2. **Ve a "Variables"**
3. **Busca `DATABASE_URL`**
4. **Verifica que:**
   - ✅ Esté presente
   - ✅ NO tenga `${{...}}` (debe estar resuelta)
   - ✅ Empiece con `postgresql://`

### En los Logs:

Después de conectar, en los logs de tu aplicación deberías ver:

```
✅ Database migrations completed
✅ Server running on port...
```

En lugar de:
```
❌ DBConnection.ConnectionError
❌ timeout
```

## 🚨 Problemas Comunes

### Problema 1: `DATABASE_URL` tiene templates `${{...}}`

**Solución:** Railway no está resolviendo las variables. Intenta:
1. Desconectar y reconectar los servicios
2. Reiniciar ambos servicios
3. Usar la Opción 2 (configuración manual)

### Problema 2: `DATABASE_URL` no existe en la aplicación web

**Solución:** Los servicios no están conectados:
1. Ve a Settings → Connect
2. Conecta PostgreSQL a tu aplicación web

### Problema 3: Error de SSL

**Solución:** Railway usa conexiones internas, pero si hay problemas:
1. Verifica que `ssl: true` esté en `config/runtime.exs` (ya está)
2. Railway maneja SSL automáticamente en conexiones internas

## 📝 Formato Correcto de DATABASE_URL

Railway puede usar dos formatos:

1. **Conexión Privada (recomendada):**
   ```
   postgresql://postgres:PASSWORD@postgres.railway.internal:5432/railway
   ```

2. **Conexión Pública (si la privada no funciona):**
   ```
   postgresql://postgres:PASSWORD@proxy.railway.app:PORT/railway
   ```

**Para Ecto, ambos formatos funcionan.** Railway prefiere la conexión privada.

## ✅ Checklist Final

- [ ] PostgreSQL está agregado como servicio
- [ ] PostgreSQL está conectado a la aplicación web (Settings → Connect)
- [ ] `DATABASE_URL` existe en las variables de la aplicación web
- [ ] `DATABASE_URL` está resuelta (sin `${{...}}`)
- [ ] `DATABASE_URL` empieza con `postgresql://`
- [ ] Servicios están reiniciados
- [ ] Logs muestran "Database migrations completed"

---

**Una vez conectado correctamente, Railway manejará todo automáticamente** 🚀

