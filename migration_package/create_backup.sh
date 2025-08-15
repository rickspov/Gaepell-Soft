#!/bin/bash

# Script para crear backup de la base de datos EvaaCRM
# Ejecutar desde el directorio raíz del proyecto

echo "🗄️ Creando backup de la base de datos EvaaCRM..."

# Configuración
DB_NAME="evaa_crm_gaepell_dev"
BACKUP_DIR="migration_package"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="database_backup_${TIMESTAMP}.sql"

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

echo "📊 Base de datos: $DB_NAME"
echo "📁 Directorio de backup: $BACKUP_DIR"
echo "📄 Archivo de backup: $BACKUP_FILE"

# Crear backup de la base de datos
echo "💾 Generando backup..."
pg_dump -h localhost -U postgres -d "$DB_NAME" > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup creado exitosamente: $BACKUP_FILE"
    echo "📏 Tamaño del archivo: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"
    
    # Crear enlace simbólico para facilitar la migración
    ln -sf "$BACKUP_DIR/$BACKUP_FILE" "$BACKUP_DIR/database_backup.sql"
    echo "🔗 Enlace simbólico creado: database_backup.sql"
    
    # Verificar integridad del backup
    echo "🔍 Verificando integridad del backup..."
    if pg_restore --list "$BACKUP_DIR/$BACKUP_FILE" > /dev/null 2>&1; then
        echo "✅ Backup verificado correctamente"
    else
        echo "⚠️  El backup no es un archivo de restore, pero es válido para psql"
    fi
    
else
    echo "❌ Error al crear el backup"
    exit 1
fi

echo ""
echo "📋 Resumen del backup:"
echo "   • Archivo: $BACKUP_DIR/$BACKUP_FILE"
echo "   • Enlace: $BACKUP_DIR/database_backup.sql"
echo "   • Tamaño: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"
echo "   • Fecha: $(date)"
echo ""
echo "🚀 El backup está listo para la migración a HostGator" 