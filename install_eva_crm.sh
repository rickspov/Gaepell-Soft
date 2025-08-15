#!/bin/bash

# 🚀 Script de instalación EvaaCRM para Hostgator
# Uso: ./install_eva_crm.sh

set -e

echo "🚀 Iniciando instalación de EVA CRM en Hostgator..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "mix.exs" ]; then
    print_error "No se encontró mix.exs. Asegúrate de estar en el directorio de EvaaCRM."
    exit 1
fi

# Crear archivo .env con la configuración específica
print_status "⚙️ Creando archivo .env..."
cat > .env << 'EOF'
# Configuración de EvaaCRM para Hostgator
MIX_ENV=prod
SECRET_KEY_BASE=tu_secret_key_aqui
PHX_HOST=grupogaepell.com

# Base de datos (con la contraseña que usaste)
DATABASE_URL=mysql://eva_crm_user:EvaCrm2025!@localhost/eva_crm_db

# Configuración del servidor
PORT=4000
EOF

print_success "✅ Archivo .env creado con la configuración de tu base de datos"

# Cargar variables de entorno
print_status "📋 Cargando variables de entorno..."
source .env

# Instalar dependencias
print_status "📦 Instalando dependencias..."
mix deps.get

# Ejecutar migraciones
print_status "🗄️ Ejecutando migraciones de base de datos..."
mix ecto.migrate

# Compilar assets
print_status "🎨 Compilando assets..."
cd apps/evaa_crm_web_gaepell/assets

# Compilar CSS con Tailwind
npx tailwindcss -i css/app.css -o ../priv/static/assets/app.css --minify

# Compilar JS con esbuild
npx esbuild js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*

cd ../../

# Generar secret key base
print_status "🔑 Generando SECRET_KEY_BASE..."
NEW_SECRET=$(mix phx.gen.secret)
sed -i "s/tu_secret_key_aqui/$NEW_SECRET/" .env
export SECRET_KEY_BASE="$NEW_SECRET"
print_success "✅ SECRET_KEY_BASE generado y actualizado en .env"

# Crear script de inicio
print_status "🔧 Creando script de inicio..."
cat > start_eva_crm.sh << 'SCRIPT_EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .env
mix phx.server
SCRIPT_EOF

chmod +x start_eva_crm.sh

# Crear script de backup
print_status "💾 Creando script de backup..."
cat > backup_database.sh << 'BACKUP_EOF'
#!/bin/bash

# 💾 Script de backup de base de datos
echo "💾 Creando backup de la base de datos..."

# Cargar variables de entorno
source .env

# Extraer información de la base de datos
DB_NAME=$(echo $DATABASE_URL | sed 's/.*\///')
DB_USER=$(echo $DATABASE_URL | sed 's/.*:\/\/\([^:]*\):.*/\1/')
DB_HOST=$(echo $DATABASE_URL | sed 's/.*@\([^:]*\):.*/\1/')

# Crear backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="database_backup_$TIMESTAMP.sql"

echo "📦 Creando backup: $BACKUP_FILE"
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE

echo "✅ Backup creado exitosamente: $BACKUP_FILE"
echo "📏 Tamaño: $(du -h $BACKUP_FILE | cut -f1)"
BACKUP_EOF

chmod +x backup_database.sh

print_success "✅ Instalación completada!"
echo ""
echo "🚀 Para iniciar la aplicación:"
echo "   ./start_eva_crm.sh"
echo ""
echo "📱 Para acceder a la aplicación:"
echo "   https://grupogaepell.com/admin/"
echo ""
echo "💾 Para crear backup de la base de datos:"
echo "   ./backup_database.sh"
echo ""
echo "📖 Configuración de base de datos:"
echo "   Usuario: eva_crm_user"
echo "   Base de datos: eva_crm_db"
echo "   Contraseña: EvaCrm2025!" 