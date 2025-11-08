# 🔧 Troubleshooting de LiveView en Railway - EVA CRM

Si los modales no se abren, el wizard no avanza, o el layout parece diferente, sigue estos pasos para diagnosticar y resolver el problema.

## Problemas Comunes

### 1. Los eventos `phx-click` no funcionan

**Síntomas:**
- Los modales no se abren al hacer clic
- El wizard no avanza al siguiente paso
- Los botones no responden

**Causas posibles:**
1. La conexión de LiveView no se está estableciendo
2. Los assets JavaScript no se están cargando correctamente
3. El `check_origin` está bloqueando las conexiones

**Solución:**

1. **Verifica la consola del navegador:**
   - Abre las herramientas de desarrollador (F12)
   - Ve a la pestaña "Console"
   - Busca errores relacionados con:
     - `LiveSocket`
     - `phoenix_live_view`
     - `WebSocket`
     - `check_origin`

2. **Verifica la conexión de LiveView:**
   - En la consola del navegador, ejecuta:
     ```javascript
     window.liveSocket
     ```
   - Deberías ver un objeto `LiveSocket`. Si es `undefined`, LiveView no se está inicializando.

3. **Verifica que los assets se carguen:**
   - En la pestaña "Network" de las herramientas de desarrollador
   - Recarga la página (Ctrl+F5)
   - Busca las siguientes peticiones:
     - `app.js` (debe retornar 200 OK)
     - `app.css` (debe retornar 200 OK)
     - `pwa.js` (debe retornar 200 OK)
   - Si alguna retorna 404, los assets no se compilaron correctamente.

4. **Verifica el `check_origin`:**
   - En los logs de Railway, busca mensajes como:
     ```
     Could not check origin for Phoenix.Socket transport
     ```
   - Si ves este error, el `check_origin` está bloqueando las conexiones.

### 2. El layout parece diferente

**Síntomas:**
- El diseño visual no coincide con la versión local
- Los estilos CSS no se aplican correctamente

**Causas posibles:**
1. Los assets CSS no se compilaron correctamente
2. El cache del navegador está mostrando una versión antigua
3. Los assets no se están sirviendo correctamente

**Solución:**

1. **Limpia el cache del navegador:**
   - Presiona `Ctrl+Shift+Delete` (o `Cmd+Shift+Delete` en Mac)
   - Selecciona "Imágenes y archivos en caché"
   - Haz clic en "Borrar datos"
   - O simplemente recarga con `Ctrl+F5` (hard refresh)

2. **Verifica que los assets se compilaron:**
   - En Railway, ve a los logs del build
   - Busca mensajes como:
     ```
     ✅ Build completed successfully!
     ```
   - Si ves errores durante la compilación de assets, esos son los problemas.

3. **Verifica que `phx.digest` se ejecutó:**
   - Los assets deben tener un hash en el nombre (ej: `app-abc123.js`)
   - Si los assets no tienen hash, `phx.digest` no se ejecutó.

### 3. El wizard no avanza

**Síntomas:**
- Al hacer clic en "Siguiente" en el wizard, no pasa nada
- El paso actual no cambia

**Causas posibles:**
1. El evento `phx-click="next_step"` no se está enviando
2. El handler `handle_event("next_step", ...)` no está funcionando
3. La conexión de LiveView se perdió

**Solución:**

1. **Verifica que el evento se está enviando:**
   - En la consola del navegador, busca mensajes de LiveView
   - Deberías ver algo como:
     ```
     [LiveView] push: next_step
     ```
   - Si no ves este mensaje, el evento no se está enviando.

2. **Verifica los logs del servidor:**
   - En Railway, ve a los logs del servicio
   - Busca mensajes relacionados con `handle_event`
   - Si ves errores, esos son los problemas.

3. **Verifica la conexión de LiveView:**
   - En la consola del navegador, ejecuta:
     ```javascript
     window.liveSocket.isConnected()
     ```
   - Debería retornar `true`. Si retorna `false`, la conexión se perdió.

## Pasos de Diagnóstico

### Paso 1: Verificar la conexión de LiveView

1. Abre las herramientas de desarrollador (F12)
2. Ve a la pestaña "Console"
3. Ejecuta:
   ```javascript
   console.log('LiveSocket:', window.liveSocket);
   console.log('Connected:', window.liveSocket?.isConnected());
   ```
4. Si `liveSocket` es `undefined` o `isConnected()` retorna `false`, hay un problema con la conexión.

### Paso 2: Verificar los assets

1. Abre las herramientas de desarrollador (F12)
2. Ve a la pestaña "Network"
3. Recarga la página (Ctrl+F5)
4. Filtra por "JS" y "CSS"
5. Verifica que todos los archivos retornen 200 OK:
   - `app.js` (o `app-*.js`)
   - `app.css` (o `app-*.css`)
   - `pwa.js` (o `pwa-*.js`)

### Paso 3: Verificar los logs de Railway

1. Ve al dashboard de Railway
2. Selecciona tu servicio
3. Ve a la pestaña "Logs"
4. Busca:
   - Errores relacionados con `check_origin`
   - Errores relacionados con `LiveView`
   - Errores relacionados con assets

### Paso 4: Verificar la configuración de `check_origin`

1. Verifica que `PHX_HOST` esté configurado correctamente en Railway
2. Debe ser el dominio completo, por ejemplo:
   ```
   PHX_HOST=gaepell-soft-production.up.railway.app
   ```
3. Verifica que el `check_origin` en `config/runtime.exs` esté usando una función dinámica (no una lista estática)

## Soluciones Rápidas

### Solución 1: Forzar recompilación de assets

Si los assets no se están compilando correctamente:

1. En Railway, ve a tu servicio
2. Haz clic en "Settings"
3. Haz clic en "Redeploy"
4. Esto forzará una nueva compilación

### Solución 2: Limpiar cache del navegador

1. Presiona `Ctrl+Shift+Delete` (o `Cmd+Shift+Delete` en Mac)
2. Selecciona "Imágenes y archivos en caché"
3. Haz clic en "Borrar datos"
4. Recarga la página con `Ctrl+F5`

### Solución 3: Verificar variables de entorno

Asegúrate de que estas variables estén configuradas en Railway:

- `PHX_HOST` - El dominio completo de tu aplicación
- `PHX_SERVER` - Debe ser `true`
- `SECRET_KEY_BASE` - Debe estar configurado
- `DATABASE_URL` - Debe estar configurado

## Contacto

Si después de seguir estos pasos el problema persiste, proporciona:
1. Los logs completos de Railway (especialmente durante el build y el inicio)
2. Los mensajes de la consola del navegador
3. Una captura de pantalla del problema

