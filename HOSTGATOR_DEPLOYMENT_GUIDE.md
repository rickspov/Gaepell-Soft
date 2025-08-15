# 🚀 Guía Completa: Desplegar PWA en Hostgator

## 📋 **Resumen del Proceso**

1. **Preparar el código** (PWA + Offline Sync)
2. **Configurar Hostgator** (Subdominio + Base de datos)
3. **Subir archivos** al servidor
4. **Configurar variables** de entorno
5. **Ejecutar migraciones** de base de datos
6. **Iniciar la aplicación**
7. **Probar PWA** en móviles

---

## 🔧 **Paso 1: Preparar el Código**

### **✅ Lo que ya está listo:**
- ✅ **PWA configurado** (manifest.json, service worker)
- ✅ **Sistema offline** (IndexedDB + sincronización)
- ✅ **Iconos PWA** (192x192, 512x512)
- ✅ **CSS optimizado** para móviles
- ✅ **JavaScript** para instalación PWA

### **📁 Archivos PWA creados:**
```
apps/evaa_crm_web_gaepell/priv/static/
├── manifest.json          # Configuración PWA
├── sw.js                  # Service Worker
├── images/
│   ├── icon-192x192.png   # Icono PWA
│   └── icon-512x512.png   # Icono PWA
└── assets/
    ├── pwa.js             # Scripts PWA
    └── offline-sync.js    # Sincronización offline
```

---

## 🌐 **Paso 2: Configurar Hostgator**

### **2.1 Crear Subdominio**
1. **Acceder a cPanel** de Hostgator
2. **Ir a "Subdominios"**
3. **Crear subdominio:**
   - **Subdominio:** `eva`
   - **Dominio:** `grupo-gaepell.com` (o tu dominio)
   - **URL resultante:** `eva.grupo-gaepell.com`

### **2.2 Configurar Base de Datos**
1. **Ir a "MySQL Databases"** en cPanel
2. **Crear nueva base de datos:**
   - **Nombre:** `eva_crm_db`
   - **Usuario:** `eva_crm_user`
   - **Contraseña:** `[contraseña_segura]`
3. **Anotar credenciales** para usar después

### **2.3 Configurar PHP (si es necesario)**
1. **Ir a "PHP Selector"**
2. **Seleccionar PHP 8.1+**
3. **Habilitar extensiones:**
   - `openssl`
   - `pdo_mysql`
   - `json`
   - `mbstring`

---

## 📤 **Paso 3: Subir Archivos**

### **3.1 Opción A: Subir Código Fuente (Desarrollo)**
```bash
# En tu máquina local
cd evaa_crm_gaepell

# Crear archivo ZIP del proyecto
zip -r eva-crm-source.zip . -x "*.git*" "_build/*" "deps/*" "node_modules/*"

# Subir via FTP/SFTP a:
# public_html/eva/
```

### **3.2 Opción B: Subir Build de Producción**
```bash
# Ejecutar build (cuando esté listo)
./build_simple.sh

# Subir el archivo generado:
# eva-crm-deploy-YYYYMMDD_HHMMSS.tar.gz
```

### **3.3 Estructura en Hostgator:**
```
public_html/eva/
├── apps/
│   └── evaa_crm_web_gaepell/
│       ├── priv/static/          # Archivos PWA
│       └── lib/                  # Código de la aplicación
├── config/                       # Configuración
├── mix.exs                       # Archivo principal
└── README.md
```

---

## ⚙️ **Paso 4: Configurar Variables de Entorno**

### **4.1 Crear archivo `.env`**
```bash
# En el directorio raíz del proyecto en Hostgator
nano .env
```

### **4.2 Contenido del archivo `.env`:**
```bash
# Configuración de la aplicación
MIX_ENV=prod
SECRET_KEY_BASE=tu_secret_key_aqui
PHX_HOST=eva.grupo-gaepell.com

# Base de datos
DATABASE_URL=mysql://eva_crm_user:contraseña@localhost/eva_crm_db

# Configuración del servidor
PORT=4000
```

### **4.3 Generar Secret Key Base:**
```bash
# En tu máquina local
mix phx.gen.secret
# Copiar el resultado al archivo .env
```

---

## 🗄️ **Paso 5: Configurar Base de Datos**

### **5.1 Instalar dependencias:**
```bash
# En el servidor Hostgator
cd public_html/eva/
mix deps.get
```

### **5.2 Ejecutar migraciones:**
```bash
# Crear tablas
mix ecto.migrate

# Insertar datos iniciales (opcional)
mix run priv/repo/seeds.exs
```

### **5.3 Verificar conexión:**
```bash
# Probar conexión a la base de datos
mix ecto.dump
```

---

## 🚀 **Paso 6: Iniciar la Aplicación**

### **6.1 Opción A: Usando Mix (Desarrollo)**
```bash
# En el servidor
cd public_html/eva/
mix phx.server
```

