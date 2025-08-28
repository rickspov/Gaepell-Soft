defmodule EvaaCrmWebGaepell.Components.UniversalFileUpload do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form

  @doc """
  Componente universal para subida de archivos.
  
  Props requeridas:
  - id: ID único del componente
  - entity_type: Tipo de entidad (ej: "truck", "maintenance_ticket", "evaluation")
  - entity_id: ID de la entidad
  - upload_name: Nombre del upload (ej: :truck_photos, :ticket_attachments)
  - existing_files: Lista de archivos existentes
  - show_upload_modal: Boolean para mostrar/ocultar el modal
  - file_descriptions: Map con descripciones de archivos
  
  Props opcionales:
  - title: Título del modal (default: "Subir Archivos")
  - accept_types: Tipos de archivo aceptados (default: ".jpg,.jpeg,.png,.gif,.pdf,.doc,.docx,.txt,.xlsx,.xls")
  - max_entries: Máximo número de archivos (default: 10)
  - max_file_size: Tamaño máximo por archivo en bytes (default: 10_000_000)
  """
  
  def render(assigns) do
    ~H"""
    <div>
      <!-- Botón para abrir modal -->
      <button phx-click="show_upload_modal" phx-target={@myself} class="px-3 py-1 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors text-sm">
        <svg class="w-4 h-4 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
        </svg>
        Subir Archivo
      </button>

      <!-- Modal de Upload -->
      <%= if @show_upload_modal do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-md w-full mx-4">
            <div class="p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
                  <%= @title || "Subir Archivos" %>
                </h3>
                <button phx-click="close_upload_modal" phx-target={@myself} class="p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                  </svg>
                </button>
              </div>

              <form id={"upload-form-#{@id}"} phx-submit="save_attachments" phx-change="validate_attachments" phx-target={@myself} phx-hook="UploadModal">
                <div class="space-y-4">
                  <!-- Zona de arrastrar y soltar -->
                  <div class="border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg p-6 text-center">
                    <svg class="h-12 w-12 mx-auto mb-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
                    </svg>
                    
                    <div class="space-y-2">
                      <div class="text-slate-600 dark:text-slate-400">
                        <p class="text-sm">Arrastra archivos aquí o</p>
                      </div>
                      
                      <.live_file_input upload={@uploads[@upload_name]} 
                          class="hidden" 
                          id={"file-input-#{@id}"}
                          accept={@accept_types}
                          phx-change="validate_attachments" 
                          phx-target={@myself} />
                      
                      <label for={"file-input-#{@id}"} class="cursor-pointer inline-flex items-center px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
                        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
                        </svg>
                        Seleccionar archivos
                      </label>
                    </div>
                    
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-2">
                      Formatos: JPG, PNG, GIF, PDF, DOC, XLS (máx. <%= @max_file_size / 1_000_000 %>MB)
                    </p>
                  </div>

                  <!-- Lista de archivos seleccionados -->
                  <%= if length(@uploads[@upload_name].entries) > 0 do %>
                    <div class="space-y-3">
                      <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300">Archivos seleccionados:</h4>
                      <%= for entry <- @uploads[@upload_name].entries do %>
                        <div class="border border-slate-200 dark:border-slate-600 rounded-lg p-3 bg-slate-50 dark:bg-slate-700">
                          <!-- Información del archivo -->
                          <div class="flex items-center justify-between mb-3">
                            <div class="flex items-center space-x-2">
                              <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                              </svg>
                              <span class="text-sm font-medium text-slate-700 dark:text-slate-300"><%= entry.client_name %></span>
                            </div>
                            <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} phx-target={@myself} class="p-1 hover:bg-slate-200 dark:hover:bg-slate-600 rounded">
                              <svg class="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                              </svg>
                            </button>
                          </div>

                          <!-- Campo de descripción -->
                          <div class="space-y-2">
                            <label class="block text-xs font-medium text-slate-600 dark:text-slate-400">
                              Descripción (opcional):
                            </label>
                            <input type="text" 
                                   placeholder="Ej: Foto del daño frontal, Documento de autorización..."
                                   value={Map.get(@file_descriptions || %{}, entry.ref, "")}
                                   phx-keyup="update_file_description"
                                   phx-value-ref={entry.ref}
                                   phx-target={@myself}
                                   class="w-full px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-600 dark:text-white">
                          </div>

                          <!-- Barra de progreso -->
                          <div class="w-full bg-slate-200 dark:bg-slate-600 rounded-full h-2 mt-3">
                            <div class="bg-blue-600 h-2 rounded-full transition-all duration-300" style={"width: #{entry.progress}%"}></div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>

                                     <!-- Errores de upload -->
                   <%= for err <- upload_errors(@uploads[@upload_name]) do %>
                     <div class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                       <p class="text-sm text-red-600 dark:text-red-400"><%= error_to_string_helper(err) %></p>
                     </div>
                   <% end %>
                </div>

                <!-- Botones del modal -->
                <div class="flex justify-end space-x-3 mt-6">
                  <button type="button" phx-click="close_upload_modal" phx-target={@myself}
                          class="px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                    Cancelar
                  </button>
                  <button type="submit"
                          class="px-4 py-2 bg-blue-600 border border-transparent rounded-lg text-sm font-medium text-white hover:bg-blue-700 transition-colors">
                    Subir Archivos
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})
     |> assign(:parent_pid, self())}
  end

  @doc """
  Renderiza la lista de archivos existentes
  """
  def render_file_list(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4" id="file-list">
      <%= if length(@existing_files || []) == 0 do %>
        <div class="col-span-full text-center py-8 text-slate-500 dark:text-slate-400">
          <svg class="h-12 w-12 mx-auto mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
          </svg>
          <p>No hay archivos adjuntos</p>
          <p class="text-sm">Haz clic en "Subir Archivo" para agregar documentos o fotos</p>
        </div>
      <% else %>
        <%= for {file, index} <- Enum.with_index(@existing_files || []) do %>
          <% file_info = parse_file_info(file) %>
          <div class="flex items-center gap-3 p-3 border rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors">
            <div class="relative flex-shrink-0">
              <%= if String.ends_with?(String.downcase(file_info.path), [".jpg", ".jpeg", ".png", ".gif"]) do %>
                <img src={file_info.path} 
                     alt="Imagen" 
                     class="h-12 w-12 rounded-lg object-cover bg-slate-100 dark:bg-slate-600"
                     loading="lazy"
                     onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="h-12 w-12 bg-slate-100 dark:bg-slate-600 rounded-lg flex items-center justify-center" style="display: none;">
                  <svg class="h-6 w-6 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                  </svg>
                </div>
                <svg class="absolute -top-1 -right-1 h-4 w-4 text-blue-600 bg-white dark:bg-slate-800 rounded-full p-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
              <% else %>
                <div class="h-12 w-12 bg-slate-100 dark:bg-slate-600 rounded-lg flex items-center justify-center">
                  <%= cond do %>
                    <% String.ends_with?(String.downcase(file_info.path), ".pdf") -> %>
                      <svg class="h-6 w-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                      </svg>
                    <% String.ends_with?(String.downcase(file_info.path), [".doc", ".docx"]) -> %>
                      <svg class="h-6 w-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                      </svg>
                    <% String.ends_with?(String.downcase(file_info.path), [".xls", ".xlsx"]) -> %>
                      <svg class="h-6 w-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"/>
                      </svg>
                    <% true -> %>
                      <svg class="h-6 w-6 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                      </svg>
                  <% end %>
                </div>
              <% end %>
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium truncate">
                <%= file_info.original_name %>
              </p>
              <%= if file_info.description && file_info.description != "" do %>
                <p class="text-sm text-blue-600 dark:text-blue-400 font-medium">
                  <%= file_info.description %>
                </p>
              <% end %>
              <p class="text-sm text-slate-500 dark:text-slate-400">
                <%= get_file_type_label(file_info.path) %>
              </p>
            </div>
            <div class="flex items-center space-x-2">
              <a href={file_info.path} target="_blank" class="p-2 text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors" title="Ver archivo">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                </svg>
              </a>
              <button phx-click="show_delete_modal" phx-value-index={index} phx-target={@myself} class="p-2 text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors" title="Eliminar archivo">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                </svg>
              </button>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Funciones auxiliares
  defp parse_file_info(file_info) when is_binary(file_info) do
    case Jason.decode(file_info) do
      {:ok, parsed} -> 
        # Es un archivo con descripción
        %{
          path: parsed["path"] || file_info,
          description: parsed["description"],
          original_name: parsed["original_name"] || Path.basename(parsed["path"] || file_info),
          size: parsed["size"],
          content_type: parsed["content_type"]
        }
      {:error, _} -> 
        # Es un archivo sin descripción (solo ruta)
        %{
          path: file_info,
          description: nil,
          original_name: Path.basename(file_info),
          size: nil,
          content_type: nil
        }
    end
  end
  
  defp parse_file_info(file_info) do
    # Fallback para cualquier otro tipo de dato
    %{
      path: to_string(file_info),
      description: nil,
      original_name: "archivo",
      size: nil,
      content_type: nil
    }
  end

  defp get_file_type_label(path) do
    cond do
      String.ends_with?(String.downcase(path), [".jpg", ".jpeg", ".png", ".gif"]) ->
        "Imagen"
      String.ends_with?(String.downcase(path), ".pdf") ->
        "Documento PDF"
      String.ends_with?(String.downcase(path), [".doc", ".docx"]) ->
        "Documento Word"
      String.ends_with?(String.downcase(path), [".xls", ".xlsx"]) ->
        "Hoja de cálculo"
      true ->
        "Archivo"
    end
  end

  defp error_to_string_helper(:too_large), do: "El archivo es demasiado grande"
  defp error_to_string_helper(:too_many_files), do: "Demasiados archivos"
  defp error_to_string_helper(:not_accepted), do: "Tipo de archivo no aceptado"
  defp error_to_string_helper(_), do: "Error al subir el archivo"

  # Event handlers
  def handle_event("show_upload_modal", _params, socket) do
    IO.inspect("show_upload_modal called in component", label: "[DEBUG]")
    {:noreply, assign(socket, :show_upload_modal, true)}
  end

  def handle_event("close_upload_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})}
  end

  def handle_event("validate_attachments", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("update_file_description", %{"ref" => ref, "value" => description}, socket) do
    file_descriptions = Map.put(socket.assigns.file_descriptions, ref, description)
    {:noreply, assign(socket, :file_descriptions, file_descriptions)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    file_descriptions = Map.delete(socket.assigns.file_descriptions, ref)
    socket = assign(socket, :file_descriptions, file_descriptions)
    {:noreply, cancel_upload(socket, socket.assigns.upload_name, ref)}
  end

  def handle_event("save_attachments", _params, socket) do
    IO.inspect("save_attachments called in component", label: "[DEBUG]")
    # Por ahora, solo cerrar el modal sin procesar archivos
    # Esto nos ayudará a identificar si el problema está en el procesamiento de archivos
    {:noreply, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})}
  end

  def handle_event("show_delete_modal", %{"index" => index}, socket) do
    # Enviar el evento al LiveView padre usando send
    send(socket.assigns.parent_pid, {:delete_file, index})
    {:noreply, socket}
  end
end

