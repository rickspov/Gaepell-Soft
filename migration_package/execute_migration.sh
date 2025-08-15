#!/bin/bash

echo "🚀 INICIANDO MIGRACIÓN EVAA_CRM A HOSTGATOR..."
echo "================================================"

# Configuración
USER_HOME="/home2/oaswmjte"
APP_DIR="$USER_HOME/evaa_crm_gaepell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
if [ ! -f "hostgator_setup.sh" ]; then
    print_error "No se encontró hostgator_setup.sh. Ejecuta este script desde migration_package/"
    exit 1
fi

print_status "Verificando directorio actual: $(pwd)"
print_status "Usuario actual: $(whoami)"
print_status "Directorio home: $USER_HOME"

# Verificar que estamos en el directorio correcto del usuario
if [[ "$(pwd)" != "$USER_HOME"* ]]; then
    print_warning "No estamos en el directorio del usuario. Navegando a $USER_HOME..."
    cd "$USER_HOME"
fi

# Verificar que los archivos estén presentes
print_status "Verificando archivos de migración..."
if [ ! -f "hostgator_setup.sh" ]; then
    print_error "No se encontró hostgator_setup.sh en el directorio actual"
    print_status "Archivos disponibles:"
    ls -la
    exit 1
fi

print_success "Todos los archivos de migración están presentes"

# Dar permisos de ejecución
print_status "Configurando permisos de ejecución..."
chmod +x hostgator_setup.sh
chmod +x *.sh

print_success "Permisos configurados correctamente"

# Ejecutar el script principal
print_status "Ejecutando script de configuración automática..."
print_warning "Este proceso puede tomar varios minutos..."
print_warning "NO CIERRES LA TERMINAL durante la ejecución"

./hostgator_setup.sh

if [ $? -eq 0 ]; then
    print_success "✅ MIGRACIÓN COMPLETADA EXITOSAMENTE!"
    echo ""
    echo "🎉 TU SISTEMA EVAA_CRM ESTÁ LISTO EN:"
    echo "   http://crm.oas.wmj.temporary.site"
    echo ""
    echo "📋 PRÓXIMOS PASOS:"
    echo "   1. Verificar que el subdominio esté configurado"
    echo "   2. Probar la aplicación en el navegador"
    echo "   3. Configurar SSL/HTTPS si es necesario"
    echo ""
else
    print_error "❌ ERROR DURANTE LA MIGRACIÓN"
    echo ""
    echo "🔧 SOLUCIÓN:"
    echo "   1. Revisar los logs de error arriba"
    echo "   2. Verificar que PostgreSQL esté funcionando"
    echo "   3. Contactar soporte de HostGator si es necesario"
    echo ""
fi 