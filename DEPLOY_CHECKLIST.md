# ✅ Checklist de Deploy en Railway

Usa esta checklist para asegurarte de que todo esté configurado correctamente antes y después del deploy.

## 📋 Pre-Deploy

### Repositorio
- [ ] Código está en GitHub
- [ ] `.gitignore` está actualizado (excluye backups, zips, etc.)
- [ ] `railway.toml` o `railway.json` está presente
- [ ] `config/runtime.exs` está configurado correctamente
- [ ] No hay archivos sensibles en el repositorio

### Configuración Local
- [ ] `SECRET_KEY_BASE` generado (usar `mix phx.gen.secret`)
- [ ] Variables de entorno documentadas
- [ ] Migraciones probadas localmente

## 🚂 Configuración en Railway

### Proyecto
- [ ] Proyecto creado en Railway
- [ ] Repositorio conectado desde GitHub
- [ ] Root directory configurado (si es necesario: `evaa_crm_gaepell`)

### Base de Datos
- [ ] PostgreSQL agregado como servicio
- [ ] `DATABASE_URL` configurada automáticamente
- [ ] Base de datos accesible

### Variables de Entorno
- [ ] `SECRET_KEY_BASE` configurada (marcada como Secret)
- [ ] `PHX_SERVER=true`
- [ ] `PHX_HOST` configurada (o usar la de Railway)
- [ ] `POOL_SIZE=10`
- [ ] `MIX_ENV=prod`
- [ ] `BUSINESS_ID` configurada (si es necesario)

## 🚀 Deploy

### Build
- [ ] Build inicia correctamente
- [ ] Dependencias se instalan sin errores
- [ ] Compilación exitosa

### Migraciones
- [ ] Migraciones se ejecutan automáticamente
- [ ] O migraciones ejecutadas manualmente
- [ ] Base de datos tiene las tablas correctas

### Inicio del Servidor
- [ ] Servidor inicia sin errores
- [ ] Health check pasa (`/`)
- [ ] Logs no muestran errores críticos

## ✅ Post-Deploy

### Verificación
- [ ] Aplicación accesible en la URL de Railway
- [ ] Login funciona correctamente
- [ ] Base de datos conectada
- [ ] Puedes crear/editar registros
- [ ] Archivos estáticos se cargan

### Monitoreo
- [ ] Logs se están generando
- [ ] Métricas disponibles en Railway
- [ ] No hay errores en los logs
- [ ] Uso de recursos es normal

## 🔧 Troubleshooting

Si algo falla, verifica:

1. **Build falla**
   - [ ] Revisa logs de build
   - [ ] Verifica que `mix.lock` esté en el repo
   - [ ] Verifica dependencias en `mix.exs`

2. **Migraciones fallan**
   - [ ] Verifica `DATABASE_URL`
   - [ ] Ejecuta migraciones manualmente
   - [ ] Revisa permisos de la BD

3. **Servidor no inicia**
   - [ ] Verifica `SECRET_KEY_BASE`
   - [ ] Verifica `PHX_SERVER=true`
   - [ ] Revisa logs completos

4. **Base de datos no conecta**
   - [ ] Verifica `DATABASE_URL`
   - [ ] Verifica que PostgreSQL esté corriendo
   - [ ] Revisa configuración de SSL

5. **Aplicación no responde**
   - [ ] Verifica health check
   - [ ] Revisa logs de la aplicación
   - [ ] Verifica que el puerto esté correcto

## 📝 Notas

- Railway configura automáticamente `PORT` y `DATABASE_URL`
- El `PHX_HOST` se puede obtener de Railway después del deploy
- Las migraciones se ejecutan automáticamente en el `startCommand`
- Los logs están disponibles en tiempo real en Railway Dashboard

---

**Última actualización**: Después de cada deploy exitoso, marca esta checklist como completada.

