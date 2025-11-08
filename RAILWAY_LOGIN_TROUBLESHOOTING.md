# 🔐 Troubleshooting de Login en Railway

## Problema: No puedo iniciar sesión

### Verificación Rápida

1. **Verifica que los seeds se ejecutaron:**
   - Revisa los logs de Railway durante el inicio
   - Deberías ver: `✅ Seeds completed successfully`

2. **Verifica las credenciales:**
   - **Email:** `admin@eva.com`
   - **Contraseña:** `admin123`

### Soluciones

#### Opción 1: Ejecutar Seeds Manualmente (Recomendado)

Si los seeds no se ejecutaron automáticamente, puedes ejecutarlos manualmente:

1. En Railway, ve a tu servicio
2. Abre la terminal (Railway CLI o Web Terminal)
3. Ejecuta:
   ```bash
   mix run apps/evaa_crm_gaepell/priv/repo/seeds_gaepell.exs
   ```

#### Opción 2: Verificar Usuarios en la Base de Datos

Para verificar si los usuarios existen:

1. En Railway, ve a tu servicio PostgreSQL
2. Abre la terminal o usa Railway CLI:
   ```bash
   railway connect postgresql
   ```
3. Ejecuta:
   ```sql
   SELECT email, role, business_id FROM users;
   ```

#### Opción 3: Crear Usuario Manualmente

Si necesitas crear un usuario manualmente:

1. En Railway, ve a tu servicio
2. Abre la terminal
3. Ejecuta:
   ```bash
   mix run -e "
   alias EvaaCrmGaepell.{Repo, User, Business}
   alias Bcrypt
   
   # Obtener el business_id (asumiendo que existe)
   business = Repo.one(from b in Business, limit: 1)
   
   if business do
     user = %User{}
     |> User.changeset(%{
       email: \"admin@eva.com\",
       password: \"admin123\",
       password_confirmation: \"admin123\",
       role: \"admin\",
       business_id: business.id
     })
     |> Repo.insert!()
     
     IO.puts(\"✅ Usuario creado: #{user.email}\")
   else
     IO.puts(\"❌ No hay business en la base de datos\")
   end
   "
   ```

### Verificar Logs de Railway

1. Ve a tu proyecto en Railway
2. Selecciona el servicio
3. Ve a la pestaña "Logs"
4. Busca mensajes relacionados con:
   - `Seeds completed successfully`
   - `ERROR` o `WARNING` relacionados con seeds
   - Errores de base de datos

### Mensajes de Error Comunes

- **"Email o contraseña incorrectos"**: El usuario no existe o la contraseña es incorrecta
- **"Usuario sin contraseña configurada"**: El usuario existe pero no tiene password_hash
- **Sin mensaje de error**: Los seeds no se ejecutaron

### Contacto

Si después de seguir estos pasos aún no puedes iniciar sesión, verifica:
1. Los logs de Railway para errores específicos
2. Que la base de datos esté conectada correctamente
3. Que las migraciones se hayan ejecutado correctamente

