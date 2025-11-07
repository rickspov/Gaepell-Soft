# 🚀 GP CRM - Sistema de Gestión de Flotas

Sistema CRM especializado para gestión de flotas vehiculares, desarrollado con Phoenix LiveView y Elixir.

## 🎯 Características Principales

- ✅ **Gestión de Flotas**: Control completo de vehículos (camiones)
- ✅ **Tickets de Mantenimiento**: Seguimiento de reparaciones
- ✅ **Evaluaciones**: Sistema de inspección vehicular
- ✅ **Órdenes de Producción**: Gestión de manufactura
- ✅ **Dashboard Interactivo**: Vista general del sistema
- ✅ **Sistema de Archivos**: Gestión de documentos e imágenes
- ✅ **Wizard de Check-in**: Proceso guiado de entrada
- ✅ **Gestión de Usuarios**: Sistema de autenticación y roles

## 🛠️ Tecnologías

- **Backend**: Elixir + Phoenix LiveView
- **Base de Datos**: PostgreSQL
- **Frontend**: Tailwind CSS + Alpine.js
- **Deploy**: Railway
- **Versionado**: Git + GitHub

## 🚀 Deploy Rápido en Railway

Este proyecto está listo para deploy en Railway. Para instrucciones detalladas, consulta [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md).

### Pasos Rápidos:

1. **Conectar repositorio** en Railway desde GitHub
2. **Agregar PostgreSQL** como servicio
3. **Configurar variables de entorno** (ver abajo)
4. **Deploy automático** - Railway detectará el proyecto

### Variables de Entorno Mínimas:

```bash
SECRET_KEY_BASE=<generar con: mix phx.gen.secret>
PHX_SERVER=true
PHX_HOST=<tu-dominio.railway.app>
POOL_SIZE=10
MIX_ENV=prod
BUSINESS_ID=1
```

> **Nota**: `DATABASE_URL` se configura automáticamente cuando agregas PostgreSQL en Railway.

## 📊 Estructura del Proyecto

```
evaa_crm_gaepell/
├── apps/
│   ├── evaa_crm_gaepell/          # Contexto principal (BD, modelos, lógica)
│   │   ├── lib/                   # Módulos de negocio
│   │   └── priv/repo/             # Migraciones y seeds
│   └── evaa_crm_web_gaepell/      # Aplicación web (Phoenix)
│       ├── lib/                   # LiveViews, controllers, routers
│       └── assets/                # CSS, JS, imágenes
├── config/                        # Configuraciones por ambiente
│   ├── config.exs                 # Configuración general
│   ├── runtime.exs                # Configuración de producción
│   └── prod.exs                   # Configuración específica de producción
├── priv/                          # Archivos estáticos
├── scripts/                       # Scripts de utilidad
├── railway.toml                   # Configuración Railway
└── railway.json                   # Configuración alternativa Railway
```

## 🔧 Desarrollo Local

### Prerrequisitos

- Elixir 1.14+
- PostgreSQL
- Node.js (para assets)

### Instalación

```bash
# Instalar dependencias de Elixir
mix deps.get

# Instalar dependencias de Node.js
cd apps/evaa_crm_web_gaepell/assets
npm install
cd ../../..

# Configurar base de datos
mix ecto.create
mix ecto.migrate

# Ejecutar seeds (datos iniciales)
mix run apps/evaa_crm_gaepell/priv/repo/seeds.exs

# Iniciar servidor
mix phx.server
```

La aplicación estará disponible en `http://localhost:4001`

## 📱 Funcionalidades Principales

### Gestión de Flotas (Camiones)
- Registro de vehículos con información completa
- Fotos y documentos por vehículo
- Historial de mantenimientos
- Seguimiento de kilometraje
- Estados: activo, mantenimiento, inactivo

### Dashboard
- Vista general de tickets y vehículos
- Estadísticas en tiempo real
- Accesos rápidos a funciones principales

### Tickets de Mantenimiento
- Creación y seguimiento de tickets
- Asignación a técnicos
- Sistema de archivos adjuntos
- Historial completo de actividades

### Sistema de Usuarios
- Autenticación segura
- Roles y permisos
- Gestión por empresa (multi-tenant)

## 🗄️ Base de Datos

El sistema utiliza PostgreSQL con las siguientes tablas principales:

- `trucks` - Información de vehículos
- `maintenance_tickets` - Tickets de mantenimiento
- `users` - Usuarios del sistema
- `businesses` - Empresas (multi-tenant)
- `activities` - Log de actividades
- Y más...

Las migraciones están en: `apps/evaa_crm_gaepell/priv/repo/migrations/`

## 🛡️ Seguridad

- Autenticación con bcrypt
- Autorización por roles
- Validación de datos en todos los niveles
- Sanitización de inputs
- Variables de entorno para secretos

## 📈 Monitoreo y Logs

- Logs estructurados
- Health checks en `/`
- Métricas de performance
- Alertas de errores

## 🚀 Deploy en Producción

Para instrucciones detalladas de deploy en Railway, consulta [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md).

### Checklist Pre-Deploy:

- [ ] Variables de entorno configuradas
- [ ] `SECRET_KEY_BASE` generado
- [ ] Base de datos PostgreSQL agregada
- [ ] Migraciones ejecutadas
- [ ] Health check funcionando

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto es privado y confidencial.

## 📞 Soporte

Para soporte técnico o preguntas sobre el deploy:
- Consulta [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md) para problemas de deploy
- Revisa los logs en Railway Dashboard
- Contacta al equipo de desarrollo

---

**Desarrollado con ❤️ usando Phoenix LiveView y Elixir**