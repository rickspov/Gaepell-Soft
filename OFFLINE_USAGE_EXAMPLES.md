# 📱 Ejemplos de Uso Offline - EVA CRM

## 🔄 **Cómo Funciona el Sistema Offline**

### **📋 Flujo de Sincronización:**

1. **Usuario está online** → Cambios se guardan directamente en BD
2. **Usuario pierde conexión** → Cambios se guardan en IndexedDB local
3. **Usuario recupera conexión** → Cambios se sincronizan automáticamente
4. **Indicadores visuales** → Usuario ve el estado de sincronización

---

## 🎯 **Ejemplos Prácticos**

### **📝 Ejemplo 1: Crear Cotización Offline**

```javascript
// En el formulario de cotizaciones
async function createQuotationOffline() {
  const quotationData = {
    client_name: "Empresa ABC",
    client_email: "contacto@empresaabc.com",
    client_phone: "+1 555-123-4567",
    quantity: 100,
    special_requirements: "Cajas especiales",
    total_cost: "2500.00",
    markup_percentage: "30.00",
    final_price: "3250.00",
    status: "draft"
  };

  try {
    // Intentar guardar online primero
    const response = await fetch('/quotations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(quotationData)
    });

    if (response.ok) {
      // Éxito online
      console.log('✅ Cotización guardada online');
    } else {
      throw new Error('Network error');
    }
  } catch (error) {
    // Fallback a offline
    console.log('📴 Guardando offline...');
    const offlineChange = await window.offlineUtils.createQuotationOffline(quotationData);
    
    // Mostrar en UI inmediatamente
    showOfflineQuotation(offlineChange);
  }
}
```

### **✏️ Ejemplo 2: Actualizar Cotización Offline**

```javascript
async function updateQuotationOffline(quotationId, updates) {
  try {
    // Intentar actualizar online
    const response = await fetch(`/quotations/${quotationId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates)
    });

    if (response.ok) {
      console.log('✅ Cotización actualizada online');
    } else {
      throw new Error('Network error');
    }
  } catch (error) {
    // Fallback a offline
    console.log('📴 Actualizando offline...');
    const offlineChange = await window.offlineUtils.updateQuotationOffline(quotationId, updates);
    
    // Actualizar UI inmediatamente
    updateOfflineQuotation(offlineChange);
  }
}
```

### **📊 Ejemplo 3: Crear Lead Offline**

```javascript
async function createLeadOffline() {
  const leadData = {
    name: "Juan Pérez",
    email: "juan@empresa.com",
    phone: "+1 555-987-6543",
    company: "Empresa XYZ",
    source: "referral",
    notes: "Cliente potencial interesado en cotización"
  };

  try {
    // Intentar guardar online
    const response = await fetch('/leads', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(leadData)
    });

    if (response.ok) {
      console.log('✅ Lead guardado online');
    } else {
      throw new Error('Network error');
    }
  } catch (error) {
    // Fallback a offline
    console.log('📴 Guardando lead offline...');
    const offlineChange = await window.offlineUtils.createLeadOffline(leadData);
    
    // Mostrar en UI inmediatamente
    showOfflineLead(offlineChange);
  }
}
```

---

## 🎨 **Indicadores Visuales**

### **📱 Indicador de Estado Offline**

```html
<!-- Se muestra automáticamente cuando hay cambios pendientes -->
<div id="offline-indicator" class="fixed top-4 right-4 bg-yellow-500 text-white px-4 py-2 rounded-lg shadow-lg z-50">
  <div class="flex items-center space-x-2">
    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
      <path d="M3.707 2.293a1 1 0 00-1.414 1.414l6.921 6.922c.05.062.105.118.168.167l6.91 6.911a1 1 0 001.415-1.414l-.675-.675a9.001 9.001 0 00-.668-11.982A1 1 0 1014.95 5.05a7.002 7.002 0 01.657 9.143l-1.435-1.435a5.002 5.002 0 00-.636-6.294A1 1 0 0010.293 7.88c.924.923 1.12 2.3.587 3.415l-1.992-1.992a.317.317 0 00-.457-.457l-1.992-1.992a1 1 0 00-1.414 0z"/>
    </svg>
    <span>Modo Offline - 3 cambios pendientes</span>
  </div>
</div>
```

### **🔄 Indicador de Sincronización**

```html
<!-- Se muestra cuando se sincronizan cambios -->
<div class="fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50">
  <div class="flex items-center space-x-2">
    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
      <path d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"/>
    </svg>
    <span>Sincronizado: 3 exitosos, 0 errores</span>
  </div>
