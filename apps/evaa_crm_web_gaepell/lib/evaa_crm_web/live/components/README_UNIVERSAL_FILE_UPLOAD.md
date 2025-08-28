# Sistema Universal de Archivos

Este sistema proporciona una solución completa y reutilizable para manejar la subida de archivos en toda la aplicación.

## Características

- ✅ **Drag & Drop** - Interfaz intuitiva para arrastrar archivos
- ✅ **Descripciones opcionales** - Cada archivo puede tener una descripción
- ✅ **Múltiples formatos** - Soporte para imágenes, PDFs, documentos, hojas de cálculo
- ✅ **Visualización con iconos** - Iconos específicos según el tipo de archivo
- ✅ **Eliminación segura** - Confirmación antes de eliminar archivos
- ✅ **Almacenamiento estructurado** - Metadatos en JSON para compatibilidad
- ✅ **Reutilizable** - Un solo componente para toda la aplicación

## Componentes

### 1. UniversalFileUpload Component

Componente LiveView reutilizable para subida de archivos.

```elixir
# Uso básico
<.live_component
  module={EvaaCrmWebGaepell.Components.UniversalFileUpload}
  id="unique-id"
  entity_type="truck"
  entity_id={@truck.id}
  upload_name={:truck_photos}
  existing_files={@truck.photos}
  show_upload_modal={@show_upload_modal}
  file_descriptions={@file_descriptions}
/>
```

#### Props requeridas:
- `id`: ID único del componente
- `entity_type`: Tipo de entidad (ej: "truck", "maintenance_ticket")
- `entity_id`: ID de la entidad
- `upload_name`: Nombre del upload (ej: :truck_photos)
- `existing_files`: Lista de archivos existentes
- `show_upload_modal`: Boolean para mostrar/ocultar el modal
- `file_descriptions`: Map con descripciones de archivos

#### Props opcionales:
- `title`: Título del modal (default: "Subir Archivos")
- `accept_types`: Tipos de archivo aceptados
- `max_entries`: Máximo número de archivos (default: 10)
- `max_file_size`: Tamaño máximo por archivo (default: 10MB)

### 2. FileUploadUtils

Módulo de utilidades para manejar archivos de manera universal.

```elixir
alias EvaaCrmWebGaepell.Utils.FileUploadUtils

# Procesar archivos subidos
uploaded_files = FileUploadUtils.process_uploaded_files(
  socket, 
  :truck_photos, 
  "truck", 
  truck_id, 
  file_descriptions
)

# Actualizar entidad con archivos
{:ok, updated_entity} = FileUploadUtils.update_entity_files(
  entity, 
  uploaded_files, 
  :photos
)

# Eliminar archivo
{:ok, updated_entity} = FileUploadUtils.delete_entity_file(
  entity, 
  file_index, 
  :photos
)
```

## Implementación Completa

### 1. Configurar el LiveView

```elixir
def mount(%{"id" => id}, _session, socket) do
  # Cargar entidad
  entity = get_entity(id)
  
  # Configurar uploads
  uploads = FileUploadUtils.configure_uploads(
    "truck", 
    id, 
    :truck_photos,
    max_entries: 10,
    max_file_size: 10_000_000
  )

  socket = 
    socket
    |> assign(:entity, entity)
    |> assign(:uploads, uploads)
    |> assign(:show_upload_modal, false)
    |> assign(:file_descriptions, %{})
    |> allow_upload(:truck_photos)

  {:ok, socket}
end
```

### 2. Renderizar el componente

```elixir
def render(assigns) do
  ~H"""
  <div>
    <!-- Componente de subida -->
    <.live_component
      module={EvaaCrmWebGaepell.Components.UniversalFileUpload}
      id="truck-files"
      entity_type="truck"
      entity_id={@entity.id}
      upload_name={:truck_photos}
      existing_files={@entity.photos}
      show_upload_modal={@show_upload_modal}
      file_descriptions={@file_descriptions}
      title="Subir Archivos del Camión"
    />
    
    <!-- Lista de archivos existentes -->
    <%= EvaaCrmWebGaepell.Components.UniversalFileUpload.render_file_list(%{
      existing_files: @entity.photos
    }) %>
  </div>
  """
end
```

### 3. Manejar eventos

