# 🌐 Cómo Acceder a tu Aplicación en Railway

## 🔗 Obtener la URL Pública

El dominio `gaepell-soft.railway.internal` es **interno** (solo funciona dentro de Railway). Necesitas el **dominio público**.

### Opción 1: Generar Dominio Público en Railway

1. **Ve a tu servicio de aplicación web** en Railway Dashboard
2. **Ve a "Settings"** → **"Networking"** (o "Public Networking")
3. **Haz clic en "Generate Domain"** o **"Generate Public URL"**
4. Railway te dará una URL como: `gaepell-soft-production.up.railway.app`
5. **Copia esa URL** - esa es la que debes usar para acceder

### Opción 2: Usar el Dominio que Railway ya Asignó

1. **Ve a "Settings"** → **"Networking"**
2. Busca la sección **"Public Domain"** o **"Service Domain"**
3. Deberías ver algo como: `gaepell-soft-production.up.railway.app`
4. **Esa es tu URL pública**

## 🔐 Crear Usuario Inicial

Si no tienes usuarios creados, necesitas crear uno. Tienes dos opciones:

### Opción 1: Ejecutar Seeds (Recomendado)

1. **Ve a la terminal de Railway** (en tu servicio web)
2. **Ejecuta:**
   ```bash
   mix run apps/evaa_crm_gaepell/priv/repo/seeds.exs
   ```
   O si tienes seeds específicos:
   ```bash
   mix run apps/evaa_crm_gaepell/priv/repo/seeds_gaepell.exs
   ```

### Opción 2: Crear Usuario Manualmente desde la Terminal

1. **Ve a la terminal de Railway** (en tu servicio web)
2. **Ejecuta:**
   ```bash
   iex -S mix
   ```
3. **En la consola de Elixir, ejecuta:**
   ```elixir
   alias EvaaCrmGaepell.{Repo, User, Business}
   
   # Obtener el business_id (ajusta según tu caso)
   business = Repo.one!(from b in Business, limit: 1)
   
   # Crear usuario
   password_hash = Bcrypt.hash_pwd_salt("tu_contraseña_segura")
   
   Repo.insert!(%User{
     email: "admin@example.com",
     password_hash: password_hash,
     role: "admin",
     business_id: business.id
   })
   ```
4. **Sal de la consola:** `Ctrl+C` dos veces

## 📝 Credenciales por Defecto

Revisa los archivos de seeds para ver si hay credenciales por defecto:
- `apps/evaa_crm_gaepell/priv/repo/seeds.exs`
- `apps/evaa_crm_gaepell/priv/repo/seeds_gaepell.exs`

## ✅ Verificar Acceso

1. **Abre tu URL pública** en el navegador (ejemplo: `https://gaepell-soft-production.up.railway.app`)
2. **Deberías ver la página de login**
3. **Ingresa con las credenciales** que creaste o las del seed

## 🔧 Si No Puedes Acceder

1. **Verifica que el servicio esté corriendo:**
   - Ve a "Deployments" → Revisa que esté "Active"
   
2. **Verifica el dominio público:**
   - Debe ser `https://...` (no `http://`)
   - No debe ser `.railway.internal` (ese es interno)

3. **Verifica las variables de entorno:**
   - `PHX_HOST` debe estar configurada con el dominio público
   - O déjala vacía y Railway la configurará automáticamente

---

**Una vez que tengas el dominio público y un usuario, podrás acceder a la aplicación** ✅

