# 🔐 Variables de Entorno para Railway

Copia y pega estas variables en Railway Dashboard → Variables

## ✅ Variables para Configurar en Railway

```bash
# Secret Key Base (generado automáticamente)
SECRET_KEY_BASE=i5vWmQ9NZsot7WM3pAkgcvu6Nn0tbA8ayeGskLzbOM84vrNXpAgNunLa2BSrGBD8Cc5S4bcMeNUfkE2Gs9v/sQ==

# Phoenix Server
PHX_SERVER=true

# Pool Size para la base de datos
POOL_SIZE=10

# Environment
MIX_ENV=prod

# Business ID (ajustar según tu caso)
BUSINESS_ID=1
```

## 📝 Notas Importantes

### PHX_HOST
**NO configures `PHX_HOST` manualmente al inicio.** 

Railway te dará automáticamente una URL como: `tu-proyecto.railway.app`

Después del primer deploy:
1. Ve a Railway Dashboard → Settings → Networking
2. Copia el dominio que Railway te asignó (ejemplo: `gaepell-soft-production.up.railway.app`)
3. Agrega esa variable: `PHX_HOST=gaepell-soft-production-production.up.railway.app`

O simplemente deja que Railway lo configure automáticamente.

### DATABASE_URL
**NO necesitas configurar `DATABASE_URL` manualmente.**

Railway la configura automáticamente cuando:
1. Agregas PostgreSQL como servicio
2. Conectas el servicio de PostgreSQL con tu aplicación

Railway crea automáticamente la variable `DATABASE_URL` con la conexión correcta.

### PORT
**NO necesitas configurar `PORT`.**

Railway lo configura automáticamente.

## 🚀 Pasos para Configurar en Railway

1. **Ve a tu proyecto en Railway Dashboard**
2. **Selecciona tu servicio** (la aplicación web)
3. **Ve a la pestaña "Variables"**
4. **Haz clic en "New Variable"** para cada una:
   - `SECRET_KEY_BASE` = `i5vWmQ9NZsot7WM3pAkgcvu6Nn0tbA8ayeGskLzbOM84vrNXpAgNunLa2BSrGBD8Cc5S4bcMeNUfkE2Gs9v/sQ==`
   - `PHX_SERVER` = `true`
   - `POOL_SIZE` = `10`
   - `MIX_ENV` = `prod`
   - `BUSINESS_ID` = `1` (ajusta según necesites)

5. **Marca `SECRET_KEY_BASE` como "Secret"** (para que no se muestre en logs)

6. **Después del primer deploy**, agrega:
   - `PHX_HOST` = `<tu-dominio-railway.app>` (obtener de Settings → Networking)

## 🔒 Seguridad

- ✅ Marca `SECRET_KEY_BASE` como "Secret" en Railway
- ✅ No compartas el `SECRET_KEY_BASE` públicamente
- ✅ Cada ambiente (dev/prod) debe tener su propio `SECRET_KEY_BASE`

## 🔄 Si Necesitas Generar un Nuevo SECRET_KEY_BASE

Si necesitas generar uno nuevo, puedes usar:

**En Windows (PowerShell):**
```powershell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

**En Linux/Mac:**
```bash
mix phx.gen.secret
```

O usar el script del proyecto:
```bash
mix run scripts/generate_secret.exs
```

---

**¡Listo para configurar en Railway!** 🚀

