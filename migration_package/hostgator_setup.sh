#!/bin/bash

# 🚀 Script de Configuración Automática EvaaCRM para HostGator
# Este script configura automáticamente el entorno para ejecutar EvaaCRM

set -e  # Salir si hay algún error

echo "🚀 Iniciando configuración automática de EvaaCRM para HostGator..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
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

# Verificar si se está ejecutando como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script no debe ejecutarse como root"
   exit 1
fi

# Obtener el directorio actual
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="/home2/oaswmjte"
APP_DIR="$USER_HOME/evaa_crm_gaepell"

print_status "Directorio del script: $SCRIPT_DIR"
print_status "Directorio del usuario: $USER_HOME"
print_status "Directorio de la aplicación: $APP_DIR"

# Paso 1: Instalar dependencias del sistema
print_status "Instalando dependencias del sistema..."

# Actualizar repositorios
sudo apt-get update

# Instalar dependencias necesarias
sudo apt-get install -y \
    postgresql \
    postgresql-contrib \
    nginx \
    curl \
    wget \
    unzip \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev

print_success "Dependencias del sistema instaladas"

# Paso 2: Configurar PostgreSQL
print_status "Configurando PostgreSQL..."

# Crear usuario de base de datos si no existe
sudo -u postgres psql -c "CREATE USER $USER WITH PASSWORD 'evaa_crm_password';" 2>/dev/null || print_warning "Usuario ya existe"
sudo -u postgres psql -c "ALTER USER $USER CREATEDB;" 2>/dev/null || print_warning "Permisos ya configurados"

# Crear base de datos si no existe
sudo -u postgres createdb -O $USER evaa_crm_gaepell 2>/dev/null || print_warning "Base de datos ya existe"

print_success "PostgreSQL configurado"

# Paso 3: Extraer y configurar la aplicación
print_status "Configurando la aplicación EvaaCRM..."

# Crear directorio de la aplicación
mkdir -p "$APP_DIR"

# Extraer el release si existe
if [ -f "$SCRIPT_DIR/evaa_crm_gaepell_release.tar.gz" ]; then
    print_status "Extrayendo release de la aplicación..."
    tar -xzf "$SCRIPT_DIR/evaa_crm_gaepell_release.tar.gz" -C "$APP_DIR"
    print_success "Release extraído"
else
    print_warning "No se encontró el release, creando estructura básica..."
    mkdir -p "$APP_DIR/bin" "$APP_DIR/releases" "$APP_DIR/lib"
fi

# Paso 4: Configurar variables de entorno
print_status "Configurando variables de entorno..."

cat > "$APP_DIR/env.sh" << EOF
#!/bin/bash
export MIX_ENV=prod
export PORT=4000
export DATABASE_URL=postgresql://$USER:evaa_crm_password@localhost/evaa_crm_gaepell
export SECRET_KEY_BASE=$(openssl rand -base64 64)
export PHX_HOST=crm.oas.wmj.temporary.site
export PHX_SERVER=true
EOF

chmod +x "$APP_DIR/env.sh"
print_success "Variables de entorno configuradas"

# Paso 5: Configurar Nginx
print_status "Configurando Nginx..."

