# 📁 Organización del Proyecto para Railway

Este documento explica cómo está organizado el proyecto para facilitar el deploy en Railway.

## 🎯 Objetivo

Organizar el sistema CRM de gestión de flotas (con base de datos de camiones) para poder:
1. Subirlo a GitHub de forma limpia
2. Hacer deploy automático en Railway
3. Mantener el código organizado y profesional

## 📂 Estructura del Proyecto

El proyecto principal está en la carpeta `evaa_crm_gaepell/`:

```
evaa_crm_gaepell/
├── apps/                          # Aplicaciones del umbrella
│   ├── evaa_crm_gaepell/         # Contexto principal (BD, modelos)
│   │   ├── lib/                   # Módulos de negocio (Truck, User, etc.)
│   │   └── priv/repo/             # Migraciones y seeds
│   └── evaa_crm_web_gaepell/      # Aplicación web (Phoenix)
│       ├── lib/                   # LiveViews, controllers, routers
│       └── assets/                # CSS, JS, imágenes
├── config/                        # Configuraciones
│   ├── config.exs                 # Configuración general
│   ├── runtime.exs                # Configuración de producción (Railway)
│   └── prod.exs                   # Configuración específica de producción
├── priv/                          # Archivos estáticos
├── scripts/                       # Scripts de utilidad
├── railway.toml                   # Configuración Railway (principal)
├── railway.json                   # Configuración alternativa Railway
├── .gitignore                     # Archivos excluidos de Git
├── README.md                      # Documentación principal
├── RAILWAY_DEPLOY.md             # Guía detallada de deploy
└── DEPLOY_CHECKLIST.md           # Checklist de deploy
```

## 🗑️ Archivos Excluidos (en .gitignore)

Para mantener el repositorio limpio, se excluyen:

- **Backups de BD**: `*.sql`, `*-backup.sql`
- **Archivos comprimidos**: `*.zip`, `*.backup`
- **Scripts de test/debug**: `test_*.exs`, `debug_*.exs`, etc.
- **Archivos compilados**: `_build/`, `deps/`, `*.beam`
- **Archivos de entorno**: `*.env`
- **Datos de muestra**: `sample_data/*.pdf`
- **Paquetes de migración**: `migration_package/`

## 🔧 Configuración para Railway

### Archivos de Configuración

1. **railway.toml** - Configuración principal de Railway
   - Builder: Nixpacks (detecta automáticamente Elixir)
   - Start command: Ejecuta migraciones y luego el servidor
   - Health check: Configurado en `/`

2. **config/runtime.exs** - Configuración de producción
   - Lee variables de entorno
   - Configura endpoint y base de datos
   - Validaciones de variables requeridas

### Variables de Entorno Necesarias

Railway configurará automáticamente:
- `DATABASE_URL` (cuando agregas PostgreSQL)
- `PORT` (puerto del servicio)

Debes configurar manualmente:
- `SECRET_KEY_BASE` (generar con `mix phx.gen.secret`)
- `PHX_SERVER=true`
- `PHX_HOST` (o usar el dominio de Railway)
- `POOL_SIZE=10`
- `MIX_ENV=prod`

## 🚀 Proceso de Deploy

### 1. Preparar el Repositorio

```bash
# Asegúrate de estar en la carpeta del proyecto
cd evaa_crm_gaepell

# Verifica que .gitignore esté actualizado
# (ya está actualizado)

# Commit y push a GitHub
git add .
git commit -m "Organizar proyecto para deploy en Railway"
git push origin main
```

### 2. Configurar en Railway

1. Crear proyecto en Railway
2. Conectar repositorio de GitHub
3. Agregar PostgreSQL como servicio
4. Configurar variables de entorno
5. Deploy automático

Ver [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md) para instrucciones detalladas.

## 📝 Archivos Importantes

### Documentación
- **README.md**: Documentación principal del proyecto
- **RAILWAY_DEPLOY.md**: Guía paso a paso para deploy
- **DEPLOY_CHECKLIST.md**: Checklist para verificar el deploy

### Configuración
- **railway.toml**: Configuración de Railway
- **config/runtime.exs**: Configuración de producción
- **.gitignore**: Archivos excluidos de Git

### Código Principal
- **apps/evaa_crm_gaepell/**: Lógica de negocio y modelos
- **apps/evaa_crm_web_gaepell/**: Interfaz web (Phoenix)

## ✅ Estado Actual

El proyecto está organizado y listo para:

- ✅ Subir a GitHub (archivos innecesarios excluidos)
- ✅ Deploy en Railway (configuración lista)
- ✅ Migraciones automáticas (en startCommand)
- ✅ Variables de entorno (documentadas)
- ✅ Health checks (configurados)

## 🔄 Próximos Pasos

1. **Subir a GitHub**
   ```bash
   git add .
   git commit -m "Proyecto organizado para Railway"
   git push origin main
   ```

2. **Crear proyecto en Railway**
   - Seguir [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md)

3. **Configurar variables de entorno**
   - Usar [DEPLOY_CHECKLIST.md](./DEPLOY_CHECKLIST.md)

4. **Verificar deploy**
   - Revisar logs
   - Probar la aplicación
   - Verificar base de datos

## 📞 Soporte

Si tienes problemas:
1. Revisa [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md)
2. Consulta [DEPLOY_CHECKLIST.md](./DEPLOY_CHECKLIST.md)
3. Revisa los logs en Railway Dashboard

---

**Proyecto organizado y listo para deploy** 🚀