```elixir
# Mostrar modal
def handle_event("show_upload_modal", _params, socket) do
  {:noreply, assign(socket, :show_upload_modal, true)}
end

# Cerrar modal
def handle_event("close_upload_modal", _params, socket) do
  {:noreply, 
   socket
   |> assign(:show_upload_modal, false)
   |> assign(:file_descriptions, %{})}
end

# Actualizar descripción
def handle_event("update_file_description", %{"ref" => ref, "value" => description}, socket) do
  file_descriptions = Map.put(socket.assigns.file_descriptions, ref, description)
  {:noreply, assign(socket, :file_descriptions, file_descriptions)}
end

# Cancelar upload
def handle_event("cancel_upload", %{"ref" => ref}, socket) do
  file_descriptions = Map.delete(socket.assigns.file_descriptions, ref)
  socket = assign(socket, :file_descriptions, file_descriptions)
  {:noreply, cancel_upload(socket, :truck_photos, ref)}
end

# Guardar archivos
def handle_event("save_attachments", _params, socket) do
  uploaded_files = FileUploadUtils.process_uploaded_files(
    socket, 
    :truck_photos, 
    "truck", 
    socket.assigns.entity.id, 
    socket.assigns.file_descriptions
  )

  if length(uploaded_files) > 0 do
    case FileUploadUtils.update_entity_files(
      socket.assigns.entity, 
      uploaded_files, 
      :photos
    ) do
      {:ok, updated_entity} ->
        {:noreply, 
         socket
         |> assign(:entity, updated_entity)
         |> assign(:show_upload_modal, false)
         |> assign(:file_descriptions, %{})
         |> put_flash(:info, "Archivos subidos correctamente")}
      
      {:error, _changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al guardar los archivos")}
    end
  else
    {:noreply, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})
     |> put_flash(:info, "No se seleccionaron archivos")}
  end
end

# Eliminar archivo
def handle_event("delete_file", %{"index" => index}, socket) do
  case FileUploadUtils.delete_entity_file(
    socket.assigns.entity, 
    String.to_integer(index), 
    :photos
  ) do
    {:ok, updated_entity} ->
      {:noreply, 
       socket
       |> assign(:entity, updated_entity)
       |> put_flash(:info, "Archivo eliminado correctamente")}
    
    {:error, :file_not_found} ->
      {:noreply, put_flash(socket, :error, "Archivo no encontrado")}
  end
end
```

## Estructura de Archivos

Los archivos se almacenan en:
```
priv/static/uploads/{entity_type}/{entity_id}/{timestamp}_{filename}
```

### Metadatos

Los archivos con descripciones se almacenan como JSON:
```json
{
  "path": "/uploads/truck/123/1703123456789_photo.jpg",
  "description": "Foto del daño frontal",
  "original_name": "photo.jpg",
  "size": 1024000,
  "content_type": "image/jpeg"
}
```

Los archivos sin descripción se almacenan como string simple:
```
/uploads/truck/123/1703123456789_photo.jpg
```

## Mapeo de Tipos de Entidad

```elixir
# Mapeo estándar de tipos a campos
%{
  "maintenance_ticket" => :damage_photos,
  "evaluation" => :photos,
  "truck" => :profile_photo,
  "quotation" => :attachments,
  "production_order" => :documents
}
```

## Formatos Soportados

- **Imágenes**: .jpg, .jpeg, .png, .gif
- **Documentos**: .pdf, .doc, .docx
- **Hojas de cálculo**: .xls, .xlsx
- **Texto**: .txt

## Configuración de Tamaños

- **Tamaño máximo por archivo**: 10MB (configurable)
- **Máximo número de archivos**: 10 (configurable)
- **Tipos aceptados**: Configurables por entidad

## Ventajas del Sistema

1. **Consistencia**: Misma interfaz en toda la aplicación
2. **Mantenibilidad**: Un solo lugar para cambios
3. **Reutilización**: No duplicar código
4. **Escalabilidad**: Fácil agregar nuevos tipos de entidad
5. **Experiencia de usuario**: Interfaz intuitiva y moderna
6. **Compatibilidad**: Soporte para archivos existentes

## Migración desde Sistemas Existentes

El sistema es compatible con archivos existentes. Los archivos sin descripción se mantienen como strings simples, mientras que los nuevos archivos pueden incluir metadatos en JSON.

## Ejemplos de Uso

Ver `universal_file_upload_example.ex` para ejemplos completos de implementación.

