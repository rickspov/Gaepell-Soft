#!/bin/bash

# Script para empaquetar todo el paquete de migración
# Ejecutar desde el directorio raíz del proyecto

echo "📦 Empaquetando paquete de migración EvaaCRM..."

# Configuración
PACKAGE_NAME="evaa_crm_gaepell_migration_$(date +%Y%m%d_%H%M%S)"
PACKAGE_DIR="migration_package"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "📋 Nombre del paquete: $PACKAGE_NAME"
echo "📁 Directorio de migración: $PACKAGE_DIR"
echo "🕐 Timestamp: $TIMESTAMP"

# Verificar que exista el directorio de migración
if [ ! -d "$PACKAGE_DIR" ]; then
    echo "❌ Error: No se encontró el directorio $PACKAGE_DIR"
    exit 1
fi

# Verificar archivos críticos
echo "🔍 Verificando archivos críticos..."

CRITICAL_FILES=(
    "MIGRATION_GUIDE.md"
    "hostgator_setup.sh"
    "nginx_config.conf"
    "systemd_service.conf"
    "environment_vars.env"
    "create_backup.sh"
    "README.md"
    "evaa_crm_gaepell"
    "database_backup.sql"
)

MISSING_FILES=()

for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -e "$PACKAGE_DIR/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ Archivos faltantes:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    exit 1
fi

echo "✅ Todos los archivos críticos están presentes"

# Crear archivo de checksums para verificación
echo "🔐 Generando checksums de verificación..."
cd "$PACKAGE_DIR"
find . -type f -exec sha256sum {} \; > checksums.sha256
cd ..

# Crear archivo de información del paquete
echo "📝 Creando archivo de información del paquete..."
cat > "$PACKAGE_DIR/PACKAGE_INFO.txt" << EOF
PAQUETE DE MIGRACIÓN EVAA_CRM_GAEPELL
=====================================

Fecha de Creación: $(date)
Versión del Sistema: EvaaCRM Gaepell v0.1.0
Entorno Origen: Desarrollo Local
Entorno Destino: HostGator
Subdominio Objetivo: crm.tudominio.com

ARCHIVOS INCLUIDOS:
==================

Documentación:
- MIGRATION_GUIDE.md: Guía completa de migración
- README.md: Información del paquete
- PACKAGE_INFO.txt: Este archivo

Scripts de Configuración:
- hostgator_setup.sh: Configuración automática para HostGator
- create_backup.sh: Script para crear backups de BD

Configuraciones del Sistema:
- nginx_config.conf: Configuración de Nginx optimizada
- systemd_service.conf: Configuración del servicio del sistema
- environment_vars.env: Variables de entorno de ejemplo

Aplicación y Datos:
- evaa_crm_gaepell/: Release compilado de la aplicación
- database_backup.sql: Backup de la base de datos actual

Verificación:
- checksums.sha256: Checksums de todos los archivos

INSTRUCCIONES RÁPIDAS:
=====================

1. Subir todo el contenido de este directorio a HostGator
2. Ejecutar: chmod +x hostgator_setup.sh
3. Ejecutar: ./hostgator_setup.sh
4. Configurar subdominio 'crm' en el panel de HostGator
5. Probar en: http://crm.tudominio.com

VERIFICACIÓN DE INTEGRIDAD:
==========================

Para verificar que no se corrompieron los archivos durante la transferencia:

cd /ruta/a/migration_package
sha256sum -c checksums.sha256

Todos los archivos deben mostrar "OK".

CONTACTO Y SOPORTE:
===================

Si tienes problemas durante la migración:
1. Revisar logs: sudo journalctl -u evaa_crm_gaepell -f
2. Verificar estado: sudo systemctl status evaa_crm_gaepell
3. Contactar al equipo de desarrollo con los logs de error

¡BUENA SUERTE CON LA MIGRACIÓN!
EOF

# Crear archivo de verificación de tamaño
echo "📏 Generando información de tamaños..."
cd "$PACKAGE_DIR"
echo "INFORMACIÓN DE TAMAÑOS:" > SIZES.txt
echo "======================" >> SIZES.txt
echo "" >> SIZES.txt
du -sh * >> SIZES.txt
echo "" >> SIZES.txt
echo "TOTAL DEL PAQUETE:" >> SIZES.txt
du -sh . >> SIZES.txt
cd ..

