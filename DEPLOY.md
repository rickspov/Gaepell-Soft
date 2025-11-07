# 🚀 Deploy en Railway - EVA CRM

## Configuración Inicial

### 1. Variables de Entorno Requeridas

```bash
# Database (automático con PostgreSQL de Railway)
DATABASE_URL=postgresql://user:pass@host:port/dbname

# Phoenix
SECRET_KEY_BASE=tu-secret-key-base-muy-largo
PHX_HOST=tu-dominio.railway.app
PHX_SERVER=true

# Business
BUSINESS_ID=1
POOL_SIZE=10
```

### 2. Comandos de Deploy

```bash
# Instalar dependencias
mix deps.get --only prod

# Compilar dependencias
mix deps.compile

# Construir assets
mix assets.deploy

# Ejecutar migraciones
mix ecto.migrate

# Generar secret key base
mix phx.gen.secret
```

### 3. Health Check

El sistema incluye un endpoint de health check en `/` que Railway usará para verificar que la aplicación está funcionando correctamente.

### 4. Logs

Para ver los logs en tiempo real:

```bash
railway logs
```

### 5. Base de Datos

Railway automáticamente:
- ✅ Crea una instancia PostgreSQL
- ✅ Configura la variable `DATABASE_URL`
- ✅ Ejecuta las migraciones en el primer deploy

## 🛠️ Troubleshooting

### Error: "Secret key base not set"
```bash
# Generar secret key base
mix phx.gen.secret
# Copiar el resultado y configurarlo en Railway
```

### Error: "Database connection failed"
- Verificar que `DATABASE_URL` esté configurada
- Verificar que PostgreSQL esté corriendo

### Error: "Assets not found"
```bash
# Reconstruir assets
mix assets.deploy
```

## 📊 Monitoreo

- **Logs**: `railway logs`
- **Métricas**: Dashboard de Railway
- **Health Check**: `https://tu-app.railway.app/`

## 🔧 Comandos Útiles

```bash
# Ver estado del deploy
railway status

# Ver logs en tiempo real
railway logs --follow

# Conectar a la base de datos
railway connect postgresql

# Reiniciar la aplicación
railway redeploy
```


