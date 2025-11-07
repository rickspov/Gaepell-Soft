# 🔌 Información sobre Puertos en Railway

## 📋 URLs de Base de Datos en Railway

Railway crea **dos URLs** para PostgreSQL:

### 1. `DATABASE_URL` (Conexión Privada - Recomendada)
```
postgresql://postgres:PASSWORD@postgres.railway.internal:5432/railway
```
- **Puerto:** 5432 (puerto estándar de PostgreSQL)
- **Host:** `postgres.railway.internal` (red privada de Railway)
- **Ventaja:** Más rápida, conexión directa
- **Uso:** Conexiones internas entre servicios

### 2. `DATABASE_PUBLIC_URL` (Conexión Pública - TCP Proxy)
```
postgresql://postgres:PASSWORD@proxy.railway.app:PUERTO_DINAMICO/railway
```
- **Puerto:** Dinámico (Railway asigna uno)
- **Host:** `proxy.railway.app` (proxy público)
- **Ventaja:** Accesible desde fuera de Railway
- **Uso:** Conexiones externas o cuando la privada no funciona

## ✅ Configuración Automática

La aplicación está configurada para usar **ambas URLs**:

1. **Primero intenta:** `DATABASE_URL` (conexión privada, puerto 5432)
2. **Si no existe:** Usa `DATABASE_PUBLIC_URL` (TCP proxy, puerto dinámico)

Esto asegura que funcione en ambos casos.

## 🔍 Verificar qué URL está usando

En los logs de Railway, busca mensajes como:
```
[info] Running migrations...
```

Si ves errores de conexión, verifica:

1. **¿Qué URL tiene tu aplicación?**
   - Ve a tu servicio web → Variables
   - Busca `DATABASE_URL` o `DATABASE_PUBLIC_URL`
   - Copia el valor

2. **¿Qué puerto está usando?**
   - Si es `5432` → Usa `DATABASE_URL` (privada) ✅
   - Si es otro número → Usa `DATABASE_PUBLIC_URL` (proxy) ⚠️

## 🚨 Problemas Comunes con Puertos

### Problema 1: Puerto 5432 no funciona

**Solución:** Railway puede estar usando el TCP proxy. Verifica:
1. ¿Tienes `DATABASE_PUBLIC_URL` configurada?
2. La aplicación la usará automáticamente si `DATABASE_URL` no está disponible

### Problema 2: Puerto dinámico cambia

**Solución:** Railway puede cambiar el puerto del proxy. Para evitar esto:
1. Usa `DATABASE_URL` (conexión privada) siempre que sea posible
2. Railway la configura automáticamente cuando conectas los servicios

### Problema 3: Timeout en conexión

**Solución:** Los timeouts ya están configurados en `runtime.exs`:
- `connect_timeout: 10_000` (10 segundos)
- `timeout: 15_000` (15 segundos)

Si sigue fallando, puede ser un problema de red, no de puerto.

## 📝 Formato de URL Esperado

Ecto acepta estos formatos:

✅ **Válidos:**
```
postgresql://user:pass@host:5432/db
postgres://user:pass@host:5432/db
ecto://user:pass@host:5432/db
```

❌ **Inválidos:**
```
postgresql://user:pass@host/db  (sin puerto - Ecto usa 5432 por defecto)
```

La aplicación normaliza automáticamente `postgres://` y `ecto://` a `postgresql://`.

## 🔧 Configuración Manual (Si es Necesario)

Si Railway no está conectando automáticamente:

1. **Ve a tu servicio PostgreSQL → Variables**
2. **Copia `DATABASE_URL`** (debe estar resuelta, sin `${{...}}`)
3. **Ve a tu servicio web → Variables**
4. **Agrega manualmente:**
   - Nombre: `DATABASE_URL`
   - Valor: La URL que copiaste

**Formato esperado:**
```
postgresql://postgres:PASSWORD@HOST:PUERTO/railway
```

Donde:
- `PASSWORD` = Tu contraseña de PostgreSQL
- `HOST` = `postgres.railway.internal` (privada) o `proxy.railway.app` (pública)
- `PUERTO` = `5432` (privada) o número dinámico (pública)
- `railway` = Nombre de la base de datos

## ✅ Checklist

- [ ] PostgreSQL está agregado como servicio
- [ ] Servicios están conectados (Settings → Connect)
- [ ] `DATABASE_URL` existe en variables de la aplicación
- [ ] `DATABASE_URL` está resuelta (sin `${{...}}`)
- [ ] URL tiene formato correcto: `postgresql://user:pass@host:port/db`
- [ ] Puerto es `5432` (privada) o está especificado (pública)

---

**La aplicación maneja automáticamente ambos tipos de conexión** ✅

