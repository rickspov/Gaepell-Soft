# 🚀 Guía de Despliegue EvaaCRM en /admin

## 📋 **Resumen del Despliegue**

Esta guía te permitirá desplegar EvaaCRM en la carpeta `/admin` de tu dominio principal, manteniendo toda la información y funcionalidad intacta.

## 🎯 **Estructura Final**

```
https://grupo-gaepell.com/          # Sitio web principal
https://grupo-gaepell.com/admin/     # EvaaCRM
```

## 📦 **Archivos Necesarios**

### **1. Aplicación Phoenix**
- Código fuente de EvaaCRM
- Release compilado (opcional)

### **2. Base de Datos**
- Backup de tu base de datos actual
- Scripts de migración

### **3. Configuración Web**
- Configuración de proxy reverso
- Variables de entorno

## 🔧 **Paso 1: Preparar Hostgator**

### **1.1 Crear Base de Datos**
1. **Ir a cPanel → MySQL Databases**
2. **Crear base de datos:**
   - Nombre: `eva_crm_db`
   - Usuario: `eva_crm_user`
   - Contraseña: `[contraseña_segura]`

### **1.2 Crear Carpeta Admin**
1. **Ir a cPanel → File Manager**
2. **Navegar a `public_html/`**
3. **Crear carpeta:** `admin`

## 📤 **Paso 2: Subir Aplicación**

### **Opción A: Código Fuente (Recomendado)**
```bash
# En tu máquina local
cd evaa_crm_gaepell

# Crear archivo ZIP
zip -r eva-crm-admin.zip . -x "*.git*" "_build/*" "deps/*" "node_modules/*"

# Subir via FTP a:
# public_html/admin/
```

### **Opción B: Release Compilado**
```bash
# Usar el paquete de migración existente
# Extraer en public_html/admin/
```

## ⚙️ **Paso 3: Configurar Variables de Entorno**

### **Crear archivo `.env` en `public_html/admin/`:**
```bash
# Configuración de la aplicación
MIX_ENV=prod
SECRET_KEY_BASE=tu_secret_key_aqui
PHX_HOST=grupo-gaepell.com

# Base de datos
DATABASE_URL=mysql://eva_crm_user:contraseña@localhost/eva_crm_db

# Configuración del servidor
PORT=4000
```

## 🗄️ **Paso 4: Restaurar Base de Datos**

```bash
# Conectarse a Hostgator via SSH
ssh usuario@tu-servidor

# Navegar al directorio
cd public_html/admin

# Restaurar backup
mysql -u eva_crm_user -p eva_crm_db < database_backup.sql
```

## 🌐 **Paso 5: Configurar Proxy Reverso**

### **5.1 Crear archivo `.htaccess` en `public_html/admin/`:**
```apache
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
```

### **5.2 Alternativa: Configuración Nginx (si está disponible)**
```nginx
location /admin/ {
    proxy_pass http://localhost:4000/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}
```

## 🚀 **Paso 6: Iniciar la Aplicación**

### **6.1 Instalar Dependencias**
```bash
cd public_html/admin
mix deps.get
```

### **6.2 Ejecutar Migraciones**
```bash
mix ecto.migrate
```

### **6.3 Iniciar Aplicación**
```bash
# Opción A: Desarrollo
mix phx.server

# Opción B: Producción
MIX_ENV=prod mix phx.server
```

### **6.4 Mantener Aplicación Corriendo**
```bash
# Usar screen o tmux
screen -S eva-crm
mix phx.server
# Ctrl+A, D para desconectar

# O usar nohup
nohup mix phx.server > eva-crm.log 2>&1 &
```

## 🔍 **Paso 7: Verificar Despliegue**

### **7.1 Probar la Aplicación**
1. **Abrir:** `https://grupo-gaepell.com/admin/`
2. **Verificar login** con tus credenciales
3. **Verificar datos** (camiones, tickets, etc.)

### **7.2 Verificar Logs**
```bash
# Ver logs de la aplicación
tail -f eva-crm.log

# Ver logs de Apache/Nginx
tail -f /var/log/apache2/error.log
```

## 🚨 **Solución de Problemas**

### **Error: Puerto 4000 no disponible**
```bash
# Verificar qué está usando el puerto
netstat -tlnp | grep :4000

# Cambiar puerto en .env
PORT=4001
```

### **Error: Base de datos no conecta**
```bash
# Verificar credenciales
mysql -u eva_crm_user -p eva_crm_db

# Verificar que las tablas existen
SHOW TABLES;
```

### **Error: Proxy no funciona**
- Verificar que mod_proxy esté habilitado
- Verificar configuración de .htaccess
- Verificar que la aplicación esté corriendo en el puerto correcto

## 🔄 **Mantenimiento**

### **Reiniciar Aplicación**
```bash
# Encontrar proceso
ps aux | grep mix

# Matar proceso
kill -9 PID

# Reiniciar
nohup mix phx.server > eva-crm.log 2>&1 &
```

### **Backup de Base de Datos**
```bash
mysqldump -u eva_crm_user -p eva_crm_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

## 🎉 **¡Despliegue Completado!**

Tu EvaaCRM estará disponible en:
**https://grupo-gaepell.com/admin/**

Con todas las funcionalidades:
- ✅ Login y autenticación
- ✅ Gestión de camiones
- ✅ Tickets de mantenimiento
- ✅ Sistema de fotos
- ✅ Wizard de tickets
- ✅ Todos los datos preservados

---

**Fecha de Despliegue**: $(date)
**URL de Acceso**: https://grupo-gaepell.com/admin/
**Versión**: EvaaCRM Gaepell v0.1.0 