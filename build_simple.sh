#!/bin/bash

# 🚀 Script de Build Simple para Producción - EVA CRM
# Uso: ./build_simple.sh

set -e  # Exit on any error

echo "🔧 Iniciando build simple de producción..."

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

# Limpiar builds anteriores
print_status "🧹 Limpiando builds anteriores..."
mix deps.clean --all
mix clean

# Obtener dependencias
print_status "📦 Obteniendo dependencias..."
MIX_ENV=prod mix deps.get

# Compilar
print_status "🔨 Compilando aplicación..."
MIX_ENV=prod mix compile

# Compilar assets manualmente
print_status "🎨 Compilando assets..."
cd apps/evaa_crm_web_gaepell/assets

# Compilar CSS con Tailwind
print_status "🎨 Compilando CSS..."
npx tailwindcss -i css/app.css -o ../priv/static/assets/app.css --minify

# Compilar JS con esbuild
print_status "🔧 Compilando JavaScript..."
npx esbuild js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*

# Copiar archivos PWA
print_status "📱 Copiando archivos PWA..."
cp js/pwa.js ../priv/static/assets/
cp js/offline-sync.js ../priv/static/assets/

cd ../../

# Generar secret key base si no existe
if [ -z "$SECRET_KEY_BASE" ]; then
    print_warning "SECRET_KEY_BASE no está configurado. Generando uno nuevo..."
    export SECRET_KEY_BASE=$(mix phx.gen.secret)
    echo "SECRET_KEY_BASE=$SECRET_KEY_BASE" > .env.prod
    print_success "Secret key base generado y guardado en .env.prod"
fi

# Crear release
print_status "📦 Creando release..."
MIX_ENV=prod mix release

# Crear archivo de despliegue
print_status "📁 Creando archivo de despliegue..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_FILE="eva-crm-deploy-$TIMESTAMP.tar.gz"

tar -czf "$DEPLOY_FILE" \
    _build/prod/rel/evaa_crm_gaepell/ \
    config/prod.exs \
    .env.prod \
    DEPLOYMENT_GUIDE.md

print_success "✅ Build completado exitosamente!"
print_success "📦 Archivo de despliegue: $DEPLOY_FILE"
print_success "📏 Tamaño: $(du -h "$DEPLOY_FILE" | cut -f1)"

# Mostrar información de despliegue
echo ""
echo "🚀 INFORMACIÓN DE DESPLIEGUE:"
echo "=============================="
echo "📦 Archivo: $DEPLOY_FILE"
echo "📁 Contenido:"
echo "   - Release de la aplicación"
echo "   - Configuración de producción"
echo "   - Variables de entorno"
echo "   - Guía de despliegue"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Subir $DEPLOY_FILE al servidor"
echo "2. Extraer en el directorio de destino"
echo "3. Configurar variables de entorno"
echo "4. Ejecutar migraciones de base de datos"
echo "5. Iniciar la aplicación"
echo ""
echo "📖 Ver DEPLOYMENT_GUIDE.md para instrucciones detalladas"

# Verificar que el release se creó correctamente
if [ -d "_build/prod/rel/evaa_crm_gaepell" ]; then
    print_success "✅ Release creado correctamente en _build/prod/rel/evaa_crm_gaepell/"
else
    print_error "❌ Error: No se pudo crear el release"
    exit 1
fi

echo ""
print_success "🎉 ¡Build de producción completado!" 