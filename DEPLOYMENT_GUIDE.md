# 🚀 Guía de Despliegue - EVA CRM

## 📋 **Opciones de Despliegue**

### **Opción 1: Hostgator (Recomendado para Gaepell)**

#### **Configuración del Subdominio:**
```
Subdominio: eva.grupo-gaepell.com
o
eva.gaepell.com
```

#### **Pasos de Despliegue:**

1. **Preparar el Build:**
```bash
# En tu máquina local
cd evaa_crm_gaepell
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
```

2. **Configurar Hostgator:**
   - Acceder al cPanel
   - Crear subdominio: `eva`
   - Configurar PHP a versión 8.1+
   - Habilitar SSH si es posible

3. **Subir Archivos:**
```bash
# Crear archivo de despliegue
tar -czf eva-crm.tar.gz _build/prod/rel/evaa_crm_gaepell/
# Subir via FTP/SFTP a public_html/eva/
```

4. **Configurar Base de Datos:**
   - Crear base de datos MySQL en cPanel
   - Configurar variables de entorno
   - Ejecutar migraciones

#### **Archivo de Configuración:**
```elixir
# config/prod.exs
config :evaa_crm_gaepell, EvaaCrmWebGaepell.Endpoint,
  url: [host: "eva.grupo-gaepell.com", port: 443, scheme: "https"],
  http: [port: 4000],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

config :evaa_crm_gaepell, EvaaCrmGaepell.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10
```

### **Opción 2: Railway (Alternativa Moderna)**

#### **Ventajas:**
- ✅ Despliegue automático desde GitHub
- ✅ SSL automático
- ✅ Base de datos PostgreSQL incluida
- ✅ Escalabilidad automática
- ✅ Más económico que Heroku

#### **Pasos:**
1. Conectar repositorio GitHub
2. Configurar variables de entorno
3. Despliegue automático

### **Opción 3: DigitalOcean App Platform**

#### **Ventajas:**
- ✅ Muy confiable
- ✅ Buena documentación
- ✅ Soporte técnico
- ✅ Precios competitivos

## 📱 **Configuración PWA**

### **Iconos Requeridos:**
```
/images/icon-192x192.png
/images/icon-512x512.png
```

### **Generar Iconos:**
```bash
# Usar herramientas online como:
# - https://realfavicongenerator.net/
# - https://www.pwabuilder.com/imageGenerator
```

## 🔧 **Configuración de Producción**

### **Variables de Entorno:**
```bash
# .env
SECRET_KEY_BASE=tu_secret_key_aqui
DATABASE_URL=mysql://usuario:password@localhost/eva_crm
PHX_HOST=eva.grupo-gaepell.com
```

### **Script de Inicio:**
```bash
#!/bin/bash
# start.sh
export MIX_ENV=prod
export PORT=4000
export DATABASE_URL="mysql://usuario:password@localhost/eva_crm"

cd /path/to/evaa_crm_gaepell
_build/prod/rel/evaa_crm_gaepell/bin/evaa_crm_gaepell start
```

## 📊 **Monitoreo y Logs**

### **Logs de Aplicación:**
```bash
# Ver logs en tiempo real
tail -f /path/to/logs/eva_crm.log

# Logs de errores
grep "ERROR" /path/to/logs/eva_crm.log
```

### **Monitoreo de Base de Datos:**
```sql
-- Ver conexiones activas
SHOW PROCESSLIST;

-- Ver tamaño de tablas
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'eva_crm';
```

## 🔒 **Seguridad**

### **SSL/HTTPS:**
- Configurar certificado SSL en Hostgator
- Redirigir HTTP a HTTPS
- Configurar HSTS

### **Firewall:**
```bash
# Solo permitir puertos necesarios
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw enable
```

## 📈 **Escalabilidad**

### **Optimizaciones:**
1. **CDN** para assets estáticos
2. **Caché** de consultas frecuentes
3. **Compresión** gzip/brotli
4. **Optimización** de imágenes

### **Monitoreo de Performance:**
```elixir
# config/prod.exs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]
```

## 🚨 **Backup y Recuperación**

### **Backup Automático:**
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u usuario -p eva_crm > backup_$DATE.sql
tar -czf backup_$DATE.tar.gz backup_$DATE.sql
rm backup_$DATE.sql
```

### **Restauración:**
```bash
mysql -u usuario -p eva_crm < backup_20241201_143022.sql
```

## 📞 **Soporte y Mantenimiento**

### **Contactos:**
- **Desarrollador:** [Tu contacto]
- **Hostgator Support:** [Contacto de Hostgator]
- **Base de Datos:** [DBA si aplica]

### **Procedimientos de Emergencia:**
1. **Sitio caído:** Verificar logs y reiniciar servicio
2. **Base de datos:** Restaurar desde backup
3. **Pérdida de datos:** Contactar inmediatamente

## 🎯 **Próximos Pasos**

1. **Configurar dominio** en Hostgator
2. **Preparar build** de producción
3. **Configurar base de datos**
4. **Probar en staging**
5. **Desplegar a producción**
6. **Configurar monitoreo**
7. **Entrenar usuarios**

---

**¿Necesitas ayuda con algún paso específico?** 