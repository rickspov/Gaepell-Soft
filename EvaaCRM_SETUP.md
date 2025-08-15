# EvaCRM - Guía de Instalación

## Requisitos Previos

Antes de instalar EvaCRM, asegúrate de tener instalado:

- **Elixir** (versión 1.18+)
- **Erlang** (versión 28+)
- **PostgreSQL** (versión 14+)
- **Homebrew** (para macOS)

### Instalación de Dependencias

```bash
# Instalar Homebrew (si no está instalado)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Agregar Homebrew al PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Instalar Elixir, Erlang y PostgreSQL
brew install elixir erlang postgresql@14

# Iniciar PostgreSQL
brew services start postgresql@14

# Crear usuario postgres (si no existe)
createuser -s postgres
```

## Instalación de EvaCRM

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd evaa_crm_umbrella
   ```

2. **Instalar dependencias**
   ```bash
   mix deps.get
   ```

3. **Configurar la base de datos**
   
   La configuración de la base de datos ya está preparada en:
   - `config/dev.exs` - Base de datos de desarrollo: `evaa_crm_dev`
   - `config/test.exs` - Base de datos de pruebas: `evaa_crm_test`
   - `config/runtime.exs` - Configuración de producción usando `DATABASE_URL`

4. **Crear y migrar la base de datos**
   ```bash
   mix ecto.setup
   ```

5. **Ejecutar seeds iniciales**
   ```bash
   mix run priv/repo/seeds.exs
   ```

## Comandos Útiles

### Desarrollo
```bash
# Iniciar el servidor de desarrollo
mix phx.server

# Iniciar con IEx (para debugging)
iex -S mix phx.server

# Compilar assets
mix assets.deploy
```

### Base de Datos
```bash
# Crear base de datos
mix ecto.create

# Ejecutar migraciones
mix ecto.migrate

# Revertir migración
mix ecto.rollback

# Resetear base de datos (drop + create + migrate + seed)
mix ecto.reset

# Ver estado de migraciones
mix ecto.migrations
```

### Testing
```bash
# Ejecutar todos los tests
mix test

# Ejecutar tests con coverage
mix test.coverage

# Ejecutar tests específicos
mix test test/path/to/test.exs
```

### Otros
```bash
# Formatear código
mix format

# Verificar sintaxis
mix compile

# Limpiar archivos compilados
mix clean
```

## Cuentas Seed

Después de ejecutar los seeds, tendrás las siguientes cuentas disponibles:

### Business
- **Nombre**: "Spa Demo"

### Usuarios
- **Admin**: `admin@eva.crm` / `password`
- **Specialist**: `yoga@eva.crm` / `password`

## Estructura del Proyecto

```
evaa_crm_umbrella/
├── apps/
│   ├── evaa_crm/           # Contexto principal (Business, User)
│   └── evaa_crm_web/       # Aplicación web (LiveViews, rutas)
├── config/                 # Configuraciones
├── priv/                   # Migraciones y seeds
└── assets/                 # CSS, JS, imágenes
```

## Módulos MVP

EvaCRM incluye los siguientes módulos como LiveViews:

- **Agenda** (`/agenda`) - Gestión de citas y eventos
- **CRM** (`/crm`) - Contactos y leads
- **Analytics** (`/analytics`) - KPIs y métricas
- **Billing** (`/billing`) - Facturación
- **Inventory** (`/inventory`) - Inventario
- **Cash Desk** (`/cash`) - Caja registradora
- **Employees** (`/employees`) - Empleados y comisiones

## Características

### Multi-negocio
- Cada `Business` puede tener múltiples `Users`
- Roles de usuario: admin, manager, specialist, employee
- Separación de datos por negocio

### Tema Light/Dark
- Toggle de tema en la barra lateral
- Preferencia guardada en localStorage
- Transiciones suaves entre temas

### Diseño estilo GitHub
- Barra lateral fija con iconos de navegación
- Navegación fluida entre módulos
- Diseño responsive y moderno

### Tecnologías
- **Backend**: Elixir + Phoenix + Ecto
- **Frontend**: LiveView + Tailwind CSS
- **Base de datos**: PostgreSQL
- **Arquitectura**: Umbrella project

## Acceso

Una vez iniciado el servidor, accede a:
- **URL**: http://localhost:4000
- **Dashboard**: Página principal con información del sistema
- **Navegación**: Barra lateral con iconos para todos los módulos

## Desarrollo

### Agregar nuevos módulos
1. Crear LiveView en `apps/evaa_crm_web/lib/evaa_crm_web/live/`
2. Agregar ruta en `apps/evaa_crm_web/lib/evaa_crm_web/router.ex`
3. Agregar icono en la barra lateral (`app.html.heex`)

### Agregar nuevos modelos
1. Crear migración: `mix ecto.gen.migration create_table_name`
2. Definir esquema en `apps/evaa_crm/lib/evaa_crm/`
3. Agregar contexto si es necesario

## Soporte

Para reportar bugs o solicitar características, crea un issue en el repositorio del proyecto. 