# 🚀 GP CRM - Sistema de Gestión de Flotas

Sistema CRM especializado para gestión de flotas vehiculares, desarrollado con Phoenix LiveView y Elixir.

## 🎯 Características Principales

- ✅ **Gestión de Flotas**: Control completo de vehículos
- ✅ **Tickets de Mantenimiento**: Seguimiento de reparaciones
- ✅ **Evaluaciones**: Sistema de inspección vehicular
- ✅ **Órdenes de Producción**: Gestión de manufactura
- ✅ **Dashboard Interactivo**: Vista general del sistema
- ✅ **Sistema de Archivos**: Gestión de documentos e imágenes
- ✅ **Wizard de Check-in**: Proceso guiado de entrada

## 🛠️ Tecnologías

- **Backend**: Elixir + Phoenix LiveView
- **Base de Datos**: PostgreSQL
- **Frontend**: Tailwind CSS + Alpine.js
- **Deploy**: Railway
- **Versionado**: Git + GitHub

## 🚀 Deploy en Railway

### Configuración Automática

El proyecto está configurado para deploy automático en Railway:

1. **Conectar repositorio** en Railway
2. **Agregar PostgreSQL** como servicio
3. **Configurar variables de entorno**
4. **Deploy automático** desde GitHub

### Variables de Entorno Requeridas

```bash
SECRET_KEY_BASE=tu-secret-key-base
PHX_SERVER=true
PHX_HOST=tu-dominio.railway.app
BUSINESS_ID=1
POOL_SIZE=10
```

## 📊 Estructura del Proyecto

```
evaa_crm_gaepell/
├── apps/
│   ├── evaa_crm_gaepell/          # Contexto principal
│   └── evaa_crm_web_gaepell/      # Web interface
├── config/                        # Configuraciones
├── priv/                         # Assets y migraciones
├── scripts/                      # Scripts de deploy
└── railway.json                  # Configuración Railway
```

## 🔧 Desarrollo Local

```bash
# Instalar dependencias
mix deps.get

# Configurar base de datos
mix ecto.create
mix ecto.migrate

# Ejecutar seeds
mix run priv/repo/seeds.exs

# Iniciar servidor
mix phx.server
```

## 📱 Funcionalidades

### Dashboard
- Vista general de tickets
- Estadísticas en tiempo real
- Accesos rápidos

### Gestión de Tickets
- Creación de tickets
- Seguimiento de estado
- Sistema de archivos adjuntos

### Wizard de Check-in
- Proceso guiado
- Validaciones automáticas
- Integración con sistema de archivos

## 🛡️ Seguridad

- Autenticación de usuarios
- Autorización por roles
- Validación de datos
- Sanitización de inputs

## 📈 Monitoreo

- Logs en tiempo real
- Métricas de performance
- Health checks automáticos
- Alertas de errores

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch
3. Commit cambios
4. Push al branch
5. Crear Pull Request

## 📄 Licencia

Este proyecto es privado y confidencial.

## 📞 Soporte

Para soporte técnico, contactar al equipo de desarrollo.

---

**Desarrollado con ❤️ usando Phoenix LiveView**