defmodule EvaaCrmWebGaepell.MaintenanceCheckinWizardLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Repo, Truck, MaintenanceTicket, User, ActivityLog}
  alias EvaaCrmWebGaepell.Utils.FileUploadUtils
  import Ecto.Query
  import Path

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil
    
    # Obtener marcas, modelos y propietarios existentes para autocompletado
    existing_brands = get_existing_brands()
    existing_models = get_existing_models()
    existing_owners = get_existing_owners()
    
    socket =
      socket
      |> assign(current_step: 1, total_steps: 6, current_user: current_user)
      |> assign(scenario: nil, entry_type: nil)
      |> assign(found_truck: nil, new_truck: nil)
      |> assign(ticket_form: %{})
      |> assign(maintenance_form_data: %{})
      |> assign(photo_uploads: %{})
      |> assign(photo_entries: %{})
      |> assign(photo_errors: %{})
      |> assign(signature_data: nil)
      |> assign(search_plate: nil)
      |> assign(show_search_modal: false)
      |> assign(show_existing_trucks_modal: false)
      |> assign(show_new_truck_form: false)
      |> assign(selected_truck_id: nil)
      |> assign(filtered_trucks: [])
      |> assign(created_ticket: nil)
      |> assign(:existing_brands, existing_brands)
      |> assign(:existing_models, existing_models)
      |> assign(:existing_owners, existing_owners)
      |> assign(:show_upload_modal, false)
      |> assign(:file_descriptions, %{})
      |> assign(:existing_files, [])
                           |> allow_upload(:maintenance_photos, accept: ~w(.jpg .jpeg .png .gif .pdf .doc .docx .txt .xlsx .xls), max_entries: 10, max_file_size: 10_000_000, auto_upload: false)
    
    if is_nil(current_user) do
      {:ok, socket |> put_flash(:error, "Debes iniciar sesión para crear tickets.") |> push_navigate(to: "/login")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("select_scenario", %{"scenario" => scenario}, socket) do
    {new_step, entry_type} =
      case scenario do
        "maintenance_checkin" -> {2, :maintenance}
        _ -> {1, nil}
      end

    # Cargar camiones existentes para el paso 2
    socket = if new_step == 2 do
      trucks = from t in Truck,
              where: t.business_id == ^socket.assigns.current_user.business_id,
              order_by: [asc: t.brand, asc: t.model]
      trucks = Repo.all(trucks)
      assign(socket, :filtered_trucks, trucks)
    else
      socket
    end

    {:noreply, 
     socket
     |> assign(current_step: new_step, scenario: scenario, entry_type: entry_type)}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    current_step = socket.assigns.current_step
    total_steps = socket.assigns.total_steps
    
    if current_step < total_steps do
      {:noreply, assign(socket, current_step: current_step + 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    current_step = socket.assigns.current_step
    
    if current_step > 1 do
      {:noreply, assign(socket, current_step: current_step - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("back_to_start", _params, socket) do
    {:noreply, 
     socket
     |> assign(current_step: 1, scenario: nil, entry_type: nil)
     |> assign(found_truck: nil, new_truck: nil)
     |> assign(ticket_form: %{}, maintenance_form_data: %{})}
  end

  @impl true
  def handle_event("search_plate", %{"plate" => plate}, socket) do
    truck = Repo.get_by(Truck, license_plate: plate)
    
    if truck do
      {:noreply, 
       socket
       |> assign(found_truck: truck, search_plate: plate)
       |> assign(current_step: 3)}
    else
      {:noreply, 
       socket
       |> put_flash(:error, "No se encontró el camión con placa #{plate}")
       |> assign(search_plate: plate)}
    end
  end

  @impl true
  def handle_event("show_existing_trucks_modal", _params, socket) do
    {:noreply, assign(socket, show_existing_trucks_modal: true)}
  end

  @impl true
  def handle_event("hide_existing_trucks_modal", _params, socket) do
    {:noreply, assign(socket, show_existing_trucks_modal: false)}
  end

  @impl true
  def handle_event("show_new_truck_form", _params, socket) do
    {:noreply, assign(socket, show_new_truck_form: true)}
  end

  @impl true
  def handle_event("hide_new_truck_form", _params, socket) do
    {:noreply, assign(socket, show_new_truck_form: false)}
  end

  @impl true
  def handle_event("select_truck", %{"truck-id" => truck_id}, socket) do
    truck = Repo.get(Truck, truck_id)
    
    if truck do
      socket = socket
        |> assign(found_truck: truck, show_existing_trucks_modal: false)
        |> assign(current_step: 4)
        |> allow_upload(:maintenance_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
      
      {:noreply, socket}
    else
      {:noreply, 
       socket
       |> put_flash(:error, "Camión no encontrado")
       |> assign(show_existing_trucks_modal: false)}
    end
  end

  @impl true
  def handle_event("register_new_truck", _params, socket) do
    {:noreply, assign(socket, show_new_truck_form: true)}
  end

  @impl true
  def handle_event("save_new_truck", %{"truck" => truck_params}, socket) do
    params = Map.merge(truck_params, %{
      business_id: socket.assigns.current_user.business_id
    })
    
    case Truck.create_truck(params, socket.assigns.current_user.id) do
      {:ok, truck} ->
        {:noreply, 
         socket
         |> assign(found_truck: truck, new_truck: nil, show_new_truck_form: false)
         |> assign(current_step: 4)
         |> allow_upload(:maintenance_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
         |> put_flash(:info, "Camión registrado exitosamente")}
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(new_truck: changeset)
         |> put_flash(:error, "Error al registrar el camión")}
    end
  end

  @impl true
  def handle_event("maintenance_field_changed", %{"maintenance" => maintenance_params}, socket) do
    current_data = socket.assigns.maintenance_form_data
    updated_data = Map.merge(current_data, maintenance_params)
    
    {:noreply, assign(socket, maintenance_form_data: updated_data)}
  end

  @impl true
  def handle_event("maintenance_field_changed", %{"field" => field, "value" => value}, socket) do
    current_data = socket.assigns.maintenance_form_data || %{}
    
    updated_data = case field do
      "maintenance_areas" ->
        areas = current_data["maintenance_areas"] || []
        if value in areas do
          Map.put(current_data, "maintenance_areas", List.delete(areas, value))
        else
          Map.put(current_data, "maintenance_areas", [value | areas])
        end
      _ ->
        Map.put(current_data, field, value)
    end
    
    {:noreply, assign(socket, :maintenance_form_data, updated_data)}
  end

  @impl true
  def handle_event("maintenance_field_changed", %{"field" => field}, socket) do
    # Handle radio buttons and checkboxes without value
    current_data = socket.assigns.maintenance_form_data || %{}
    updated_data = Map.put(current_data, field, true)
    {:noreply, assign(socket, :maintenance_form_data, updated_data)}
  end

  @impl true
  def handle_event("submit_maintenance", _params, socket) do
    case create_maintenance_ticket(socket) do
      {:ok, ticket} ->
        {:noreply, 
         socket
         |> assign(created_ticket: ticket, current_step: 6)
         |> put_flash(:info, "Ticket de mantenimiento creado exitosamente")}
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(maintenance_form_data: changeset)
         |> put_flash(:error, "Error al crear el ticket de mantenimiento")}
    end
  end

  @impl true
  def handle_event("validate_photos", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    file_descriptions = Map.delete(socket.assigns.file_descriptions, ref)
    socket = assign(socket, :file_descriptions, file_descriptions)
    {:noreply, cancel_upload(socket, :maintenance_photos, ref)}
  end

  @impl true
  def handle_event("validate_attachments", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_file_description", %{"ref" => ref, "value" => description}, socket) do
    file_descriptions = Map.put(socket.assigns.file_descriptions, ref, description)
    {:noreply, assign(socket, :file_descriptions, file_descriptions)}
  end

  @impl true
  def handle_event("show_upload_modal", _params, socket) do
    {:noreply, assign(socket, :show_upload_modal, true)}
  end

  @impl true
  def handle_event("close_upload_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})}
  end

  @impl true
  def handle_event("validate_attachments", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save_attachments", _params, socket) do
    IO.inspect("Save attachments event triggered", label: "[DEBUG]")
    
    # Procesar archivos subidos usando el mismo enfoque que ticket_detail_live
    uploaded_files = consume_uploaded_entries(socket, :maintenance_photos, fn %{path: path}, entry ->
      IO.inspect("Processing file: #{entry.client_name}", label: "[DEBUG]")
      
      # Crear directorio para archivos si no existe
      upload_dir = Path.join(["priv", "static", "uploads", "maintenance", "temp"])
      File.mkdir_p!(upload_dir)
      
      # Generar nombre único para el archivo usando timestamp y nombre original
      timestamp = System.system_time(:millisecond)
      unique_filename = "#{timestamp}_#{entry.client_name}"
      dest_path = Path.join(upload_dir, unique_filename)
      
      # Copiar archivo
      File.cp!(path, dest_path)
      
      # Obtener descripción del archivo
      description = Map.get(socket.assigns.file_descriptions, entry.ref, "")
      
      file_info = %{
        original_name: entry.client_name,
        filename: unique_filename,
        path: "/uploads/maintenance/temp/#{unique_filename}",
        size: entry.client_size,
        content_type: entry.client_type,
        description: description
      }
      
      IO.inspect(file_info, label: "[DEBUG] File info")
      IO.inspect("File copied successfully to: #{dest_path}", label: "[DEBUG]")
      {:ok, file_info}
    end)

    IO.inspect(uploaded_files, label: "[DEBUG] Uploaded files")
    IO.inspect(length(uploaded_files), label: "[DEBUG] Number of uploaded files")

    if length(uploaded_files) > 0 do
      IO.inspect("Files uploaded successfully", label: "[DEBUG]")
      
      # Actualizar la lista de archivos existentes
      existing_files = socket.assigns.existing_files ++ uploaded_files
      
      {:noreply, 
       socket
       |> assign(:existing_files, existing_files)
       |> assign(:show_upload_modal, false)
       |> assign(:file_descriptions, %{})
       |> put_flash(:info, "Archivos subidos correctamente")}
    else
      IO.inspect("No files to upload", label: "[DEBUG]")
      {:noreply, 
       socket
       |> assign(:show_upload_modal, false)
       |> assign(:file_descriptions, %{})
       |> put_flash(:info, "No se seleccionaron archivos")}
    end
  end

  @impl true
  def handle_event("remove_file", %{"file_path" => file_path}, socket) do
    # Encontrar el índice del archivo en la lista
    file_index = Enum.find_index(socket.assigns.existing_files, fn file -> file.path == file_path end)
    
    if file_index do
      if socket.assigns.created_ticket do
        case FileUploadUtils.delete_entity_file(
          socket.assigns.created_ticket, 
          file_index, 
          :damage_photos
        ) do
          {:ok, updated_ticket} ->
            # Actualizar la lista de archivos existentes
            existing_photos = FileUploadUtils.get_entity_files(updated_ticket, "maintenance", FileUploadUtils.standard_field_mapping())
            
            {:noreply, 
             socket
             |> assign(:created_ticket, updated_ticket)
             |> assign(:existing_files, existing_photos)
             |> put_flash(:info, "Archivo eliminado correctamente")}
          
          {:error, :file_not_found} ->
            {:noreply, put_flash(socket, :error, "Archivo no encontrado")}
        end
      else
        # Si no hay ticket creado, solo eliminar del estado local
        existing_files = List.delete_at(socket.assigns.existing_files, file_index)
        {:noreply, 
         socket
         |> assign(:existing_files, existing_files)
         |> put_flash(:info, "Archivo eliminado correctamente")}
      end
    else
      {:noreply, put_flash(socket, :error, "Archivo no encontrado")}
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :progress_percentage, get_progress_percentage(assigns.current_step, assigns.total_steps))
    
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-slate-900 dark:text-slate-100 mb-2">
          Check-in de Mantenimiento
        </h1>
        <p class="text-slate-600 dark:text-slate-400">
          Complete la información paso a paso para crear un nuevo ticket de mantenimiento
        </p>
      </div>

      <!-- Progress Bar -->
      <div class="space-y-2 mb-8">
        <div class="flex justify-between text-sm text-slate-600 dark:text-slate-400">
          <span>Paso <%= @current_step %> de <%= @total_steps %></span>
          <span><%= round(@progress_percentage) %>% completado</span>
        </div>
        <div class="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
          <div class="bg-red-600 h-2 rounded-full transition-all duration-500 ease-out" 
               style={"width: #{@progress_percentage}%"}>
          </div>
        </div>
      </div>

      <!-- Steps Navigation -->
      <div class="flex justify-between mb-8">
        <%= for step <- 1..@total_steps do %>
          <div class={get_step_container_classes(step, @total_steps)}>
            <div class={"inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium mb-2 transition-all duration-200 " <> get_step_classes(@current_step, step)}>
              <%= if @current_step > step do %>
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
              <% else %>
                <%= step %>
              <% end %>
            </div>
            <div class="text-xs">
              <p class="font-medium text-slate-900 dark:text-slate-100">
                <%= get_step_title(step) %>
              </p>
              <p class="text-slate-500 dark:text-slate-400">
                <%= get_step_description(step) %>
              </p>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Step Content -->
      <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-slate-200 dark:border-slate-700">
        <div class="p-6 border-b border-slate-200 dark:border-slate-700">
          <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
            <%= get_step_title(@current_step) %>
          </h2>
          <p class="text-slate-600 dark:text-slate-400 mt-1">
            <%= get_step_description(@current_step) %>
          </p>
        </div>
        
        <div class="p-6">
          <%= render_step_content(assigns) %>
        </div>
      </div>

      <!-- Navigation Buttons -->
      <div class="flex justify-between mt-8">
        <div class="flex gap-3">
          <button phx-click="back_to_start" 
                  class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
            Cancelar
          </button>
          <%= if @current_step > 1 do %>
            <button phx-click="prev_step" 
                    class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors flex items-center gap-2">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
              Anterior
            </button>
          <% end %>
        </div>
        
        <div>
          <%= if @current_step < @total_steps do %>
            <button phx-click="next_step" 
                    class="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-lg hover:bg-red-700 transition-colors flex items-center gap-2">
              Siguiente
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
            </button>
          <% end %>
        </div>
      </div>
    </div>

    <!-- Modal de Upload -->
    <%= if @show_upload_modal do %>
      <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
                Subir Fotos y Documentos
              </h3>
              <button phx-click="close_upload_modal" class="p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>

                                                                 <div class="space-y-4">
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
                    
                                                                                   <.live_file_input upload={@uploads.maintenance_photos} 
                          class="hidden" 
                          id="file-input-maintenance"
                          accept=".jpg,.jpeg,.png,.gif,.pdf,.doc,.docx,.txt,.xlsx,.xls"
                          phx-change="validate_attachments" />
                    
                    <label for="file-input-maintenance" class="cursor-pointer inline-flex items-center px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
                      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
                      </svg>
                      Seleccionar archivos
                    </label>
                  </div>
                  
                  <p class="text-xs text-slate-500 dark:text-slate-400 mt-2">
                    Formatos: JPG, PNG, GIF, PDF, DOC, XLS (máx. 10MB)
                  </p>
                </div>

                <!-- Lista de archivos seleccionados -->
                <%= if length(@uploads.maintenance_photos.entries) > 0 do %>
                  <div class="space-y-3">
                    <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300">Archivos seleccionados:</h4>
                    <%= for entry <- @uploads.maintenance_photos.entries do %>
                      <div class="border border-slate-200 dark:border-slate-600 rounded-lg p-3 bg-slate-50 dark:bg-slate-700">
                        <!-- Información del archivo -->
                        <div class="flex items-center justify-between mb-3">
                          <div class="flex items-center space-x-2">
                            <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                            <span class="text-sm font-medium text-slate-700 dark:text-slate-300"><%= entry.client_name %></span>
                          </div>
                          <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} class="p-1 hover:bg-slate-200 dark:hover:bg-slate-600 rounded">
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
                <%= for err <- upload_errors(@uploads.maintenance_photos) do %>
                  <div class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                    <p class="text-sm text-red-600 dark:text-red-400"><%= error_to_string_helper(err) %></p>
                  </div>
                <% end %>
              </div>

              <!-- Botones del modal -->
              <div class="flex justify-end space-x-3 mt-6">
                <button type="button" phx-click="close_upload_modal"
                        class="px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                  Cancelar
                </button>
                                                 <button type="button" phx-click="save_attachments"
                        disabled={length(@uploads.maintenance_photos.entries) == 0}
                        class="px-4 py-2 bg-blue-600 border border-transparent rounded-lg text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed">
                  Subir Archivos
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_step_content(assigns) do
    case assigns.current_step do
      1 -> render_scenario_selection(assigns)
      2 -> render_truck_search(assigns)
      3 -> render_truck_info(assigns)
      4 -> render_ticket_details(assigns)
      5 -> render_confirmation(assigns)
      6 -> render_ticket_created(assigns)
      _ -> "Paso no implementado"
    end
  end

  defp render_scenario_selection(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-6">
      <button phx-click="select_scenario" phx-value-scenario="maintenance_checkin" 
              class="w-full py-8 rounded-lg bg-red-500 text-white text-xl font-semibold shadow hover:bg-red-600 transition flex items-center justify-center gap-3">
        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
        </svg>
        <span>🛠️ Check-in de Mantenimiento</span>
      </button>
    </div>
    """
  end

  defp render_truck_search(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="text-center">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">
          Seleccionar Camión
        </h3>
        <p class="text-slate-600 dark:text-slate-400">
          Elige un camión existente o registra uno nuevo
        </p>
      </div>
      
      <div class="grid grid-cols-1 gap-4">
        <button phx-click="show_existing_trucks_modal" 
                class="w-full py-6 rounded-lg bg-green-500 text-white text-lg font-semibold shadow hover:bg-green-600 transition flex items-center justify-center gap-3">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
          </svg>
          Seleccionar Camión Existente
        </button>
        
        <button phx-click="show_new_truck_form" 
                class="w-full py-6 rounded-lg bg-blue-500 text-white text-lg font-semibold shadow hover:bg-blue-600 transition flex items-center justify-center gap-3">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          Registrar Nuevo Camión
        </button>
      </div>
    </div>
    """
  end

  defp render_truck_info(assigns) do
    if assigns.found_truck do
      ~H"""
      <div class="space-y-6">
        <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
          <div class="flex items-center gap-3">
            <svg class="h-6 w-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <div>
              <h3 class="font-semibold text-green-800 dark:text-green-200">Camión Encontrado</h3>
              <p class="text-sm text-green-700 dark:text-green-300">Información del camión registrado</p>
            </div>
          </div>
        </div>
        
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">Placa</label>
            <p class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= @found_truck.license_plate %></p>
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">Marca</label>
            <p class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= @found_truck.brand %></p>
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">Modelo</label>
            <p class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= @found_truck.model %></p>
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">Propietario</label>
            <p class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= @found_truck.owner %></p>
          </div>
        </div>
        
        <div class="flex justify-end">
          <button phx-click="next_step" 
                  class="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors">
            Continuar con este camión
          </button>
        </div>
      </div>
      """
    else
      ~H"""
      <div class="text-center py-8">
        <svg class="h-12 w-12 text-slate-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3a4 4 0 118 0v4m-4 6v6m-4-6h8m-8 6h8"></path>
        </svg>
        <p class="text-slate-500 dark:text-slate-400">No se ha seleccionado ningún camión</p>
      </div>
      """
    end
  end

  defp render_ticket_details(assigns) do
    ~H"""
    <form class="max-w-4xl mx-auto space-y-6">
      <!-- Header -->
      <div class="text-center">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-slate-100">Ticket de Mantenimiento</h1>
        <p class="text-slate-600 dark:text-slate-400">Documenta y registra el mantenimiento del vehículo</p>
      </div>

      <!-- Basic Information -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Información Básica</h3>
        </div>
        <div class="p-6 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Camión</label>
              <div class="p-3 bg-slate-50 dark:bg-slate-700 rounded-lg border border-slate-200 dark:border-slate-600">
                <p class="text-sm font-medium text-slate-900 dark:text-slate-100">
                  <%= @found_truck.brand %> <%= @found_truck.model %>
                </p>
                <p class="text-sm text-slate-600 dark:text-slate-400">
                  Placa: <%= @found_truck.license_plate %>
                </p>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Entregado por *</label>
              <input
                type="text"
                name="maintenance[delivered_by]"
                value={@maintenance_form_data["delivered_by"]}
                phx-change="maintenance_field_changed"
                phx-value-field="delivered_by"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Nombre del conductor"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Cédula del Conductor</label>
              <input
                type="text"
                name="maintenance[driver_cedula]"
                value={@maintenance_form_data["driver_cedula"]}
                phx-change="maintenance_field_changed"
                phx-value-field="driver_cedula"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Número de cédula"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Fecha</label>
              <input
                type="date"
                name="maintenance[date]"
                value={@maintenance_form_data["date"]}
                phx-change="maintenance_field_changed"
                phx-value-field="date"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Maintenance Type -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tipo de Mantenimiento</h3>
        </div>
        <div class="p-6">
          <div class="space-y-3">
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="maintenance[maintenance_type]" value="preventive" id="preventive" 
                     checked={@maintenance_form_data["maintenance_type"] == "preventive"}
                     phx-change="maintenance_field_changed"
                     phx-value-field="maintenance_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="preventive" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Preventivo
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Mantenimiento programado para prevenir fallas</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="maintenance[maintenance_type]" value="corrective" id="corrective"
                     checked={@maintenance_form_data["maintenance_type"] == "corrective"}
                     phx-change="maintenance_field_changed"
                     phx-value-field="maintenance_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="corrective" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Correctivo
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Reparación de fallas existentes</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="maintenance[maintenance_type]" value="emergency" id="emergency"
                     checked={@maintenance_form_data["maintenance_type"] == "emergency"}
                     phx-change="maintenance_field_changed"
                     phx-value-field="maintenance_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="emergency" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Emergencia
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Reparación urgente por falla crítica</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="maintenance[maintenance_type]" value="inspection" id="inspection"
                     checked={@maintenance_form_data["maintenance_type"] == "inspection"}
                     phx-change="maintenance_field_changed"
                     phx-value-field="maintenance_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="inspection" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Inspección
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Revisión general del estado del vehículo</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Maintenance Details -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Detalles del Mantenimiento</h3>
        </div>
        <div class="p-6 space-y-6">
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Descripción del Problema *</label>
            <textarea
              name="maintenance[description]"
              value={@maintenance_form_data["description"]}
              phx-change="maintenance_field_changed"
              phx-value-field="description"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              placeholder="Describe detalladamente el problema o trabajo a realizar..."
              rows="4"
            ></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-3">Áreas a Mantener</label>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
              <%= for area <- ["Motor", "Transmisión", "Sistema Eléctrico", "Frenos", "Suspensión", "Dirección", "Llantas", "Carrocería", "Interior", "Sistema de Combustible"] do %>
                <div class="flex items-center space-x-2">
                  <input type="checkbox"
                         id={area}
                         name="maintenance[maintenance_areas][]"
                         value={area}
                         checked={area in (@maintenance_form_data["maintenance_areas"] || [])}
                         phx-change="maintenance_field_changed"
                         phx-value-field="maintenance_areas"
                         class="rounded border-slate-300 dark:border-slate-600" />
                  <label for={area} class="cursor-pointer text-sm text-slate-700 dark:text-slate-300"><%= area %></label>
                </div>
              <% end %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-3">Prioridad *</label>
            <div class="space-y-3">
              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="maintenance[priority]" value="low" id="low_priority"
                       checked={@maintenance_form_data["priority"] == "low"}
                       phx-change="maintenance_field_changed"
                       phx-value-field="priority"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="low_priority" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Baja
                    </label>
                    <div class="w-3 h-3 rounded-full bg-green-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">Mantenimiento rutinario, no urgente</p>
                </div>
              </div>
              
              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="maintenance[priority]" value="medium" id="medium_priority"
                       checked={@maintenance_form_data["priority"] == "medium"}
                       phx-change="maintenance_field_changed"
                       phx-value-field="priority"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="medium_priority" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Media
                    </label>
                    <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">Requiere atención en los próximos días</p>
                </div>
              </div>
              
              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="maintenance[priority]" value="high" id="high_priority"
                       checked={@maintenance_form_data["priority"] == "high"}
                       phx-change="maintenance_field_changed"
                       phx-value-field="priority"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="high_priority" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Alta
                    </label>
                    <div class="w-3 h-3 rounded-full bg-orange-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">Afecta el funcionamiento del vehículo</p>
                </div>
              </div>

              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="maintenance[priority]" value="critical" id="critical_priority"
                       checked={@maintenance_form_data["priority"] == "critical"}
                       phx-change="maintenance_field_changed"
                       phx-value-field="priority"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="critical_priority" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Crítica
                    </label>
                    <div class="w-3 h-3 rounded-full bg-red-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">El vehículo no puede operar de forma segura</p>
                </div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Kilometraje</label>
              <input
                type="number"
                name="maintenance[mileage]"
                value={@maintenance_form_data["mileage"]}
                phx-change="maintenance_field_changed"
                phx-value-field="mileage"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="0"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Nivel de Combustible</label>
              <select
                name="maintenance[fuel_level]"
                value={@maintenance_form_data["fuel_level"]}
                phx-change="maintenance_field_changed"
                phx-value-field="fuel_level"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100">
                <option value="">Seleccionar</option>
                <option value="empty">Vacío</option>
                <option value="quarter">1/4</option>
                <option value="half">1/2</option>
                <option value="three_quarters">3/4</option>
                <option value="full">Lleno</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Costo Estimado</label>
              <input
                type="number"
                name="maintenance[estimated_cost]"
                value={@maintenance_form_data["estimated_cost"]}
                phx-change="maintenance_field_changed"
                phx-value-field="estimated_cost"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="0.00"
                step="0.01"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Daños Visibles</label>
            <textarea
              name="maintenance[visible_damage]"
              value={@maintenance_form_data["visible_damage"]}
              phx-change="maintenance_field_changed"
              phx-value-field="visible_damage"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              placeholder="Describa cualquier daño visible..."
              rows="3"
            ></textarea>
          </div>
        </div>
      </div>

      <!-- Photos -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Documentación Fotográfica</h3>
          <p class="text-sm text-slate-600 dark:text-slate-400">Sube fotos que documenten el estado del vehículo</p>
        </div>
        <div class="p-6">
          <div class="space-y-4">
            <!-- Botón para abrir modal de subida -->
            <button 
              phx-click="show_upload_modal" 
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
              </svg>
              Subir Fotos y Documentos
            </button>

            <!-- Lista de archivos ya subidos -->
            <%= if length(@existing_files) > 0 do %>
              <div class="mt-4">
                <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-3">Archivos subidos:</h4>
                <div class="space-y-2">
                  <%= for file <- @existing_files do %>
                    <div class="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-700 rounded-lg border border-slate-200 dark:border-slate-600">
                      <div class="flex items-center space-x-2">
                        <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                        </svg>
                        <span class="text-sm text-slate-700 dark:text-slate-300"><%= file.original_name %></span>
                        <%= if file.description && file.description != "" do %>
                          <span class="text-xs text-slate-500 dark:text-slate-400">(<%= file.description %>)</span>
                        <% end %>
                      </div>
                      <button 
                        phx-click="remove_file" 
                        phx-value-file_path={file.path}
                        class="p-1 hover:bg-slate-200 dark:hover:bg-slate-600 rounded text-red-500"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Notes -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Notas Adicionales</h3>
        </div>
        <div class="p-6">
          <textarea
            name="maintenance[notes]"
            value={@maintenance_form_data["notes"]}
            phx-change="maintenance_field_changed"
            phx-value-field="notes"
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
            placeholder="Cualquier información adicional relevante..."
            rows="4"
          ></textarea>
        </div>
      </div>

      <!-- Summary -->
      <%= if @maintenance_form_data["priority"] || (@maintenance_form_data["maintenance_areas"] && length(@maintenance_form_data["maintenance_areas"]) > 0) do %>
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
          <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
            <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Resumen del Mantenimiento</h3>
          </div>
          <div class="p-6">
            <div class="space-y-3">
              <%= if @maintenance_form_data["priority"] do %>
                <div class="flex items-center gap-2">
                  <span class="text-sm text-slate-600 dark:text-slate-400">Prioridad:</span>
                  <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{get_priority_color(@maintenance_form_data["priority"])}"}>
                    <%= get_priority_label(@maintenance_form_data["priority"]) %>
                  </span>
                </div>
              <% end %>
              <%= if @maintenance_form_data["maintenance_areas"] && length(@maintenance_form_data["maintenance_areas"]) > 0 do %>
                <div>
                  <span class="text-sm text-slate-600 dark:text-slate-400">Áreas a mantener: </span>
                  <span class="text-sm font-medium text-slate-900 dark:text-slate-100"><%= Enum.join(@maintenance_form_data["maintenance_areas"], ", ") %></span>
                </div>
              <% end %>
              <%= if @maintenance_form_data["estimated_cost"] && @maintenance_form_data["estimated_cost"] != "" do %>
                <div>
                  <span class="text-sm text-slate-600 dark:text-slate-400">Costo estimado: </span>
                  <span class="text-sm font-medium text-slate-900 dark:text-slate-100">$<%= @maintenance_form_data["estimated_cost"] %></span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Actions -->
      <div class="flex justify-between">
        <button type="button" phx-click="prev_step" 
                class="px-4 py-2 text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
          Anterior
        </button>
        <div class="flex gap-2">
          <button type="button" phx-click="submit_maintenance" phx-value-action="draft"
                  class="px-4 py-2 text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
            <svg class="h-4 w-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"></path>
            </svg>
            Guardar Borrador
          </button>
          <button type="button" phx-click="submit_maintenance" phx-value-action="submit"
                  class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors">
            <svg class="h-4 w-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
            </svg>
            Crear Ticket
          </button>
        </div>
      </div>
    </form>
    """
  end

  defp render_confirmation(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="text-center">
        <div class="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
        </div>
        <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-100 mb-2">
          Confirmar Creación del Ticket
        </h3>
        <p class="text-slate-600 dark:text-slate-400">
          Revisa la información antes de crear el ticket de mantenimiento
        </p>
      </div>

      <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6">
        <h4 class="font-semibold text-blue-800 dark:text-blue-200 mb-4">Resumen del Ticket</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <span class="text-blue-700 dark:text-blue-300 font-medium">Camión:</span>
            <span class="text-blue-900 dark:text-blue-100 ml-2"><%= @found_truck.license_plate %></span>
          </div>
          <div>
            <span class="text-blue-700 dark:text-blue-300 font-medium">Título:</span>
            <span class="text-blue-900 dark:text-blue-100 ml-2"><%= @maintenance_form_data["title"] || "Mantenimiento - #{@found_truck.license_plate}" %></span>
          </div>
          <div>
            <span class="text-blue-700 dark:text-blue-300 font-medium">Prioridad:</span>
            <span class="text-blue-900 dark:text-blue-100 ml-2 capitalize"><%= @maintenance_form_data["priority"] || "medium" %></span>
          </div>
          <div>
            <span class="text-blue-700 dark:text-blue-300 font-medium">Fecha de Entrada:</span>
            <span class="text-blue-900 dark:text-blue-100 ml-2"><%= @maintenance_form_data["entry_date"] || "Hoy" %></span>
          </div>
          <div>
            <span class="text-blue-700 dark:text-blue-300 font-medium">Kilometraje:</span>
            <span class="text-blue-900 dark:text-blue-100 ml-2"><%= @maintenance_form_data["mileage"] || "No especificado" %></span>
          </div>
          <div>
            <span class="text-blue-700 dark:text-blue-300 font-medium">Nivel de Combustible:</span>
            <span class="text-blue-900 dark:text-blue-100 ml-2 capitalize"><%= @maintenance_form_data["fuel_level"] || "No especificado" %></span>
          </div>
        </div>
        
        <%= if @maintenance_form_data["description"] && @maintenance_form_data["description"] != "" do %>
          <div class="mt-4">
            <span class="text-blue-700 dark:text-blue-300 font-medium">Descripción:</span>
            <p class="text-blue-900 dark:text-blue-100 mt-1"><%= @maintenance_form_data["description"] %></p>
          </div>
        <% end %>
      </div>

      <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
        <div class="flex items-start">
          <svg class="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
          </svg>
          <p class="text-yellow-700 dark:text-yellow-300 text-sm">
            Una vez confirmado, el ticket será creado y asignado al equipo de mantenimiento.
          </p>
        </div>
      </div>

      <div class="flex justify-between">
        <button phx-click="prev_step" 
                class="px-6 py-2 bg-slate-600 text-white rounded-lg hover:bg-slate-700 transition-colors">
          Atrás
        </button>
        <button phx-click="submit_maintenance" 
                class="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors">
          <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          Crear Ticket
        </button>
      </div>
    </div>
    """
  end

  defp render_ticket_created(assigns) do
    if assigns.created_ticket do
      ~H"""
      <div class="max-w-4xl mx-auto">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-8 mb-6">
          <div class="text-center mb-8">
            <div class="w-16 h-16 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
            </div>
            <h2 class="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-2">
              ¡Ticket Creado Exitosamente!
            </h2>
            <p class="text-slate-600 dark:text-slate-400">
              El ticket de mantenimiento ha sido creado y está listo para ser procesado.
            </p>
          </div>

          <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 mb-6">
            <h3 class="text-lg font-semibold text-green-800 dark:text-green-200 mb-4">
              Detalles del Ticket Creado
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <span class="text-green-700 dark:text-green-300 font-medium">ID del Ticket:</span>
                <span class="text-green-900 dark:text-green-100 ml-2 font-mono"><%= @created_ticket.id %></span>
              </div>
              <div>
                <span class="text-green-700 dark:text-green-300 font-medium">Título:</span>
                <span class="text-green-900 dark:text-green-100 ml-2"><%= @created_ticket.title %></span>
              </div>
              <div>
                <span class="text-green-700 dark:text-green-300 font-medium">Estado:</span>
                <span class="text-green-900 dark:text-green-100 ml-2 capitalize"><%= @created_ticket.status %></span>
              </div>
              <div>
                <span class="text-green-700 dark:text-green-300 font-medium">Prioridad:</span>
                <span class="text-green-900 dark:text-green-100 ml-2 capitalize"><%= @created_ticket.priority %></span>
              </div>
              <div>
                <span class="text-green-700 dark:text-green-300 font-medium">Camión:</span>
                <span class="text-green-900 dark:text-green-100 ml-2"><%= @found_truck.license_plate %></span>
              </div>
              <div>
                <span class="text-green-700 dark:text-green-300 font-medium">Fecha de Creación:</span>
                <span class="text-green-900 dark:text-green-100 ml-2"><%= Calendar.strftime(@created_ticket.inserted_at, "%d/%m/%Y %H:%M") %></span>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 mb-6">
            <h3 class="text-lg font-semibold text-blue-800 dark:text-blue-200 mb-4">
              Próximos Pasos
            </h3>
            <ul class="space-y-2 text-blue-700 dark:text-blue-300">
              <li class="flex items-start">
                <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                El ticket ha sido asignado al equipo de mantenimiento
              </li>
              <li class="flex items-start">
                <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Recibirás notificaciones sobre el progreso del mantenimiento
              </li>
              <li class="flex items-start">
                <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                Puedes revisar el estado del ticket en cualquier momento
              </li>
            </ul>
          </div>

          <div class="flex justify-center gap-4">
            <a href={"/maintenance/#{@created_ticket.id}"} 
               class="px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium">
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
              </svg>
              Ver Ticket Completo
            </a>
            <button phx-click="back_to_start" 
                    class="px-6 py-3 bg-slate-600 text-white rounded-lg hover:bg-slate-700 transition-colors font-medium">
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
              </svg>
              Crear Otro Ticket
            </button>
          </div>
        </div>
      </div>
      """
    else
      ~H"""
      <div class="text-center py-8">
        <p class="text-slate-500 dark:text-slate-400">No hay ticket creado para mostrar.</p>
      </div>
      """
    end
  end

  # Helper functions
  defp get_progress_percentage(current_step, total_steps) do
    (current_step / total_steps) * 100
  end

  defp get_step_container_classes(step, total_steps) do
    base_classes = "flex-1 text-center"
    if step == total_steps do
      base_classes
    else
      base_classes <> " relative"
    end
  end

  defp get_step_classes(current_step, step) do
    cond do
      current_step > step -> "bg-green-600 text-white"
      current_step == step -> "bg-red-600 text-white"
      true -> "bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-400"
    end
  end

  defp get_step_title(step) do
    case step do
      1 -> "Tipo de Entrada"
      2 -> "Seleccionar Camión"
      3 -> "Información del Camión"
      4 -> "Detalles del Mantenimiento"
      5 -> "Confirmación"
      6 -> "Ticket Creado"
      _ -> "Paso #{step}"
    end
  end

  defp get_step_description(step) do
    case step do
      1 -> "Elige el tipo de entrada"
      2 -> "Busca o registra un camión"
      3 -> "Revisa la información"
      4 -> "Completa los detalles"
      5 -> "Confirma la creación"
      6 -> "Ticket creado exitosamente"
      _ -> "Descripción del paso #{step}"
    end
  end

  defp get_existing_brands do
    from(t in Truck, 
         where: not is_nil(t.brand) and t.brand != "",
         distinct: t.brand,
         order_by: t.brand)
    |> Repo.all()
    |> Enum.map(& &1.brand)
  end

  defp get_existing_models do
    from(t in Truck, 
         where: not is_nil(t.model) and t.model != "",
         distinct: t.model,
         order_by: t.model)
    |> Repo.all()
    |> Enum.map(& &1.model)
  end

  defp get_existing_owners do
    from(t in Truck, 
         where: not is_nil(t.owner) and t.owner != "",
         distinct: t.owner,
         order_by: t.owner)
    |> Repo.all()
    |> Enum.map(& &1.owner)
  end

  defp create_maintenance_ticket(socket) do
    maintenance_data = socket.assigns.maintenance_form_data
    found_truck = socket.assigns.found_truck
    current_user = socket.assigns.current_user
    
    # Procesar fotos subidas
    photo_paths = case consume_uploaded_entries(socket, :maintenance_photos, fn %{path: path}, _entry ->
      # Mover archivo a ubicación permanente
      filename = Path.basename(path)
      new_path = Path.join(["priv", "static", "uploads", "maintenance", "#{found_truck.id}", filename])
      File.mkdir_p!(Path.dirname(new_path))
      File.cp!(path, new_path)
      "/uploads/maintenance/#{found_truck.id}/#{filename}"
    end) do
      {:ok, paths} -> paths
      _ -> []
    end
    
    # Preparar parámetros para crear el ticket
    maintenance_params = %{
      title: maintenance_data["title"] || "Mantenimiento - #{found_truck.license_plate}",
      description: maintenance_data["description"] || "",
      priority: maintenance_data["priority"] || "medium",
      entry_date: parse_date(maintenance_data["entry_date"]),
      mileage: parse_integer(maintenance_data["mileage"]),
      fuel_level: maintenance_data["fuel_level"],
      visible_damage: maintenance_data["visible_damage"],
      color: maintenance_data["color"],
      status: "pending",
      business_id: current_user.business_id,
      truck_id: found_truck.id,
      damage_photos: photo_paths
    }
    
    case MaintenanceTicket.create_maintenance_ticket(maintenance_params, current_user.id) do
      {:ok, ticket} ->
        # Crear log de actividad
        ActivityLog.create_log(%{
          action: "created",
          description: "creó maintenance ticket '#{ticket.title}'",
          user_id: current_user.id,
          business_id: current_user.business_id,
          entity_id: ticket.id,
          entity_type: "maintenance_ticket"
        })
        {:ok, ticket}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp parse_date(date_string) when is_binary(date_string) and date_string != "" do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end
  defp parse_date(_), do: nil

  defp parse_integer(value) when is_binary(value) and value != "" do
    case Integer.parse(value) do
      {int, _} -> int
      _ -> nil
    end
  end
  defp parse_integer(_), do: nil

  # Helper functions for priority colors and labels
  defp get_priority_color(priority) do
    case priority do
      "low" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "medium" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "high" -> "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
      "critical" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      _ -> "bg-slate-100 text-slate-800 dark:bg-slate-900 dark:text-slate-200"
    end
  end

  defp get_priority_label(priority) do
    case priority do
      "low" -> "Baja"
      "medium" -> "Media"
      "high" -> "Alta"
      "critical" -> "Crítica"
      _ -> "No especificada"
    end
  end

  # Helper function for upload errors
  defp error_to_string_helper(:too_large), do: "El archivo es demasiado grande"
  defp error_to_string_helper(:too_many_files), do: "Demasiados archivos"
  defp error_to_string_helper(:not_accepted), do: "Tipo de archivo no aceptado"
  defp error_to_string_helper(_), do: "Error al subir el archivo"
end
