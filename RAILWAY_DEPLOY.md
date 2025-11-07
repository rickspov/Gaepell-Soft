# 🚂 Guía de Deploy en Railway

Esta guía te ayudará a desplegar el sistema CRM de gestión de flotas en Railway.

## 📋 Prerrequisitos

1. Cuenta en [Railway](https://railway.app)
2. Repositorio en GitHub con el código del proyecto
3. PostgreSQL (se puede agregar desde Railway)

## 🚀 Pasos para el Deploy

### 1. Preparar el Repositorio

Asegúrate de que tu código esté en GitHub y que el proyecto esté organizado:

```bash
# El proyecto principal está en: evaa_crm_gaepell/
# Asegúrate de que esté en la raíz del repositorio o ajusta la configuración
```

### 2. Crear Proyecto en Railway

1. Ve a [Railway Dashboard](https://railway.app/dashboard)
2. Haz clic en **"New Project"**
3. Selecciona **"Deploy from GitHub repo"**
4. Conecta tu cuenta de GitHub si es necesario
5. Selecciona el repositorio `crm` (o el nombre de tu repo)
6. Railway detectará automáticamente el proyecto

### 3. Agregar Base de Datos PostgreSQL

1. En el proyecto de Railway, haz clic en **"+ New"**
2. Selecciona **"Database"** → **"Add PostgreSQL"**
3. Railway creará automáticamente una base de datos PostgreSQL
4. La variable `DATABASE_URL` se configurará automáticamente

### 4. Configurar Variables de Entorno

En el servicio de tu aplicación, ve a la pestaña **"Variables"** y agrega:

#### Variables Requeridas:

```bash
# Secret Key Base (generar uno nuevo)
SECRET_KEY_BASE=tu-secret-key-base-generado

# Phoenix Server
PHX_SERVER=true

# Host (se actualizará automáticamente, pero puedes configurarlo)
PHX_HOST=tu-app.railway.app

# Pool Size para la base de datos
POOL_SIZE=10

# Environment
MIX_ENV=prod

# Business ID (ajustar según tu caso)
BUSINESS_ID=1
```

#### Generar SECRET_KEY_BASE

Puedes generar un SECRET_KEY_BASE usando:

```bash
# En tu máquina local
mix phx.gen.secret
```

O usar el script incluido:

```bash
elixir scripts/generate_secret.exs
```

### 5. Configurar el Root Directory (si es necesario)

Si tu proyecto no está en la raíz del repositorio:

1. Ve a **Settings** → **Service**
2. En **"Root Directory"**, especifica: `evaa_crm_gaepell`

### 6. Deploy

Railway detectará automáticamente:
- El archivo `railway.toml` o `railway.json`
- Que es un proyecto Elixir/Phoenix
- Las dependencias necesarias

El deploy se iniciará automáticamente. Puedes ver el progreso en la pestaña **"Deployments"**.

### 7. Ejecutar Migraciones

Las migraciones se ejecutan automáticamente en el `startCommand` configurado en `railway.toml`:

```bash
mix ecto.migrate && mix phx.server
```

Si necesitas ejecutar migraciones manualmente:

1. Ve a la pestaña **"Deployments"**
2. Haz clic en el deployment más reciente
3. Abre la terminal
4. Ejecuta: `mix ecto.migrate`

### 8. Verificar el Deploy

1. Una vez completado el deploy, Railway te dará una URL pública
2. Visita la URL para verificar que la aplicación esté funcionando
3. Revisa los logs en la pestaña **"Deployments"** si hay problemas

## 🔧 Configuración Avanzada

### Dominio Personalizado

1. Ve a **Settings** → **Networking**
2. Haz clic en **"Generate Domain"** para obtener un dominio Railway
3. O configura un dominio personalizado en **"Custom Domain"**

### Variables de Entorno Sensibles

Para datos sensibles, usa **Railway Secrets**:
1. Ve a **Variables**
2. Marca las variables como **"Secret"**
3. Estas no se mostrarán en los logs

### Monitoreo y Logs

- **Logs**: Disponibles en tiempo real en la pestaña **"Deployments"**
- **Métricas**: Railway proporciona métricas básicas de CPU, memoria y red
- **Health Checks**: Configurados automáticamente en `/`

## 🐛 Solución de Problemas

### Error: "Database connection failed"

- Verifica que PostgreSQL esté agregado como servicio
- Verifica que `DATABASE_URL` esté configurada correctamente
- Revisa los logs para más detalles

### Error: "SECRET_KEY_BASE not set"

- Asegúrate de haber configurado `SECRET_KEY_BASE` en las variables de entorno
- Genera uno nuevo si es necesario: `mix phx.gen.secret`

### Error: "Port already in use"

- Railway maneja el puerto automáticamente con la variable `PORT`
- No necesitas configurar el puerto manualmente

### Migraciones fallan

- Verifica que la base de datos esté creada
- Revisa los logs para ver el error específico
- Ejecuta las migraciones manualmente desde la terminal de Railway

### Build falla

- Verifica que todas las dependencias estén en `mix.exs`
- Revisa los logs de build para ver errores específicos
- Asegúrate de que `mix.lock` esté en el repositorio

## 📝 Estructura del Proyecto

```
evaa_crm_gaepell/
├── apps/
│   ├── evaa_crm_gaepell/      # Contexto principal (BD, modelos)
│   └── evaa_crm_web_gaepell/  # Aplicación web (Phoenix)
├── config/
│   ├── config.exs             # Configuración general
│   ├── runtime.exs            # Configuración de producción
│   └── prod.exs               # Configuración específica de producción
├── priv/
│   └── repo/
│       └── migrations/        # Migraciones de base de datos
├── railway.toml               # Configuración de Railway
└── railway.json               # Configuración alternativa de Railway
```

## 🔄 Actualizaciones Futuras

Para actualizar la aplicación:

1. Haz push a tu repositorio de GitHub
2. Railway detectará automáticamente los cambios
3. Iniciará un nuevo deploy automáticamente
4. Las migraciones se ejecutarán automáticamente

## 📞 Soporte

Si tienes problemas con el deploy:

1. Revisa los logs en Railway
2. Verifica que todas las variables de entorno estén configuradas
3. Consulta la [documentación de Railway](https://docs.railway.app)
4. Contacta al equipo de desarrollo

---

**¡Listo para desplegar! 🚀**