# Crear archivo de instrucciones de transferencia
echo "📤 Creando instrucciones de transferencia..."
cat > "$PACKAGE_DIR/TRANSFER_INSTRUCTIONS.md" << EOF
# 📤 Instrucciones de Transferencia a HostGator

## 🚀 **Opción 1: Transferencia via SSH (Recomendado)**

### **Desde tu máquina local:**
\`\`\`bash
# Conectar y transferir
scp -r migration_package/ usuario@tu-servidor:/home/usuario/

# Verificar la transferencia
ssh usuario@tu-servidor
cd migration_package
ls -la
\`\`\`

## 📁 **Opción 2: Transferencia via FTP/SFTP**

### **Usando FileZilla o similar:**
1. Conectar a tu servidor HostGator via FTP
2. Navegar a tu directorio raíz (ej: `/home/usuario/`)
3. Subir **todo el contenido** de la carpeta `migration_package/`
4. **NO subir la carpeta `migration_package/` en sí, sino su contenido**

### **Estructura correcta en el servidor:**
\`\`\`
/home/usuario/
├── MIGRATION_GUIDE.md
├── hostgator_setup.sh
├── nginx_config.conf
├── systemd_service.conf
├── environment_vars.env
├── create_backup.sh
├── README.md
├── PACKAGE_INFO.txt
├── SIZES.txt
├── checksums.sha256
├── evaa_crm_gaepell/
└── database_backup.sql
\`\`\`

## ✅ **Verificación de la Transferencia**

### **1. Verificar archivos transferidos:**
\`\`\`bash
ls -la
\`\`\`

### **2. Verificar integridad (si usaste SSH):**
\`\`\`bash
sha256sum -c checksums.sha256
\`\`\`

### **3. Verificar tamaños:**
\`\`\`bash
cat SIZES.txt
\`\`\`

## 🚨 **Problemas Comunes**

### **Error: Permisos denegados**
\`\`\`bash
chmod +x hostgator_setup.sh
chmod +x create_backup.sh
\`\`\`

### **Error: Archivos corruptos**
- Reintentar la transferencia
- Verificar espacio en disco en el servidor
- Usar modo binario en FTP

### **Error: Conexión interrumpida**
- Usar conexión estable
- Transferir archivos por separado si es necesario
- Verificar configuración de firewall

## 🎯 **Próximos Pasos Después de la Transferencia**

1. **Ejecutar configuración automática:**
   \`\`\`bash
   ./hostgator_setup.sh
   \`\`\`

2. **Configurar subdominio en HostGator**

3. **Probar la aplicación**

## 📞 **Soporte**

Si tienes problemas con la transferencia:
- Verificar conectividad al servidor
- Verificar permisos de usuario
- Contactar soporte de HostGator
EOF

# Mostrar resumen final
echo ""
echo "🎉 ¡Paquete de migración empaquetado exitosamente!"
echo ""
echo "📋 Resumen del paquete:"
echo "   • Directorio: $PACKAGE_DIR/"
echo "   • Archivos incluidos: $(find $PACKAGE_DIR -type f | wc -l)"
echo "   • Tamaño total: $(du -sh $PACKAGE_DIR | cut -f1)"
echo "   • Checksums: $PACKAGE_DIR/checksums.sha256"
echo "   • Información: $PACKAGE_DIR/PACKAGE_INFO.txt"
echo "   • Tamaños: $PACKAGE_DIR/SIZES.txt"
echo "   • Instrucciones: $PACKAGE_DIR/TRANSFER_INSTRUCTIONS.md"
echo ""
echo "🚀 El paquete está listo para transferir a HostGator"
echo ""
echo "📤 Para transferir via SSH:"
echo "   scp -r $PACKAGE_DIR/ usuario@tu-servidor:/home/usuario/"
echo ""
echo "📁 Para transferir via FTP:"
echo "   Subir todo el contenido de $PACKAGE_DIR/ (no la carpeta en sí)"
echo ""
echo "✅ Después de transferir, ejecutar:"
echo "   chmod +x hostgator_setup.sh"
echo "   ./hostgator_setup.sh" 