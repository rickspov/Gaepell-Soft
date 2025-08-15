# 🚀 Instrucciones de Despliegue EvaaCRM en Hostgator

## 📋 **Resumen**
Desplegar EvaaCRM en `https://grupogaepell.com/admin/` con tu base de datos MySQL.

## 🗄️ **Base de Datos Configurada**
- **Usuario:** `eva_crm_user`
- **Base de datos:** `eva_crm_db`
- **Contraseña:** `EvaCrm2025!`
- **Host:** `localhost`

## 📦 **Archivos Necesarios**
1. `eva-crm-admin-20250814_165749.zip` (96MB) - Aplicación
2. `eva-crm-database-backup.sql` (142KB) - Datos actuales
3. `install_eva_crm.sh` - Script de instalación
4. `eva-crm-config.env` - Configuración específica

---

## 🔧 **Paso 1: Preparar Hostgator**

### **1.1 Crear Carpeta Admin**
1. **Acceder a cPanel**
2. **Ir a "File Manager"**
3. **Navegar a `public_html/`**
4. **Crear carpeta:** `admin`

### **1.2 Verificar Base de Datos**
1. **Ir a "MySQL Databases"**
2. **Verificar que existe:**
   - Base de datos: `eva_crm_db`
   - Usuario: `eva_crm_user`
   - Contraseña: `EvaCrm2025!`

---

## 📤 **Paso 2: Subir Archivos**

### **2.1 Subir Aplicación**
1. **Subir** `eva-crm-admin-20250814_165749.zip` a tu servidor
2. **Extraer** en `public_html/admin/`
3. **Verificar** que se extrajo correctamente

### **2.2 Subir Backup de Datos**
1. **Subir** `eva-crm-database-backup.sql` a `public_html/admin/`
2. **Subir** `install_eva_crm.sh` a `public_html/admin/`

---

## ⚙️ **Paso 3: Instalar Aplicación**

### **3.1 Conectarse via SSH**
```bash
ssh usuario@tu-servidor
cd public_html/admin
```

### **3.2 Ejecutar Instalación**
```bash
# Dar permisos de ejecución
chmod +x install_eva_crm.sh

# Ejecutar instalación automática
./install_eva_crm.sh
```

**El script automáticamente:**
- ✅ Crea el archivo `.env` con tu configuración
- ✅ Instala dependencias
- ✅ Ejecuta migraciones
- ✅ Compila assets
- ✅ Genera SECRET_KEY_BASE
- ✅ Crea scripts de inicio y backup

---

## 🗄️ **Paso 4: Restaurar Datos**

### **4.1 Restaurar Backup**
```bash
# Restaurar tu base de datos actual
mysql -u eva_crm_user -p eva_crm_db < eva-crm-database-backup.sql
```

**Cuando te pida la contraseña, usa:** `EvaCrm2025!`

---

## 🚀 **Paso 5: Iniciar Aplicación**

### **5.1 Iniciar Servicio**
```bash
# Iniciar la aplicación
./start_eva_crm.sh
```

### **5.2 Mantener Corriendo**
```bash
# Para mantener corriendo en background
nohup ./start_eva_crm.sh > eva_crm.log 2>&1 &
```

---

## 🔍 **Paso 6: Verificar Despliegue**

### **6.1 Probar Aplicación**
1. **Abrir:** `https://grupogaepell.com/admin/`
2. **Verificar** que carga correctamente
3. **Hacer login** con tus credenciales actuales

### **6.2 Verificar Datos**
- ✅ Camiones presentes
- ✅ Tickets de mantenimiento
- ✅ Usuarios y especialistas
- ✅ Fotos y archivos

---

## 🔧 **Comandos Útiles**

### **Ver Logs**
```bash
tail -f eva_crm.log
```

### **Reiniciar Aplicación**
```bash
# Encontrar proceso
ps aux | grep mix

# Matar proceso
kill -9 PID

# Reiniciar
./start_eva_crm.sh
```

### **Crear Backup**
```bash
./backup_database.sh
```

### **Verificar Base de Datos**
```bash
mysql -u eva_crm_user -p eva_crm_db
SHOW TABLES;
SELECT COUNT(*) FROM trucks;
SELECT COUNT(*) FROM maintenance_tickets;
```

---

## 🚨 **Solución de Problemas**

### **Error: Puerto 4000 en uso**
```bash
netstat -tlnp | grep :4000
kill -9 PID_DEL_PROCESO
```

### **Error: Base de datos no conecta**
```bash
# Verificar credenciales
mysql -u eva_crm_user -p eva_crm_db

# Verificar que las tablas existen
SHOW TABLES;
```

### **Error: Permisos de archivos**
```bash
chmod -R 755 .
chmod +x *.sh
```

---

## 📞 **Información de Contacto**

**Configuración de Base de Datos:**
- **Host:** localhost
- **Usuario:** eva_crm_user
- **Base de datos:** eva_crm_db
- **Contraseña:** EvaCrm2025!

**URL de Acceso:**
- **https://grupogaepell.com/admin/**

---

## 🎉 **¡Despliegue Completado!**

Una vez que hayas seguido todos los pasos, tu EvaaCRM estará funcionando en:
**https://grupogaepell.com/admin/**

Con todas las funcionalidades y datos preservados. 