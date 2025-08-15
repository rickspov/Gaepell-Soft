#!/bin/bash

# 📦 Script para preparar despliegue en /admin
# Uso: ./prepare_admin_deployment.sh

set -e

echo "📦 Preparando despliegue EvaaCRM en /admin..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
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
    print_error "No se encontró mix.exs. Asegúrate de estar en el directorio raíz del proyecto."
    exit 1
fi

# Crear directorio temporal
TEMP_DIR="eva_crm_admin_temp"
print_status "📁 Creando directorio temporal: $TEMP_DIR"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copiar archivos necesarios
print_status "📋 Copiando archivos del proyecto..."

# Copiar estructura principal
cp -r apps "$TEMP_DIR/"
cp -r config "$TEMP_DIR/"
cp -r priv "$TEMP_DIR/"

# Copiar archivos de configuración
cp mix.exs "$TEMP_DIR/"
cp mix.lock "$TEMP_DIR/"

# Copiar archivos de documentación
cp README.md "$TEMP_DIR/"

# Crear archivo .env de ejemplo
print_status "⚙️ Creando archivo .env de ejemplo..."
cat > "$TEMP_DIR/.env.example" << 'EOF'
# Configuración de la aplicación
MIX_ENV=prod
SECRET_KEY_BASE=tu_secret_key_aqui
PHX_HOST=grupo-gaepell.com

# Base de datos
DATABASE_URL=mysql://eva_crm_user:contraseña@localhost/eva_crm_db

# Configuración del servidor
PORT=4000
EOF

# Crear archivo .htaccess para proxy reverso
print_status "🌐 Creando archivo .htaccess..."
cat > "$TEMP_DIR/.htaccess" << 'EOF'
RewriteEngine On

# Redirigir todas las peticiones a la aplicación Phoenix
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ http://localhost:4000/$1 [P,L]

# Headers necesarios para Phoenix LiveView
ProxyPassReverse / http://localhost:4000/
ProxyPreserveHost On

# Headers para WebSocket
RewriteCond %{HTTP:Upgrade} websocket [NC]
RewriteCond %{HTTP:Connection} upgrade [NC]
RewriteRule ^/?(.*) "ws://localhost:4000/$1" [P,L]
EOF

# Crear script de instalación
print_status "🔧 Creando script de instalación..."
cat > "$TEMP_DIR/install.sh" << 'EOF'
#!/bin/bash

# 🚀 Script de instalación para /admin
# Uso: ./install.sh

set -e

echo "🚀 Iniciando instalación de EVA CRM en /admin..."

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

# Verificar que .env existe
if [ ! -f ".env" ]; then
    print_error "Archivo .env no encontrado. Por favor:"
    echo "1. Copia .env.example a .env"
    echo "2. Edita .env con tus credenciales"
    echo "3. Ejecuta este script nuevamente"
    exit 1
fi

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

# Generar secret key base si no está configurado
if [ "$SECRET_KEY_BASE" = "tu_secret_key_aqui" ]; then
    print_warning "Generando nuevo SECRET_KEY_BASE..."
    NEW_SECRET=$(mix phx.gen.secret)
    sed -i "s/tu_secret_key_aqui/$NEW_SECRET/" .env
    export SECRET_KEY_BASE="$NEW_SECRET"
    print_success "SECRET_KEY_BASE generado y actualizado en .env"
fi

# Crear script de inicio
print_status "🔧 Creando script de inicio..."
cat > start_eva_crm.sh << 'SCRIPT_EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .env
mix phx.server
SCRIPT_EOF

chmod +x start_eva_crm.sh

print_success "✅ Instalación completada!"
echo ""
echo "🚀 Para iniciar la aplicación:"
echo "   ./start_eva_crm.sh"
echo ""
echo "📱 Para acceder a la aplicación:"
echo "   https://grupo-gaepell.com/admin/"
echo ""
echo "📖 Ver ADMIN_DEPLOYMENT_GUIDE.md para más detalles"
EOF

chmod +x "$TEMP_DIR/install.sh"

# Crear script de backup de base de datos
print_status "💾 Creando script de backup..."
cat > "$TEMP_DIR/backup_database.sh" << 'EOF'
#!/bin/bash

# 💾 Script de backup de base de datos
# Uso: ./backup_database.sh

set -e

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
mysqldump -h $DB_HOST -u $DB_USER -p $DB_NAME > $BACKUP_FILE

echo "✅ Backup creado exitosamente: $BACKUP_FILE"
echo "📏 Tamaño: $(du -h $BACKUP_FILE | cut -f1)"
EOF

chmod +x "$TEMP_DIR/backup_database.sh"

# Crear archivo ZIP
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIP_FILE="eva-crm-admin-$TIMESTAMP.zip"

print_status "📦 Creando archivo ZIP: $ZIP_FILE"
cd "$TEMP_DIR"
zip -r "../$ZIP_FILE" . -x "*.git*" "_build/*" "deps/*" "node_modules/*"
cd ..

# Limpiar directorio temporal
print_status "🧹 Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

# Mostrar información del archivo
print_success "✅ Archivo ZIP creado exitosamente!"
print_success "📦 Archivo: $ZIP_FILE"
print_success "📏 Tamaño: $(du -h "$ZIP_FILE" | cut -f1)"

echo ""
echo "🚀 INSTRUCCIONES PARA HOSTGATOR:"
echo "================================"
echo "1. 📤 Subir $ZIP_FILE a tu servidor Hostgator"
echo "2. 📁 Extraer en: public_html/admin/"
echo "3. ⚙️ Copiar .env.example a .env y configurar"
echo "4. 🔧 Ejecutar: ./install.sh"
echo "5. 🚀 Iniciar: ./start_eva_crm.sh"
echo ""
echo "📖 Ver ADMIN_DEPLOYMENT_GUIDE.md para instrucciones detalladas"
echo ""
echo "🌐 URL FINAL:"
echo "============="
echo "https://grupo-gaepell.com/admin/"
echo ""
echo "📱 FUNCIONALIDADES INCLUIDAS:"
echo "============================="
echo "✅ Login y autenticación"
echo "✅ Gestión de camiones"
echo "✅ Tickets de mantenimiento"
echo "✅ Sistema de fotos"
echo "✅ Wizard de tickets"
echo "✅ Todos los datos preservados"

print_success "🎉 ¡Archivo listo para subir a Hostgator en /admin!" 