### **6.2 Opción B: Usando Release (Producción)**
```bash
# Crear release
MIX_ENV=prod mix release

# Iniciar aplicación
_build/prod/rel/evaa_crm_gaepell/bin/evaa_crm_gaepell start
```

### **6.3 Configurar como Servicio (Recomendado)**
```bash
# Crear script de inicio
nano start_eva_crm.sh
```

**Contenido del script:**
```bash
#!/bin/bash
cd /home/usuario/public_html/eva/
export MIX_ENV=prod
export DATABASE_URL="mysql://eva_crm_user:contraseña@localhost/eva_crm_db"
export SECRET_KEY_BASE="tu_secret_key_aqui"
export PHX_HOST="eva.grupo-gaepell.com"

# Iniciar aplicación
mix phx.server
```

```bash
# Hacer ejecutable
chmod +x start_eva_crm.sh

# Ejecutar en background
nohup ./start_eva_crm.sh > eva_crm.log 2>&1 &
```

---

## 🔒 **Paso 7: Configurar SSL/HTTPS**

### **7.1 SSL Gratuito en cPanel:**
1. **Ir a "SSL/TLS"** en cPanel
2. **Seleccionar "Install SSL"**
3. **Elegir dominio:** `eva.grupo-gaepell.com`
4. **Instalar certificado gratuito**

### **7.2 Redirigir HTTP a HTTPS:**
```apache
# En .htaccess (si usas Apache)
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

---

## 📱 **Paso 8: Probar PWA**

### **8.1 Verificar PWA:**
1. **Abrir:** `https://eva.grupo-gaepell.com`
2. **Verificar que aparece prompt** "Instalar EVA CRM"
3. **Instalar en móvil/tablet**

### **8.2 Probar Funcionalidad Offline:**
1. **Activar modo avión** en móvil
2. **Intentar crear cotización**
3. **Verificar indicador offline**
4. **Desactivar modo avión**
5. **Verificar sincronización**

### **8.3 Verificar en Chrome DevTools:**
1. **Abrir DevTools** (F12)
2. **Ir a pestaña "Application"**
3. **Verificar:**
   - ✅ Manifest cargado
   - ✅ Service Worker registrado
   - ✅ Íconos disponibles

---

## 🔧 **Paso 9: Configuración Adicional**

### **9.1 Configurar Dominio Personalizado (Opcional):**
```
# En lugar de eva.grupo-gaepell.com
# Usar: crm.grupo-gaepell.com
```

### **9.2 Configurar Email (Opcional):**
```bash
# En config/prod.exs
config :evaa_crm_gaepell, EvaaCrmGaepell.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.gmail.com",
  port: 587,
  username: "tu_email@gmail.com",
  password: "tu_password",
  tls: :always,
  auth: :always,
  retries: 2
```

### **9.3 Configurar Backup Automático:**
```bash
# Crear script de backup
nano backup_eva_crm.sh
```

**Contenido:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u eva_crm_user -p eva_crm_db > backup_$DATE.sql
tar -czf backup_$DATE.tar.gz backup_$DATE.sql
rm backup_$DATE.sql
```

---

## 🚨 **Solución de Problemas**

### **Problema: "Application Error"**
```bash
# Verificar logs
tail -f eva_crm.log

# Verificar variables de entorno
echo $DATABASE_URL
echo $SECRET_KEY_BASE
```

### **Problema: "Database Connection Failed"**
```bash
# Verificar credenciales de BD
mysql -u eva_crm_user -p eva_crm_db

# Verificar que la tabla existe
SHOW TABLES;
```

### **Problema: PWA no se instala**
1. **Verificar HTTPS** está configurado
2. **Verificar manifest.json** es accesible
3. **Verificar service worker** está registrado
4. **Limpiar caché** del navegador

### **Problema: Offline no funciona**
1. **Verificar IndexedDB** está habilitado
2. **Verificar service worker** está activo
3. **Verificar archivos** están cacheados

---

## 📞 **Soporte**

### **Contactos útiles:**
- **Hostgator Support:** [Contacto de Hostgator]
- **Documentación PWA:** https://web.dev/progressive-web-apps/
- **Documentación Phoenix:** https://hexdocs.pm/phoenix/

### **Logs importantes:**
```bash
# Logs de la aplicación
tail -f eva_crm.log

# Logs de errores
tail -f /var/log/apache2/error.log

# Logs de MySQL
tail -f /var/log/mysql/error.log
```

---

## 🎯 **Checklist Final**

- [ ] **Subdominio creado** (`eva.grupo-gaepell.com`)
- [ ] **Base de datos configurada** (MySQL)
- [ ] **Archivos subidos** al servidor
- [ ] **Variables de entorno** configuradas
- [ ] **Migraciones ejecutadas**
- [ ] **Aplicación iniciada**
- [ ] **SSL configurado** (HTTPS)
- [ ] **PWA funciona** en móviles
- [ ] **Offline funciona** correctamente
- [ ] **Backup configurado**

---

**¡Tu PWA EVA CRM está listo para usar en Hostgator! 🎉** 