</div>
```

---

## 🔧 **Integración con LiveView**

### **📝 En QuotationsLive**

```elixir
# En quotations_live.ex
def handle_event("save_quotation", %{"quotation" => quotation_params}, socket) do
  case save_quotation(quotation_params) do
    {:ok, quotation} ->
      {:noreply, 
       socket 
       |> put_flash(:success, "Cotización guardada exitosamente")
       |> assign(:quotations, load_quotations())}
    
    {:error, _changeset} ->
      # Si falla, el JavaScript manejará el guardado offline
      {:noreply, socket}
  end
end

def handle_event("show_offline_quotation", %{"change" => change}, socket) do
  # Mostrar cotización offline en la UI
  {:noreply, 
   socket 
   |> put_flash(:info, "Cotización guardada offline - se sincronizará cuando haya conexión")
   |> assign(:offline_quotations, [change | socket.assigns.offline_quotations])}
end
```

### **🎨 En el Template**

```heex
<!-- En quotations_live.html.heex -->
<div class="space-y-4">
  <!-- Cotizaciones normales -->
  <%= for quotation <- @quotations do %>
    <div class="bg-white p-4 rounded-lg shadow">
      <h3><%= quotation.client_name %></h3>
      <p><%= quotation.quotation_number %></p>
    </div>
  <% end %>
  
  <!-- Cotizaciones offline -->
  <%= for change <- @offline_quotations do %>
    <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-lg shadow">
      <div class="flex items-center">
        <svg class="w-5 h-5 text-yellow-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path d="M3.707 2.293a1 1 0 00-1.414 1.414l6.921 6.922c.05.062.105.118.168.167l6.91 6.911a1 1 0 001.415-1.414l-.675-.675a9.001 9.001 0 00-.668-11.982A1 1 0 1014.95 5.05a7.002 7.002 0 01.657 9.143l-1.435-1.435a5.002 5.002 0 00-.636-6.294A1 1 0 0010.293 7.88c.924.923 1.12 2.3.587 3.415l-1.992-1.992a.317.317 0 00-.457-.457l-1.992-1.992a1 1 0 00-1.414 0z"/>
        </svg>
        <h3 class="text-yellow-800"><%= change.data.client_name %></h3>
        <span class="ml-auto text-yellow-600 text-sm">Offline</span>
      </div>
      <p class="text-yellow-700 mt-1">Pendiente de sincronización</p>
    </div>
  <% end %>
</div>
```

---

## 🧪 **Pruebas del Sistema Offline**

### **📱 Simular Offline en Chrome DevTools:**

1. **Abrir DevTools** (F12)
2. **Ir a Network tab**
3. **Marcar "Offline"**
4. **Intentar crear/editar datos**
5. **Verificar que se guardan offline**
6. **Desmarcar "Offline"**
7. **Verificar sincronización automática**

### **🔍 Verificar Datos Offline:**

```javascript
// En la consola del navegador
// Ver cambios pendientes
window.offlineSync.getPendingChanges().then(changes => {
  console.log('Cambios pendientes:', changes);
});

// Ver datos cacheados
window.offlineSync.getCachedData('quotations').then(data => {
  console.log('Datos cacheados:', data);
});
```

---

## 🎯 **Beneficios para Gaepell**

### **✅ Ventajas del Sistema Offline:**

1. **Trabajo sin interrupciones** - Los usuarios pueden seguir trabajando sin conexión
2. **Datos seguros** - Los cambios se guardan localmente hasta que hay conexión
3. **Sincronización automática** - No requiere intervención manual
4. **Indicadores claros** - El usuario sabe cuándo está offline y qué está pendiente
5. **Experiencia fluida** - La app funciona igual online y offline

### **📊 Casos de Uso Típicos:**

- **Vendedores en campo** - Crear cotizaciones sin conexión
- **Trabajo en zonas con mala señal** - Continuar trabajando normalmente
- **Interrupciones de internet** - No perder trabajo en progreso
- **Sincronización automática** - Datos se actualizan cuando hay conexión

---

## 🚀 **Próximos Pasos**

1. **Probar el sistema** en desarrollo
2. **Implementar en LiveViews** específicos
3. **Agregar más tipos de datos** (actividades, leads, etc.)
4. **Mejorar indicadores visuales**
5. **Agregar conflict resolution** para cambios simultáneos 