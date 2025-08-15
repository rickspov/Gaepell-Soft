# 🚀 Paquete de Migración EvaaCRM a HostGator

## 📦 **Contenido del Paquete**

Este directorio contiene todo lo necesario para migrar tu sistema EvaaCRM desde tu entorno de desarrollo local a HostGator como subdominio.

### **Archivos Incluidos:**

- **`MIGRATION_GUIDE.md`** - Guía completa paso a paso de la migración
- **`hostgator_setup.sh`** - Script de configuración automática para HostGator
- **`nginx_config.conf`** - Configuración de Nginx optimizada
- **`systemd_service.conf`** - Configuración del servicio del sistema
- **`environment_vars.env`** - Variables de entorno de ejemplo
- **`create_backup.sh`** - Script para crear backups de la base de datos
- **`evaa_crm_gaepell/`** - Release compilado de la aplicación
- **`database_backup.sql`** - Backup de tu base de datos actual

## 🎯 **Objetivos de la Migración**

✅ **Migrar la aplicación completa** con todos los cambios recientes  
✅ **Preservar la base de datos** con todos los datos existentes  
✅ **Configurar como subdominio** en HostGator  
✅ **Mantener funcionalidad completa** del sistema  

## 🚀 **Pasos Rápidos para la Migración**

### **1. Subir el Paquete a HostGator**
```bash
# Via SSH (recomendado)
scp -r migration_package/ usuario@tu-servidor:/home/usuario/

# Via FTP/SFTP
# Subir todo el contenido de migration_package/ a tu directorio raíz
```

### **2. Ejecutar Configuración Automática**
```bash
# Conectarse a HostGator
ssh usuario@tu-servidor

# Navegar al directorio
cd migration_package

# Dar permisos y ejecutar
chmod +x hostgator_setup.sh
./hostgator_setup.sh
```

### **3. Configurar Subdominio**
- En el panel de HostGator: **Domains** → **Subdomains**
- Crear subdominio: `crm`
- Apuntar al directorio: `/home/usuario/evaa_crm_gaepell`

### **4. Probar la Aplicación**
- Abrir: `http://crm.tudominio.com`
- Verificar login y funcionalidades

## 📋 **Requisitos Previos en HostGator**

- ✅ Acceso SSH con permisos sudo
- ✅ Base de datos PostgreSQL disponible
- ✅ Dominio principal configurado
- ✅ Puerto 4000 disponible

## 🔧 **Comandos Útiles Después de la Migración**

```bash
# Ver estado del servicio
/home/usuario/evaa_crm_gaepell/manage.sh status

# Ver logs en tiempo real
/home/usuario/evaa_crm_gaepell/manage.sh logs

# Reiniciar la aplicación
/home/usuario/evaa_crm_gaepell/manage.sh restart

# Crear backup de la base de datos
/home/usuario/evaa_crm_gaepell/manage.sh backup
```

## 🚨 **Solución de Problemas**

### **Error: Puerto 4000 en uso**
```bash
sudo netstat -tlnp | grep :4000
sudo kill -9 PID_DEL_PROCESO
```

### **Error: Base de datos no conecta**
```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

### **Error: Permisos de archivos**
```bash
sudo chown -R usuario:usuario /home/usuario/evaa_crm_gaepell
sudo chmod -R 755 /home/usuario/evaa_crm_gaepell
```

## 📞 **Soporte**

Si encuentras problemas durante la migración:

1. **Revisar logs**: `sudo journalctl -u evaa_crm_gaepell -f`
2. **Verificar estado**: `sudo systemctl status evaa_crm_gaepell`
3. **Contactar al equipo de desarrollo** con los logs de error

## 🎉 **¡Migración Completada!**

Una vez completada la migración, tendrás:

- 🌐 **Aplicación web funcional** en `https://crm.tudominio.com`
- 🗄️ **Base de datos completa** con todos los datos
- ✨ **Funcionalidades actualizadas** (campos de entregador simplificados)
- 🔐 **Sistema de autenticación** funcionando
- 🚛 **Gestión de camiones y tickets** operativa
- 🔧 **Sistema de mantenimiento** completo

---

**Versión del Sistema**: EvaaCRM Gaepell v0.1.0  
**Fecha de Migración**: $(date)  
**Entorno Destino**: HostGator  
**Subdominio**: crm.tudominio.com 