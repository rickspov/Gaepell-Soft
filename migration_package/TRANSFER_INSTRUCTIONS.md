# 📤 Instrucciones de Transferencia a HostGator

## 🚀 **Opción 1: Transferencia via SSH (Recomendado)**

### **Desde tu máquina local:**
```bash
# Conectar y transferir
scp -r migration_package/ usuario@tu-servidor:/home/usuario/

# Verificar la transferencia
ssh usuario@tu-servidor
cd migration_package
ls -la
```

## 📁 **Opción 2: Transferencia via FTP/SFTP**

### **Usando FileZilla o similar:**
1. Conectar a tu servidor HostGator via FTP
2. Navegar a tu directorio raíz (ej: )
3. Subir **todo el contenido** de la carpeta 
4. **NO subir la carpeta  en sí, sino su contenido**

### **Estructura correcta en el servidor:**
```
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
```

## ✅ **Verificación de la Transferencia**

### **1. Verificar archivos transferidos:**
```bash
ls -la
```

### **2. Verificar integridad (si usaste SSH):**
```bash
sha256sum -c checksums.sha256
```

### **3. Verificar tamaños:**
```bash
cat SIZES.txt
```

## 🚨 **Problemas Comunes**

### **Error: Permisos denegados**
```bash
chmod +x hostgator_setup.sh
chmod +x create_backup.sh
```

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
   ```bash
   ./hostgator_setup.sh
   ```

2. **Configurar subdominio en HostGator**

3. **Probar la aplicación**

## 📞 **Soporte**

Si tienes problemas con la transferencia:
- Verificar conectividad al servidor
- Verificar permisos de usuario
- Contactar soporte de HostGator
