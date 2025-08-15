#!/bin/bash

# 🚀 Script para preparar despliegue con Release
# Uso: ./prepare_release_deployment.sh

set -e

echo "🚀 Preparando despliegue con Release de EvaaCRM..."

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

# Verificar que el release existe
if [ ! -d "_build/prod/rel/evaa_crm_gaepell" ]; then
    print_error "No se encontró el release. Ejecuta 'MIX_ENV=prod mix release' primero."
    exit 1
fi

# Crear directorio temporal
TEMP_DIR="release_deployment_$(date +%Y%m%d_%H%M%S)"
print_status "📦 Creando directorio temporal: $TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copiar el release
print_status "📋 Copiando release..."
cp -r _build/prod/rel/evaa_crm_gaepell "$TEMP_DIR/"

# Crear archivo .env
print_status "⚙️ Creando archivo .env..."
cat > "$TEMP_DIR/.env" << 'EOF'
# Configuración de EvaaCRM para Hostgator
MIX_ENV=prod
SECRET_KEY_BASE=tu_secret_key_aqui
PHX_HOST=grupogaepell.com

# Base de datos (con la contraseña que usaste)
DATABASE_URL=mysql://eva_crm_user:EvaCrm2025!@localhost/eva_crm_db

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

# Crear script de inicio
print_status "🔧 Creando script de inicio..."
cat > "$TEMP_DIR/start_eva_crm.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

# Cargar variables de entorno
source .env

# Generar secret key base si no existe
if [ "$SECRET_KEY_BASE" = "tu_secret_key_aqui" ]; then
    echo "🔑 Generando SECRET_KEY_BASE..."
    NEW_SECRET=$(./evaa_crm_gaepell/bin/evaa_crm_gaepell eval "IO.puts(Base.encode64(:crypto.strong_rand_bytes(64)))")
    sed -i "s/tu_secret_key_aqui/$NEW_SECRET/" .env
    export SECRET_KEY_BASE="$NEW_SECRET"
    echo "✅ SECRET_KEY_BASE generado y actualizado en .env"
fi

# Ejecutar migraciones
echo "🗄️ Ejecutando migraciones..."
./evaa_crm_gaepell/bin/evaa_crm_gaepell eval "EvaaCrmGaepell.Release.migrate"

# Iniciar la aplicación
echo "🚀 Iniciando EvaaCRM..."
./evaa_crm_gaepell/bin/evaa_crm_gaepell start
EOF

chmod +x "$TEMP_DIR/start_eva_crm.sh"

# Crear script de backup
print_status "💾 Creando script de backup..."
cat > "$TEMP_DIR/backup_database.sh" << 'EOF'
#!/bin/bash

# 💾 Script de backup de base de datos
echo "💾 Creando backup de la base de datos..."

# Cargar variables de entorno
source .env

# Extraer información de la base de datos
DB_NAME=$(echo $DATABASE_URL | sed 's/.*\///')
DB_USER=$(echo $DATABASE_URL | sed 's/.*:\/\/\([^:]*\):.*/\1/')
DB_HOST=$(echo $DATABASE_URL | sed 's/.*@\([^:]*\):.*/\1/')
DB_PASSWORD=$(echo $DATABASE_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/')

# Crear backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="database_backup_$TIMESTAMP.sql"

echo "📦 Creando backup: $BACKUP_FILE"
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE

echo "✅ Backup creado exitosamente: $BACKUP_FILE"
echo "📏 Tamaño: $(du -h $BACKUP_FILE | cut -f1)"
EOF

chmod +x "$TEMP_DIR/backup_database.sh"

# Crear script de instalación
print_status "📋 Creando script de instalación..."
cat > "$TEMP_DIR/install.sh" << 'EOF'
#!/bin/bash

# 🚀 Script de instalación EvaaCRM con Release
echo "🚀 Iniciando instalación de EvaaCRM con Release..."

# Verificar que estamos en el directorio correcto
if [ ! -f "start_eva_crm.sh" ]; then
    echo "❌ No se encontró start_eva_crm.sh. Asegúrate de estar en el directorio correcto."
    exit 1
fi

# Dar permisos de ejecución
chmod +x start_eva_crm.sh
chmod +x backup_database.sh
chmod +x evaa_crm_gaepell/bin/evaa_crm_gaepell

# Crear directorio de logs
mkdir -p logs

# Ejecutar migraciones y iniciar
echo "🗄️ Ejecutando migraciones..."
./evaa_crm_gaepell/bin/evaa_crm_gaepell eval "EvaaCrmGaepell.Release.migrate"

echo "✅ Instalación completada!"
echo ""
echo "🚀 Para iniciar la aplicación:"
echo "   ./start_eva_crm.sh"
echo ""
echo "📱 Para acceder a la aplicación:"
echo "   https://grupogaepell.com/admin/"
echo ""
echo "💾 Para crear backup de la base de datos:"
echo "   ./backup_database.sh"
EOF

chmod +x "$TEMP_DIR/install.sh"

# Crear README
print_status "📖 Creando README..."
cat > "$TEMP_DIR/README.md" << 'EOF'
# 🚀 EvaaCRM - Despliegue con Release

## 📋 Instalación

1. **Ejecutar instalación:**
   ```bash
   ./install.sh
   ```

2. **Iniciar la aplicación:**
   ```bash
   ./start_eva_crm.sh
   ```

3. **Acceder a la aplicación:**
   ```
   https://grupogaepell.com/admin/
   ```

## 🔧 Comandos Útiles

- **Iniciar aplicación:** `./start_eva_crm.sh`
- **Crear backup:** `./backup_database.sh`
- **Ver logs:** `tail -f logs/evaa_crm.log`

## 📁 Estructura

- `evaa_crm_gaepell/` - Release de la aplicación
- `.env` - Variables de entorno
- `.htaccess` - Configuración de proxy reverso
- `start_eva_crm.sh` - Script de inicio
- `backup_database.sh` - Script de backup
- `install.sh` - Script de instalación

## 🗄️ Base de Datos

- **Usuario:** `eva_crm_user`
- **Base de datos:** `eva_crm_db`
- **Contraseña:** `EvaCrm2025!`
- **Host:** `localhost`
EOF

# Crear ZIP
ZIP_FILE="evaa-crm-release-$(date +%Y%m%d_%H%M%S).zip"
print_status "📦 Creando archivo ZIP: $ZIP_FILE"
cd "$TEMP_DIR"
zip -r "../$ZIP_FILE" . -x "*.git*" "*.DS_Store"
cd ..

# Limpiar directorio temporal
print_status "🧹 Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

print_success "✅ Despliegue preparado exitosamente!"
echo ""
echo "📦 Archivo creado: $ZIP_FILE"
echo ""
echo "📋 Próximos pasos:"
echo "1. Subir $ZIP_FILE al servidor"
echo "2. Descomprimir en public_html/admin/"
echo "3. Ejecutar ./install.sh"
echo "4. Ejecutar ./start_eva_crm.sh"
echo ""
echo "🌐 URL final: https://grupogaepell.com/admin/" 