sudo tee /etc/nginx/sites-available/evaa_crm_gaepell > /dev/null << EOF
server {
    listen 80;
    server_name crm.tudominio.com;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /uploads/ {
        alias $APP_DIR/priv/static/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /assets/ {
        alias $APP_DIR/priv/static/assets/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar el sitio
sudo ln -sf /etc/nginx/sites-available/evaa_crm_gaepell /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
sudo nginx -t
sudo systemctl restart nginx

print_success "Nginx configurado"

# Paso 6: Configurar servicio del sistema
print_status "Configurando servicio del sistema..."

sudo tee /etc/systemd/system/evaa_crm_gaepell.service > /dev/null << EOF
[Unit]
Description=EvaaCRM Gaepell Application
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/env.sh
ExecStart=$APP_DIR/bin/evaa_crm_gaepell start
ExecStop=$APP_DIR/bin/evaa_crm_gaepell stop
ExecReload=$APP_DIR/bin/evaa_crm_gaepell restart
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=evaa_crm_gaepell

[Install]
WantedBy=multi-user.target
EOF

# Recargar configuración del sistema
sudo systemctl daemon-reload

# Habilitar el servicio
sudo systemctl enable evaa_crm_gaepell

print_success "Servicio del sistema configurado"

# Paso 7: Configurar firewall (si es necesario)
print_status "Configurando firewall..."

# Permitir puertos HTTP y HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp

print_success "Firewall configurado"

# Paso 8: Crear script de gestión
print_status "Creando script de gestión..."

cat > "$APP_DIR/manage.sh" << 'EOF'
#!/bin/bash

# Script de gestión para EvaaCRM
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
    start)
        echo "🚀 Iniciando EvaaCRM..."
        sudo systemctl start evaa_crm_gaepell
        ;;
    stop)
        echo "🛑 Deteniendo EvaaCRM..."
        sudo systemctl stop evaa_crm_gaepell
        ;;
    restart)
        echo "🔄 Reiniciando EvaaCRM..."
        sudo systemctl restart evaa_crm_gaepell
        ;;
    status)
        echo "📊 Estado de EvaaCRM..."
        sudo systemctl status evaa_crm_gaepell
        ;;
    logs)
        echo "📝 Mostrando logs de EvaaCRM..."
        sudo journalctl -u evaa_crm_gaepell -f
        ;;
    backup)
        echo "💾 Creando backup de la base de datos..."
        pg_dump -h localhost -U $USER -d evaa_crm_gaepell > backup_$(date +%Y%m%d_%H%M%S).sql
        echo "Backup creado: backup_$(date +%Y%m%d_%H%M%S).sql"
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|backup}"
        echo ""
        echo "Comandos disponibles:"
        echo "  start   - Iniciar la aplicación"
        echo "  stop    - Detener la aplicación"
        echo "  restart - Reiniciar la aplicación"
        echo "  status  - Ver estado del servicio"
        echo "  logs    - Ver logs en tiempo real"
        echo "  backup  - Crear backup de la base de datos"
        exit 1
        ;;
esac
EOF

chmod +x "$APP_DIR/manage.sh"

print_success "Script de gestión creado"

# Paso 9: Configurar permisos
print_status "Configurando permisos..."

sudo chown -R $USER:$USER "$APP_DIR"
chmod -R 755 "$APP_DIR"

print_success "Permisos configurados"

# Paso 10: Iniciar el servicio
print_status "Iniciando el servicio EvaaCRM..."

sudo systemctl start evaa_crm_gaepell

# Esperar un momento para que el servicio se inicie
sleep 5

# Verificar estado del servicio
if sudo systemctl is-active --quiet evaa_crm_gaepell; then
    print_success "Servicio EvaaCRM iniciado correctamente"
else
    print_error "Error al iniciar el servicio EvaaCRM"
    sudo systemctl status evaa_crm_gaepell
    exit 1
fi

# Paso 11: Verificación final
print_status "Realizando verificación final..."

# Verificar que el puerto esté escuchando
if netstat -tlnp | grep -q ":4000"; then
    print_success "Puerto 4000 está escuchando"
else
    print_warning "Puerto 4000 no está escuchando"
fi

# Verificar que Nginx esté funcionando
if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx está funcionando"
else
    print_warning "Nginx no está funcionando"
fi

# Verificar que PostgreSQL esté funcionando
if sudo systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL está funcionando"
else
    print_warning "PostgreSQL no está funcionando"
fi

echo ""
echo "🎉 ¡Configuración completada exitosamente!"
echo ""
echo "📋 Resumen de la instalación:"
echo "   • Aplicación instalada en: $APP_DIR"
echo "   • Servicio del sistema: evaa_crm_gaepell"
echo "   • Puerto de la aplicación: 4000"
echo "   • Configuración de Nginx: /etc/nginx/sites-available/evaa_crm_gaepell"
echo "   • Variables de entorno: $APP_DIR/env.sh"
echo "   • Script de gestión: $APP_DIR/manage.sh"
echo ""
echo "🚀 Comandos útiles:"
echo "   • Ver estado: $APP_DIR/manage.sh status"
echo "   • Ver logs: $APP_DIR/manage.sh logs"
echo "   • Reiniciar: $APP_DIR/manage.sh restart"
echo "   • Crear backup: $APP_DIR/manage.sh backup"
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Configurar el subdominio 'crm' en tu panel de HostGator"
echo "   2. Apuntar el subdominio al directorio: $APP_DIR"
echo "   3. Configurar SSL/HTTPS si es necesario"
echo "   4. Probar la aplicación en: http://crm.tudominio.com"
echo ""
echo "📞 Si tienes problemas, revisa los logs con:"
echo "   sudo journalctl -u evaa_crm_gaepell -f"
echo "" 