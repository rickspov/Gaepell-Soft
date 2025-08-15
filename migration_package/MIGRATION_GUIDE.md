# 🚀 Guía de Migración EvaaCRM a HostGator

## 📋 **Resumen de la Migración**

Esta guía te permitirá migrar tu sistema EvaaCRM completo desde tu entorno de desarrollo local a HostGator como subdominio, manteniendo toda la información y funcionalidad intacta.

## 🎯 **Objetivos de la Migración**

- ✅ **Migrar la aplicación completa** con todos los cambios recientes
- ✅ **Preservar la base de datos** con todos los datos existentes
- ✅ **Configurar como subdominio** en HostGator
- ✅ **Mantener funcionalidad completa** del sistema

## 📦 **Archivos Incluidos en el Paquete**

```
migration_package/
├── MIGRATION_GUIDE.md (este archivo)
├── evaa_crm_gaepell_release.tar.gz (aplicación compilada)
├── database_backup.sql (respaldo de la base de datos)
├── hostgator_setup.sh (script de configuración automática)
├── nginx_config.conf (configuración del servidor web)
├── systemd_service.conf (servicio del sistema)
└── environment_vars.env (variables de entorno)
```

## 🔧 **Requisitos Previos en HostGator**

### **1. Acceso SSH**
- Acceso SSH a tu cuenta de HostGator
- Permisos de administrador (sudo)

### **2. Base de Datos**
- Base de datos PostgreSQL creada
- Usuario y contraseña de la base de datos
- Host y puerto de la base de datos

### **3. Dominio**
- Dominio principal configurado
- Subdominio deseado (ej: `crm.tudominio.com`)

## 📥 **Paso 1: Subir el Paquete de Migración**

### **Opción A: Via FTP/SFTP**
1. Conecta a tu cuenta de HostGator via FTP
2. Sube todo el contenido de `migration_package/` a tu directorio raíz
3. Extrae el archivo `evaa_crm_gaepell_release.tar.gz`

### **Opción B: Via SSH (Recomendado)**
```bash
# Desde tu máquina local
scp -r migration_package/ usuario@tu-servidor:/home/usuario/
```

## 🗄️ **Paso 2: Restaurar la Base de Datos**

```bash
# Conectarse a HostGator via SSH
ssh usuario@tu-servidor

# Navegar al directorio de migración
cd migration_package

# Restaurar la base de datos
psql -h localhost -U tu_usuario -d tu_base_datos < database_backup.sql
```

## ⚙️ **Paso 3: Configuración Automática**

```bash
# Dar permisos de ejecución al script
chmod +x hostgator_setup.sh

# Ejecutar la configuración automática
./hostgator_setup.sh
```

**El script automático realizará:**
- ✅ Instalación de dependencias del sistema
- ✅ Configuración de PostgreSQL
- ✅ Configuración de Nginx
- ✅ Configuración del servicio del sistema
- ✅ Configuración de variables de entorno
- ✅ Inicio del servicio EvaaCRM

## 🌐 **Paso 4: Configuración del Subdominio**

### **En el Panel de Control de HostGator:**
1. Ir a **Domains** → **Subdomains**
2. Crear subdominio: `crm` (resultará en `crm.tudominio.com`)
3. Apuntar al directorio: `/home/usuario/evaa_crm_gaepell`

### **Configuración DNS (si es necesario):**
```
Tipo: CNAME
Nombre: crm
Valor: tudominio.com
TTL: 300
```

## 🔍 **Paso 5: Verificación de la Migración**

### **1. Verificar el Servicio**
```bash
# Verificar que el servicio esté corriendo
sudo systemctl status evaa_crm_gaepell

# Ver logs en tiempo real
sudo journalctl -u evaa_crm_gaepell -f
```

### **2. Verificar la Aplicación Web**
- Abrir `https://crm.tudominio.com` en tu navegador
- Verificar que puedas hacer login
- Verificar que todos los datos estén presentes
- Verificar que las funcionalidades principales funcionen

### **3. Verificar la Base de Datos**
```bash
# Conectarse a la base de datos
psql -h localhost -U tu_usuario -d tu_base_datos

# Verificar tablas principales
\dt
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM trucks;
SELECT COUNT(*) FROM maintenance_tickets;
```

## 🚨 **Solución de Problemas Comunes**

### **Error: Puerto ya en uso**
```bash
# Verificar qué está usando el puerto 4000
sudo netstat -tlnp | grep :4000

# Detener el proceso conflictivo
sudo kill -9 PID_DEL_PROCESO
```

### **Error: Base de datos no conecta**
```bash
# Verificar estado de PostgreSQL
sudo systemctl status postgresql

# Verificar configuración de conexión
sudo cat /etc/postgresql/*/main/postgresql.conf | grep listen_addresses
```

### **Error: Permisos de archivos**
```bash
# Corregir permisos
sudo chown -R usuario:usuario /home/usuario/evaa_crm_gaepell
sudo chmod -R 755 /home/usuario/evaa_crm_gaepell
```

## 🔄 **Mantenimiento y Actualizaciones**

### **Reiniciar el Servicio**
```bash
sudo systemctl restart evaa_crm_gaepell
```

### **Ver Logs**
```bash
sudo journalctl -u evaa_crm_gaepell -f
```

### **Backup de la Base de Datos**
```bash
pg_dump -h localhost -U tu_usuario -d tu_base_datos > backup_$(date +%Y%m%d_%H%M%S).sql
```

## 📞 **Soporte Técnico**

Si encuentras problemas durante la migración:

1. **Revisar logs del sistema**: `sudo journalctl -u evaa_crm_gaepell -f`
2. **Verificar estado del servicio**: `sudo systemctl status evaa_crm_gaepell`
3. **Verificar conectividad de la base de datos**
4. **Contactar al equipo de desarrollo** con los logs de error

## 🎉 **¡Migración Completada!**

Una vez que hayas seguido todos los pasos, tu sistema EvaaCRM estará funcionando completamente en HostGator como subdominio, con:

- ✅ **Aplicación web funcional** en `https://crm.tudominio.com`
- ✅ **Base de datos completa** con todos los datos
- ✅ **Funcionalidades actualizadas** (campos de entregador simplificados)
- ✅ **Sistema de autenticación** funcionando
- ✅ **Gestión de camiones y tickets** operativa
- ✅ **Sistema de mantenimiento** completo

---

**Fecha de Migración**: $(date)
**Versión del Sistema**: EvaaCRM Gaepell v0.1.0
**Entorno Destino**: HostGator
**Subdominio**: crm.tudominio.com 