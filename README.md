# EvaCRM

**Eficiencia Virtual Asistida** - Sistema de gestión completo para optimizar la eficiencia de tu negocio.

## Descripción

EvaCRM es una aplicación web moderna construida con Elixir y Phoenix que proporciona una solución integral para la gestión empresarial. Con un diseño inspirado en GitHub y una arquitectura robusta, EvaCRM ofrece:

- **Gestión de citas y eventos** - Agenda completa para programar y gestionar citas
- **CRM y contactos** - Gestión integral de clientes y leads
- **Analytics y KPIs** - Métricas y análisis de rendimiento
- **Facturación** - Sistema completo de facturación y cobros
- **Inventario** - Control de stock y productos
- **Caja registradora** - Gestión de transacciones en efectivo
- **Empleados** - Administración de personal y comisiones

## Características Principales

### 🎨 Diseño Moderno
- Interfaz estilo GitHub con barra lateral fija
- Tema light/dark con transiciones suaves
- Diseño responsive y accesible
- Navegación intuitiva con iconos

### 🏢 Multi-negocio
- Soporte para múltiples negocios
- Roles de usuario (admin, manager, specialist, employee)
- Separación completa de datos por negocio

### ⚡ Tecnología Avanzada
- **Backend**: Elixir + Phoenix + LiveView
- **Base de datos**: PostgreSQL con Ecto
- **Frontend**: Tailwind CSS + JavaScript moderno
- **Arquitectura**: Umbrella project para escalabilidad

### 🔒 Seguridad
- Autenticación robusta
- Autorización basada en roles
- Protección CSRF
- Validaciones de datos

## Instalación Rápida

```bash
# Clonar el repositorio
git clone <repository-url>
cd evaa_crm_umbrella

# Instalar dependencias
mix deps.get

# Configurar base de datos
mix ecto.setup

# Iniciar servidor
mix phx.server
```

Accede a http://localhost:4000

## Cuentas Demo

- **Admin**: `admin@eva.crm` / `password`
- **Specialist**: `yoga@eva.crm` / `password`

## Documentación

Para información detallada sobre instalación, configuración y desarrollo, consulta [EvaaCRM_SETUP.md](./EvaaCRM_SETUP.md).

## Tecnologías

- **Elixir** - Lenguaje funcional para el backend
- **Phoenix** - Framework web de alto rendimiento
- **LiveView** - Interfaz reactiva en tiempo real
- **Ecto** - ORM y query builder
- **PostgreSQL** - Base de datos relacional
- **Tailwind CSS** - Framework CSS utility-first
- **Alpine.js** - JavaScript minimalista

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Soporte

- 📧 Email: support@eva.crm
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/issues)
- 📖 Documentación: [Wiki](https://github.com/your-repo/wiki)

---

**EvaCRM** - Transformando la gestión empresarial con eficiencia virtual asistida.
