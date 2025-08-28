defmodule EvaaCrmWebGaepell.CheckinWizardLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Repo, Truck, MaintenanceTicket, User, ActivityLog, Fleet}
  alias EvaaCrmWebGaepell.Components.UniversalFileUpload
  alias EvaaCrmWebGaepell.Utils.FileUploadUtils
  import Ecto.Query
  import Phoenix.LiveView.Helpers
  import Path

  @required_photos ["front", "back", "left", "right", "damage"]

  @impl true
  def mount(_params, session, socket) do
    IO.inspect("CheckinWizardLive mount called", label: "[DEBUG]")
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil
    
    # Obtener marcas, modelos y propietarios existentes para autocompletado
    existing_brands = get_existing_brands()
    existing_models = get_existing_models()
    existing_owners = get_existing_owners()
    
         socket =
       socket
       |> assign(current_step: 1, total_steps: 5, current_user: current_user)
       |> assign(scenario: nil, entry_type: nil)
       |> assign(found_truck: nil, new_truck: nil)
       |> assign(ticket_form: %{})
       |> assign(evaluation_form_data: %{})
       |> assign(maintenance_form_data: %{})
       |> assign(production_form_data: %{
         "delivered_by" => "",
         "driver_cedula" => "",
         "date" => "",
         "box_type" => "seca",
         "estimated_delivery" => "",
         "notes" => "",
         "rear_tire_width" => "",
         "useful_length" => "",
         "chassis_width" => ""
       })
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
       |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif .pdf .doc .docx .txt .xlsx .xls), max_entries: 10, max_file_size: 10_000_000, auto_upload: false)
    
    IO.inspect("Upload config:", label: "[DEBUG]")
    IO.inspect(socket.assigns.uploads.evaluation_photos, label: "[DEBUG] upload config")
    
    if is_nil(current_user) do
      {:ok, socket |> put_flash(:error, "Debes iniciar sesión para crear tickets.") |> push_navigate(to: "/login")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("select_scenario", %{"scenario" => scenario}, socket) do
    IO.inspect("select_scenario called with scenario: #{scenario}", label: "[DEBUG]")
    IO.inspect("Current step: #{socket.assigns.current_step}", label: "[DEBUG]")
    {new_step, entry_type} =
      case scenario do
        "evaluation_quotation" -> {2, :quotation}
        "maintenance_checkin" -> {2, :maintenance}
        "production_order" -> {2, :production}
        _ -> {1, nil}
      end

    # Cargar camiones existentes para el paso 2
    socket = if new_step == 2 do
      import Ecto.Query
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
    
    IO.inspect("Moving from step #{current_step} to #{current_step + 1}", label: "[DEBUG]")
    
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
     |> assign(ticket_form: %{}, evaluation_form_data: %{}, maintenance_form_data: %{})
     |> assign(show_existing_trucks_modal: false, show_new_truck_form: false)}
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
    IO.inspect("Opening existing trucks modal", label: "[DEBUG]")
    {:noreply, assign(socket, show_existing_trucks_modal: true)}
  end

  @impl true
  def handle_event("hide_existing_trucks_modal", _params, socket) do
    IO.inspect("Hiding existing trucks modal", label: "[DEBUG]")
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
    IO.inspect("Selecting truck #{truck_id}, moving to step 4", label: "[DEBUG]")
    truck = Repo.get(Truck, truck_id)
    
    if truck do
      socket = socket
        |> assign(found_truck: truck, show_existing_trucks_modal: false)
        |> assign(current_step: 4)
        |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
        |> allow_upload(:maintenance_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
      
      IO.inspect("Upload after truck selection:", label: "[DEBUG]")
      IO.inspect(socket.assigns.uploads.evaluation_photos, label: "[DEBUG] upload after truck selection")
      IO.inspect("Modal state after truck selection: #{socket.assigns.show_existing_trucks_modal}", label: "[DEBUG]")
      
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
      "business_id" => socket.assigns.current_user.business_id
    })
    
    case Truck.create_truck(params, socket.assigns.current_user.id) do
      {:ok, truck} ->
        {:noreply, 
         socket
         |> assign(found_truck: truck, new_truck: nil, show_new_truck_form: false)
         |> assign(current_step: 4)
         |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
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
  def handle_event("save_ticket_details", %{"ticket" => ticket_params}, socket) do
    found_truck = socket.assigns.found_truck
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    ticket_params = Map.merge(ticket_params, %{
      "truck_id" => found_truck.id,
      "business_id" => socket.assigns.current_user.business_id,
      "entry_date" => now,
      "status" => "check_in"
    })
    
    case MaintenanceTicket.create_ticket(ticket_params, socket.assigns.current_user.id) do
      {:ok, ticket} ->
        {:noreply, 
         socket
         |> assign(current_step: 5)
         |> assign(created_ticket: ticket)
         |> put_flash(:info, "Ticket creado exitosamente")}
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(ticket_form: changeset)
         |> put_flash(:error, "Error al crear el ticket")}
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
  def handle_event("production_field_changed", %{"_target" => ["production", field], "production" => production_data}, socket) do
    current_data = socket.assigns.production_form_data || %{}
    value = Map.get(production_data, field)
    updated_data = Map.put(current_data, field, value)
    {:noreply, assign(socket, :production_form_data, updated_data)}
  end

  @impl true
  def handle_event("production_field_changed", %{"field" => field, "value" => value}, socket) do
    current_data = socket.assigns.production_form_data || %{}
    updated_data = Map.put(current_data, field, value)
    {:noreply, assign(socket, :production_form_data, updated_data)}
  end

  @impl true
  def handle_event("production_field_changed", %{"field" => field}, socket) do
    # Handle radio buttons and checkboxes without value
    current_data = socket.assigns.production_form_data || %{}
    updated_data = Map.put(current_data, field, true)
    {:noreply, assign(socket, :production_form_data, updated_data)}
  end

  @impl true
  def handle_event("submit_maintenance", %{"action" => action}, socket) do
    case action do
      "draft" ->
        # Guardar como borrador
        {:noreply, 
         socket
         |> put_flash(:info, "Borrador guardado exitosamente")
         |> push_navigate(to: "/maintenance")}
      "submit" ->
        # Crear el ticket de mantenimiento
        case create_maintenance_ticket(socket) do
          {:ok, ticket} ->
            {:noreply, 
             socket
             |> assign(created_ticket: ticket, current_step: 5)
             |> put_flash(:info, "Ticket de mantenimiento creado exitosamente")}
          {:error, changeset} ->
            {:noreply, 
             socket
             |> assign(maintenance_form_data: changeset)
             |> put_flash(:error, "Error al crear el ticket de mantenimiento")}
        end
    end
  end

  @impl true
  def handle_event("submit_maintenance", _params, socket) do
    # Si no se especifica acción, crear el ticket directamente
    case create_maintenance_ticket(socket) do
      {:ok, ticket} ->
        {:noreply, 
         socket
         |> assign(created_ticket: ticket, current_step: 5)
         |> put_flash(:info, "Ticket de mantenimiento creado exitosamente")}
      {:noreply, 
         socket
         |> assign(created_ticket: ticket, current_step: 5)
         |> put_flash(:info, "Ticket de mantenimiento creado exitosamente")}
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(maintenance_form_data: changeset)
         |> put_flash(:error, "Error al crear el ticket de mantenimiento")}
    end
  end

  @impl true
  def handle_event("submit_production_order", _params, socket) do
    case create_production_order(socket) do
      {:ok, order} ->
        {:noreply, 
         socket
         |> assign(created_ticket: order, current_step: 5)
         |> put_flash(:info, "Orden de producción creada exitosamente")}
      {:error, changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al crear la orden de producción: #{format_changeset_errors(changeset)}")}
    end
  end

  @impl true
  def handle_event("go_to_production_orders", _params, socket) do
    {:noreply, push_navigate(socket, to: "/tickets?tab=production")}
  end

  @impl true
  def handle_event("go_to_tickets", _params, socket) do
    {:noreply, push_navigate(socket, to: "/tickets")}
  end

  @impl true
  def handle_event("complete_wizard", _params, socket) do
    # Determinar la ruta de redirección basada en el tipo de entrada
    redirect_to = case socket.assigns.entry_type do
      :quotation -> "/evaluations"
      :maintenance -> "/maintenance"
      :production -> "/production-orders"
      _ -> "/maintenance"
    end
    
    {:noreply, 
     socket
     |> put_flash(:success, "Proceso completado exitosamente")
     |> push_navigate(to: redirect_to)}
  end

  # Helper functions
  defp get_existing_brands do
    Truck
    |> select([t], t.brand)
    |> where([t], not is_nil(t.brand) and t.brand != "")
    |> distinct([t], t.brand)
    |> order_by([t], t.brand)
    |> Repo.all()
  end

  defp get_existing_models do
    Truck
    |> select([t], t.model)
    |> where([t], not is_nil(t.model) and t.model != "")
    |> distinct([t], t.model)
    |> order_by([t], t.model)
    |> Repo.all()
  end

  defp get_existing_owners do
    Truck
    |> select([t], t.owner)
    |> where([t], not is_nil(t.owner) and t.owner != "")
    |> distinct([t], t.owner)
    |> order_by([t], t.owner)
    |> Repo.all()
  end

  defp get_step_title(step) do
    case step do
      1 -> "Seleccionar Tipo de Check-in"
      2 -> "Buscar o Registrar Camión"
      3 -> "Información del Camión"
      4 -> "Detalles del Ticket"
      5 -> "Confirmación"
      _ -> "Paso #{step}"
    end
  end

  defp get_step_description(step) do
    case step do
      1 -> "Elige el tipo de proceso que deseas realizar"
      2 -> "Busca un camión existente o registra uno nuevo"
      3 -> "Revisa y confirma la información del camión"
      4 -> "Completa los detalles del ticket de mantenimiento"
      5 -> "Revisa toda la información antes de finalizar"
      _ -> "Descripción del paso #{step}"
    end
  end

  defp get_progress_percentage(current_step, total_steps) do
    (current_step / total_steps) * 100
  end

  defp get_step_classes(current_step, step, entry_type) do
    if current_step >= step do
      case entry_type do
        :maintenance -> "bg-red-600 text-white shadow-lg"
        :quotation -> "bg-purple-600 text-white shadow-lg"
        :production -> "bg-green-600 text-white shadow-lg"
        _ -> "bg-blue-600 text-white shadow-lg"
      end
    else
      "bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-400"
    end
  end

  defp get_step_container_classes(step, total_steps) do
    if step < total_steps do
      "flex-1 text-center border-r border-slate-200 dark:border-slate-700"
    else
      "flex-1 text-center"
    end
  end

  defp get_progress_bar_color(entry_type) do
    case entry_type do
      :maintenance -> "bg-red-600"
      :quotation -> "bg-purple-600"
      :production -> "bg-green-600"
      _ -> "bg-blue-600"
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :progress_percentage, get_progress_percentage(assigns.current_step, assigns.total_steps))
    
    # Debug modal state in every render
    IO.inspect("Modal state in render: #{assigns.show_existing_trucks_modal}", label: "[DEBUG]")
    
    # Debug upload in render
    if assigns.current_step == 4 do
      IO.inspect("Render step 4 - upload config:", label: "[DEBUG]")
      IO.inspect(assigns.uploads.evaluation_photos, label: "[DEBUG] upload in render")
    end
    
    ~H"""
    <div class="max-w-4xl mx-auto py-4 sm:py-8 px-4">
      <!-- Header -->
      <div class="text-center mb-6 sm:mb-8">
        <h1 class="text-2xl sm:text-3xl font-bold text-slate-900 dark:text-slate-100 mb-2">
          Check-in de Entrada
        </h1>
        <p class="text-sm sm:text-base text-slate-600 dark:text-slate-400">
          Complete la información paso a paso para crear un nuevo ticket
        </p>
      </div>

      <!-- Progress Bar -->
      <div class="space-y-2 mb-6 sm:mb-8">
        <div class="flex justify-between text-xs sm:text-sm text-slate-600 dark:text-slate-400">
          <span>Paso <%= @current_step %> de <%= @total_steps %></span>
          <span><%= round(@progress_percentage) %>% completado</span>
        </div>
        <div class="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
          <div class={get_progress_bar_color(@entry_type) <> " h-2 rounded-full transition-all duration-500 ease-out"} 
               style={"width: #{@progress_percentage}%"}>
          </div>
        </div>
      </div>

      <!-- Steps Navigation -->
      <div class="hidden sm:flex justify-between mb-6 sm:mb-8">
        <%= for step <- 1..@total_steps do %>
          <div class={get_step_container_classes(step, @total_steps)}>
            <div class={"inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium mb-2 transition-all duration-200 " <> get_step_classes(@current_step, step, @entry_type)}>
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
      
      <!-- Mobile Steps Indicator -->
      <div class="sm:hidden flex justify-center mb-6">
        <div class="flex items-center space-x-2">
          <%= for step <- 1..@total_steps do %>
            <div class={"w-2 h-2 rounded-full transition-all duration-200 " <> 
              if(@current_step >= step, do: "bg-blue-600", else: "bg-slate-300 dark:bg-slate-600")}>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Step Content -->
      <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-slate-200 dark:border-slate-700">
        <div class="p-4 sm:p-6 border-b border-slate-200 dark:border-slate-700">
          <h2 class="text-lg sm:text-xl font-semibold text-slate-900 dark:text-slate-100">
            <%= get_step_title(@current_step) %>
          </h2>
          <p class="text-sm sm:text-base text-slate-600 dark:text-slate-400 mt-1">
            <%= get_step_description(@current_step) %>
          </p>
        </div>
        
        <div class="p-4 sm:p-6">
          <%= render_step_content(assigns) %>
        </div>
      </div>

      <!-- Navigation Buttons -->
      <div class="flex flex-col sm:flex-row justify-between gap-4 sm:gap-0 mt-6 sm:mt-8">
        <div class="flex flex-col sm:flex-row gap-3">
          <button phx-click="back_to_start" 
                  class="px-4 py-3 sm:py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
            Cancelar
          </button>
          <%= if @current_step > 1 do %>
            <button phx-click="prev_step" 
                    class="px-4 py-3 sm:py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors flex items-center justify-center gap-2">
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
                    class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2">
              Siguiente
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
            </button>
          <% else %>
            <button phx-click="complete_wizard" 
                    class="px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-lg hover:bg-green-700 transition-colors flex items-center gap-2">
              Completar
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
            </button>
          <% end %>
        </div>
      </div>
    </div>
    
    <%= render_modals(assigns) %>
    <%= render_upload_modal(assigns) %>
    """
  end

  defp render_step_content(assigns) do
    case assigns.current_step do
      1 -> render_scenario_selection(assigns)
      2 -> render_truck_search(assigns)
      3 -> render_truck_info(assigns)
      4 -> render_ticket_details(assigns)
      5 -> render_confirmation(assigns)
      _ -> "Paso no implementado"
    end
  end

  defp render_scenario_selection(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-6">
      <button phx-click="select_scenario" phx-value-scenario="evaluation_quotation" 
              class="w-full py-8 rounded-lg bg-purple-600 text-white text-xl font-semibold shadow hover:bg-purple-700 transition flex items-center justify-center gap-3">
        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
        </svg>
        <span>Evaluación & Cotización</span>
      </button>
      
      <button phx-click="select_scenario" phx-value-scenario="maintenance_checkin" 
              class="w-full py-8 rounded-lg bg-red-500 text-white text-xl font-semibold shadow hover:bg-red-600 transition flex items-center justify-center gap-3">
        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
        </svg>
        <span>🛠️ Check-in de Mantenimiento</span>
      </button>
      
      <button phx-click="select_scenario" phx-value-scenario="production_order" 
              class="w-full py-8 rounded-lg bg-green-500 text-white text-xl font-semibold shadow hover:bg-green-600 transition flex items-center justify-center gap-3">
        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
        </svg>
        <span>📦 Orden de Producción</span>
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
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">Año</label>
            <p class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= @found_truck.year %></p>
          </div>
        </div>
      </div>
      """
    else
      ~H"""
      <div class="space-y-6">
        <div class="text-center">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">
            Registrar Nuevo Camión
          </h3>
          <p class="text-slate-600 dark:text-slate-400">
            Completa la información del nuevo camión
          </p>
        </div>
        
        <form phx-submit="save_new_truck" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Placa *</label>
              <input type="text" name="truck[license_plate]" required
                     class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                     placeholder="ABC-123">
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Marca *</label>
              <input type="text" name="truck[brand]" required
                     class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                     placeholder="Volvo">
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Modelo *</label>
              <input type="text" name="truck[model]" required
                     class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                     placeholder="FH 460">
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Año</label>
              <input type="number" name="truck[year]"
                     class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                     placeholder="2020">
            </div>
          </div>
          
          <button type="submit" 
                  class="w-full py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors">
            Registrar Camión
          </button>
        </form>
      </div>
      """
    end
  end

  defp render_ticket_details(assigns) do
    case assigns.entry_type do
      :quotation -> render_evaluation_form(assigns)
      :production -> render_production_order_form(assigns)
      _ -> render_maintenance_form(assigns)
    end
  end

  defp render_production_order_form(assigns) do
    ~H"""
    <form class="max-w-4xl mx-auto space-y-6">
      <!-- Header -->
      <div class="text-center">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-slate-100">Orden de Producción</h1>
        <p class="text-slate-600 dark:text-slate-400">Configura la producción de cajas para el camión</p>
      </div>

      <!-- Basic Information -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Información del Camión</h3>
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
                name="production[delivered_by]"
                value={@production_form_data["delivered_by"] || ""}
                phx-change="production_field_changed"
                phx-value-field="delivered_by"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Nombre del conductor"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Cédula del Conductor</label>
              <input
                type="text"
                name="production[driver_cedula]"
                value={@production_form_data["driver_cedula"] || ""}
                phx-change="production_field_changed"
                phx-value-field="driver_cedula"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Número de cédula"
              />
            </div>

            <div>
              <label class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Fecha</label>
              <input
                type="date"
                name="production[date]"
                value={@production_form_data["date"] || ""}
                phx-change="production_field_changed"
                phx-value-field="date"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Box Type Selection -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tipo de Caja</h3>
        </div>
        <div class="p-6">
          <div class="space-y-3">
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="production[box_type]" value="refrigerada" id="box_refrigerada" 
                     checked={@production_form_data["box_type"] == "refrigerada"}
                     phx-change="production_field_changed"
                     phx-value-field="box_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="box_refrigerada" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  🧊 Caja Refrigerada
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Caja con sistema de refrigeración para productos perecederos</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="production[box_type]" value="seca" id="box_seca" 
                     checked={@production_form_data["box_type"] == "seca"}
                     phx-change="production_field_changed"
                     phx-value-field="box_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="box_seca" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  📦 Caja Seca
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Caja estándar para productos no perecederos</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Technical Measurements -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Medidas Técnicas del Camión</h3>
        </div>
        <div class="p-6 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Ancho Gomas Traseras (cm)</label>
              <input
                type="number"
                name="production[rear_tire_width]"
                value={@production_form_data["rear_tire_width"] || @found_truck.rear_tire_width}
                phx-change="production_field_changed"
                phx-value-field="rear_tire_width"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Ancho en cm"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Largo Útil (cm)</label>
              <input
                type="number"
                name="production[useful_length]"
                value={@production_form_data["useful_length"] || @found_truck.useful_length}
                phx-change="production_field_changed"
                phx-value-field="useful_length"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Largo en cm"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Ancho Chassis (cm)</label>
              <input
                type="number"
                name="production[chassis_width]"
                value={@production_form_data["chassis_width"] || @found_truck.chassis_width}
                phx-change="production_field_changed"
                phx-value-field="chassis_width"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Ancho en cm"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Production Details -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Detalles de Producción</h3>
        </div>
        <div class="p-6 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Fecha Estimada de Entrega</label>
              <input
                type="date"
                name="production[estimated_delivery]"
                value={@production_form_data["estimated_delivery"] || ""}
                phx-change="production_field_changed"
                phx-value-field="estimated_delivery"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Notas Adicionales</label>
              <textarea
                name="production[notes]"
                value={@production_form_data["notes"] || ""}
                phx-change="production_field_changed"
                phx-value-field="notes"
                rows="3"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder="Especificaciones especiales, requisitos adicionales..."
              ></textarea>
            </div>
          </div>
        </div>
      </div>

      <!-- Submit Button -->
      <div class="flex justify-end">
        <button type="button" phx-click="submit_production_order" 
                class="px-6 py-3 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition-colors">
          Crear Orden de Producción
        </button>
      </div>
    </form>
    """
  end

  defp render_evaluation_form(assigns) do
    ~H"""
    <form class="max-w-4xl mx-auto space-y-6">
      <!-- Header -->
      <div class="text-center">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-slate-100">Evaluación de Daños</h1>
        <p class="text-slate-600 dark:text-slate-400">Documenta y evalúa los daños del vehículo</p>
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
                 name="evaluation[delivered_by]"
                 value={@evaluation_form_data["delivered_by"]}
                 phx-change="evaluation_field_changed"
                 phx-value-field="delivered_by"
                 class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                 placeholder="Nombre del conductor"
               />
             </div>

             <div>
               <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Cédula del Conductor</label>
               <input
                 type="text"
                 name="evaluation[driver_cedula]"
                 value={@evaluation_form_data["driver_cedula"]}
                 phx-change="evaluation_field_changed"
                 phx-value-field="driver_cedula"
                 class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                 placeholder="Número de cédula"
               />
             </div>

             <div>
               <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Fecha</label>
               <input
                 type="date"
                 name="evaluation[date]"
                 value={@evaluation_form_data["date"]}
                 phx-change="evaluation_field_changed"
                 phx-value-field="date"
                 class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
               />
             </div>
          </div>
        </div>
      </div>

      <!-- Evaluation Type -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tipo de Evaluación</h3>
        </div>
        <div class="p-6">
          <div class="space-y-3">
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="evaluation[evaluation_type]" value="garantia" id="garantia" 
                     checked={@evaluation_form_data["evaluation_type"] == "garantia"}
                     phx-change="evaluation_field_changed"
                     phx-value-field="evaluation_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="garantia" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Garantía
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Problemas cubiertos por garantía del fabricante</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="evaluation[evaluation_type]" value="colision" id="colision"
                     checked={@evaluation_form_data["evaluation_type"] == "colision"}
                     phx-change="evaluation_field_changed"
                     phx-value-field="evaluation_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="colision" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Colisión
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Daños por accidente o choque</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="evaluation[evaluation_type]" value="desgaste" id="desgaste"
                     checked={@evaluation_form_data["evaluation_type"] == "desgaste"}
                     phx-change="evaluation_field_changed"
                     phx-value-field="evaluation_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="desgaste" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Desgaste
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Desgaste normal por uso</p>
              </div>
            </div>
            
            <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
              <input type="radio" name="evaluation[evaluation_type]" value="otro" id="otro"
                     checked={@evaluation_form_data["evaluation_type"] == "otro"}
                     phx-change="evaluation_field_changed"
                     phx-value-field="evaluation_type"
                     class="mt-1" />
              <div class="flex-1">
                <label for="otro" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                  Otro
                </label>
                <p class="text-sm text-slate-600 dark:text-slate-400">Otros tipos de daños o problemas</p>
              </div>
            </div>
          </div>
          
          <!-- Campo de detalles específicos que aparece cuando se selecciona un tipo -->
          <%= if @evaluation_form_data["evaluation_type"] in ["garantia", "otro"] do %>
            <div class="mt-4 p-4 bg-slate-50 dark:bg-slate-700 rounded-lg border border-slate-200 dark:border-slate-600">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                <%= case @evaluation_form_data["evaluation_type"] do %>
                  <% "garantia" -> %>Detalles de Garantía *
                  <% "otro" -> %>Detalles Específicos *
                  <% _ -> %>Detalles Adicionales
                <% end %>
              </label>
              <textarea
                name="evaluation[evaluation_details]"
                phx-change="evaluation_field_changed"
                phx-value-field="evaluation_details"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
                placeholder={case @evaluation_form_data["evaluation_type"] do
                  "garantia" -> "Describe detalladamente los detalles de la garantía a trabajar..."
                  "otro" -> "Describe detalladamente el tipo de evaluación específica..."
                  _ -> "Describe los detalles adicionales..."
                end}
                rows="3"
                required
              ><%= @evaluation_form_data["evaluation_details"] || "" %></textarea>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Damage Details -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Detalles del Daño</h3>
        </div>
        <div class="p-6 space-y-6">
          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Descripción del Daño *</label>
            <textarea
              name="evaluation[description]"
              phx-change="evaluation_field_changed"
              phx-value-field="description"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              placeholder="Describe detalladamente los daños observados..."
              rows="4"
            ><%= @evaluation_form_data["description"] || "" %></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-3">Áreas Afectadas</label>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
              <%= for area <- ["Frontal", "Lateral Izquierdo", "Lateral Derecho", "Trasero", "Techo", "Cabina", "Caja/Remolque", "Llantas", "Motor", "Interior"] do %>
                <div class="flex items-center space-x-2">
                  <input type="checkbox"
                         id={area}
                         name="evaluation[damage_areas][]"
                         value={area}
                         checked={area in (@evaluation_form_data["damage_areas"] || [])}
                         phx-change="evaluation_field_changed"
                         phx-value-field="damage_areas"
                         class="rounded border-slate-300 dark:border-slate-600" />
                  <label for={area} class="cursor-pointer text-sm text-slate-700 dark:text-slate-300"><%= area %></label>
                </div>
              <% end %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-3">Nivel de Severidad *</label>
            <div class="space-y-3">
              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="evaluation[severity_level]" value="low" id="minor"
                       checked={@evaluation_form_data["severity_level"] == "low"}
                       phx-change="evaluation_field_changed"
                       phx-value-field="severity_level"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="minor" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Menor
                    </label>
                    <div class="w-3 h-3 rounded-full bg-green-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">Daño cosmético, no afecta funcionamiento</p>
                </div>
              </div>
              
              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="evaluation[severity_level]" value="medium" id="moderate"
                       checked={@evaluation_form_data["severity_level"] == "medium"}
                       phx-change="evaluation_field_changed"
                       phx-value-field="severity_level"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="moderate" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Moderado
                    </label>
                    <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">Requiere reparación, afecta parcialmente</p>
                </div>
              </div>
              
              <div class="flex items-start space-x-3 p-3 border border-slate-200 dark:border-slate-600 rounded-lg">
                <input type="radio" name="evaluation[severity_level]" value="high" id="severe"
                       checked={@evaluation_form_data["severity_level"] == "high"}
                       phx-change="evaluation_field_changed"
                       phx-value-field="severity_level"
                       class="mt-1" />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <label for="severe" class="font-medium text-slate-900 dark:text-slate-100 cursor-pointer">
                      Severo
                    </label>
                    <div class="w-3 h-3 rounded-full bg-red-500"></div>
                  </div>
                  <p class="text-sm text-slate-600 dark:text-slate-400">Daño crítico, requiere atención inmediata</p>
                </div>
              </div>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Costo Estimado de Reparación</label>
            <input
              type="number"
              name="evaluation[estimated_cost]"
              value={@evaluation_form_data["estimated_cost"]}
              phx-change="evaluation_field_changed"
              phx-value-field="estimated_cost"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
              placeholder="0.00"
              step="0.01"
            />
          </div>
        </div>
      </div>

      <!-- Photos -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Documentación Fotográfica</h3>
          <p class="text-sm text-slate-600 dark:text-slate-400">Sube fotos que documenten los daños</p>
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


            
            <!-- Lista de archivos existentes -->
            <div class="mt-6">
              <h4 class="text-lg font-medium mb-4">Archivos Adjuntos</h4>
              <div class="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg p-4 text-center">
                <svg class="h-12 w-12 mx-auto mb-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
                <p class="text-slate-600 dark:text-slate-400 mb-2">Fotos y documentos se gestionarán en la vista detallada</p>
                <p class="text-sm text-slate-500 dark:text-slate-500">Después de crear la evaluación, podrás subir fotos y PDFs desde la página de detalles del ticket</p>
              </div>
            </div>
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
            name="evaluation[notes]"
            value={@evaluation_form_data["notes"]}
            phx-change="evaluation_field_changed"
            phx-value-field="notes"
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-slate-100"
            placeholder="Cualquier información adicional relevante..."
            rows="4"
          ></textarea>
        </div>
      </div>

      <!-- Summary -->
      <%= if @evaluation_form_data["severity_level"] || (@evaluation_form_data["damage_areas"] && length(@evaluation_form_data["damage_areas"]) > 0) do %>
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
          <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
            <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Resumen de Evaluación</h3>
          </div>
          <div class="p-6">
            <div class="space-y-3">
              <%= if @evaluation_form_data["severity_level"] do %>
                <div class="flex items-center gap-2">
                  <span class="text-sm text-slate-600 dark:text-slate-400">Severidad:</span>
                  <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{get_severity_color(@evaluation_form_data["severity_level"])}"}>
                    <%= get_severity_label(@evaluation_form_data["severity_level"]) %>
                  </span>
                </div>
              <% end %>
              <%= if @evaluation_form_data["damage_areas"] && length(@evaluation_form_data["damage_areas"]) > 0 do %>
                <div>
                  <span class="text-sm text-slate-600 dark:text-slate-400">Áreas afectadas: </span>
                  <span class="text-sm font-medium text-slate-900 dark:text-slate-100"><%= Enum.join(@evaluation_form_data["damage_areas"], ", ") %></span>
                </div>
              <% end %>
              <%= if @evaluation_form_data["estimated_cost"] && @evaluation_form_data["estimated_cost"] != "" do %>
                <div>
                  <span class="text-sm text-slate-600 dark:text-slate-400">Costo estimado: </span>
                  <span class="text-sm font-medium text-slate-900 dark:text-slate-100">$<%= @evaluation_form_data["estimated_cost"] %></span>
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
          <button type="button" phx-click="submit_evaluation" phx-value-action="draft"
                  class="px-4 py-2 text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
            <svg class="h-4 w-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"></path>
            </svg>
            Guardar Borrador
          </button>
          <button type="button" phx-click="submit_evaluation" phx-value-action="submit"
                  class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors">
            <svg class="h-4 w-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
            </svg>
            Enviar Evaluación
          </button>
        </div>
      </div>
    </form>
    """
  end

  defp render_maintenance_form(assigns) do
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
            <!-- Nota informativa sobre la funcionalidad de upload -->
            <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-4">
              <div class="flex items-start">
                <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <div>
                  <h4 class="text-sm font-medium text-blue-800 dark:text-blue-200 mb-1">
                    Subida de archivos disponible después de crear el ticket
                  </h4>
                  <p class="text-sm text-blue-700 dark:text-blue-300">
                    Una vez creado el ticket de mantenimiento, podrás subir fotos y documentos PDF desde la vista detallada del ticket. 
                    Esta funcionalidad estará disponible en la página de detalles del mantenimiento.
                  </p>
                </div>
              </div>
            </div>

            <!-- Botón temporal deshabilitado -->
            <button disabled class="px-3 py-1 border border-slate-300 dark:border-slate-600 rounded-lg bg-slate-100 dark:bg-slate-700 text-slate-500 dark:text-slate-400 cursor-not-allowed text-sm opacity-50">
              <svg class="w-4 h-4 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
              </svg>
              Subir Archivo (Próximamente)
            </button>

            <!-- Lista de archivos existentes -->
            <div class="mt-6">
              <h4 class="text-lg font-medium mb-4">Archivos Adjuntos</h4>
              <div class="bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg p-4 text-center">
                <svg class="h-12 w-12 mx-auto mb-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
                <p class="text-slate-600 dark:text-slate-400 mb-2">Fotos y documentos se gestionarán en la vista detallada</p>
                <p class="text-sm text-slate-500 dark:text-slate-500">Después de crear el ticket de mantenimiento, podrás subir fotos y PDFs desde la página de detalles del ticket</p>
              </div>
            </div>
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
      <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
        <div class="flex items-center gap-3">
          <svg class="h-6 w-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          <div>
            <h3 class="font-semibold text-green-800 dark:text-green-200">¡Ticket Creado Exitosamente!</h3>
            <p class="text-sm text-green-700 dark:text-green-300">El proceso de check-in se ha completado</p>
          </div>
        </div>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-slate-50 dark:bg-slate-800 rounded-lg p-4">
          <h4 class="font-semibold text-slate-900 dark:text-slate-100 mb-3">Información del Camión</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-slate-600 dark:text-slate-400">Placa:</span>
              <span class="font-medium text-slate-900 dark:text-slate-100"><%= @found_truck.license_plate %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600 dark:text-slate-400">Marca:</span>
              <span class="font-medium text-slate-900 dark:text-slate-100"><%= @found_truck.brand %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600 dark:text-slate-400">Modelo:</span>
              <span class="font-medium text-slate-900 dark:text-slate-100"><%= @found_truck.model %></span>
            </div>
          </div>
        </div>
        
        <%= if Map.has_key?(assigns, :created_ticket) and assigns.created_ticket do %>
          <div class="bg-slate-50 dark:bg-slate-800 rounded-lg p-4">
            <h4 class="font-semibold text-slate-900 dark:text-slate-100 mb-3">
              <%= if @entry_type == :production do %>
                Información de la Orden
              <% else %>
                Información del Ticket
              <% end %>
            </h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600 dark:text-slate-400">ID:</span>
                <span class="font-medium text-slate-900 dark:text-slate-100">#<%= @created_ticket.id %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600 dark:text-slate-400">Estado:</span>
                <span class="font-medium text-slate-900 dark:text-slate-100">
                  <%= if @entry_type == :production do %>
                    Nueva Orden
                  <% else %>
                    Check-in
                  <% end %>
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600 dark:text-slate-400">Fecha:</span>
                <span class="font-medium text-slate-900 dark:text-slate-100">
                  <%= if safe_get_field(@created_ticket, :entry_date) do %>
                    <%= Calendar.strftime(safe_get_field(@created_ticket, :entry_date), "%d/%m/%Y %H:%M") %>
                  <% else %>
                    <%= if safe_get_field(@created_ticket, :inserted_at) do %>
                      <%= Calendar.strftime(safe_get_field(@created_ticket, :inserted_at), "%d/%m/%Y %H:%M") %>
                    <% else %>
                      Fecha no especificada
                    <% end %>
                  <% end %>
                </span>
              </div>
              <%= if @entry_type == :production and @created_ticket.box_type do %>
                <div class="flex justify-between">
                  <span class="text-slate-600 dark:text-slate-400">Tipo de Caja:</span>
                  <span class="font-medium text-slate-900 dark:text-slate-100">
                    <%= if @created_ticket.box_type == "refrigerada" do %>
                      🧊 Refrigerada
                    <% else %>
                      📦 Seca
                    <% end %>
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-600 dark:text-slate-400">Cliente:</span>
                  <span class="font-medium text-slate-900 dark:text-slate-100">
                    <%= @created_ticket.client_name %>
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-600 dark:text-slate-400">Camión:</span>
                  <span class="font-medium text-slate-900 dark:text-slate-100">
                    <%= @created_ticket.truck_brand %> <%= @created_ticket.truck_model %>
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-col sm:flex-row gap-4 justify-center">
        <%= if @entry_type == :production do %>
          <button phx-click="go_to_production_orders" 
                  class="px-6 py-3 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition-colors">
            Ver Órdenes de Producción
          </button>
        <% else %>
          <button phx-click="go_to_tickets" 
                  class="px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors">
            Ver Tickets
          </button>
        <% end %>
        
        <button phx-click="back_to_start" 
                class="px-6 py-3 bg-slate-600 text-white font-semibold rounded-lg hover:bg-slate-700 transition-colors">
          Crear Otro Ticket
        </button>
      </div>
    </div>
    """
  end

  # Modales
  defp render_modals(assigns) do
    ~H"""
    <!-- Modal de Camiones Existentes -->
    <%= if @show_existing_trucks_modal do %>
      <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-hidden">
          <div class="p-6 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
                Seleccionar Camión Existente
              </h3>
              <button phx-click="hide_existing_trucks_modal" 
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
          </div>
          
          <div class="p-6">
            <div class="max-h-96 overflow-y-auto space-y-3">
              <%= if @filtered_trucks && length(@filtered_trucks) > 0 do %>
                <%= for truck <- @filtered_trucks do %>
                  <button phx-click="select_truck" phx-value-truck-id={truck.id} 
                          class="w-full p-4 border border-slate-200 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors text-left">
                    <div class="flex items-center justify-between">
                      <div>
                        <h4 class="font-semibold text-slate-900 dark:text-slate-100">
                          <%= truck.brand %> <%= truck.model %>
                        </h4>
                        <p class="text-sm text-slate-600 dark:text-slate-400">
                          Placa: <%= truck.license_plate %> | Año: <%= truck.year %>
                        </p>
                        <%= if truck.kilometraje && truck.kilometraje > 0 do %>
                          <p class="text-xs text-slate-500 dark:text-slate-500">
                            Kilometraje: <%= truck.kilometraje %> km
                          </p>
                        <% end %>
                      </div>
                      <svg class="w-5 h-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                      </svg>
                    </div>
                  </button>
                <% end %>
              <% else %>
                <div class="text-center py-8">
                  <svg class="w-12 h-12 text-slate-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"></path>
                  </svg>
                  <p class="text-slate-500 dark:text-slate-400">No hay camiones registrados</p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Modal de Nuevo Camión -->
    <%= if @show_new_truck_form do %>
      <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
          <div class="p-6 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
                Registrar Nuevo Camión
              </h3>
              <button phx-click="hide_new_truck_form" 
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
          </div>
          
          <form phx-submit="save_new_truck" class="p-6 space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Marca *</label>
                <input type="text" name="truck[brand]" required
                       class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                       placeholder="Ej: Volvo">
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Modelo *</label>
                <input type="text" name="truck[model]" required
                       class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                       placeholder="Ej: FH 460">
              </div>
            </div>
            
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Placa *</label>
                <input type="text" name="truck[license_plate]" required
                       class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                       placeholder="ABC-123">
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Año</label>
                <input type="number" name="truck[year]"
                       class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                       placeholder="2020">
              </div>
            </div>
            
            <div class="flex gap-3 pt-4">
              <button type="button" phx-click="hide_new_truck_form"
                      class="flex-1 px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors">
                Cancelar
              </button>
              <button type="submit"
                      class="flex-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 transition-colors">
                Registrar Camión
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  # Event handlers for evaluation form
  @impl true
  def handle_event("evaluation_field_changed", %{"field" => field, "value" => value}, socket) do
    current_data = socket.assigns.evaluation_form_data || %{}
    
    updated_data = case field do
      "damage_areas" ->
        areas = current_data["damage_areas"] || []
        if value in areas do
          Map.put(current_data, "damage_areas", List.delete(areas, value))
        else
          Map.put(current_data, "damage_areas", [value | areas])
        end
      _ ->
        Map.put(current_data, field, value)
    end
    
    {:noreply, assign(socket, :evaluation_form_data, updated_data)}
  end

  @impl true
  def handle_event("evaluation_field_changed", %{"field" => field}, socket) do
    # Handle radio buttons and checkboxes without value
    current_data = socket.assigns.evaluation_form_data || %{}
    updated_data = Map.put(current_data, field, true)
    {:noreply, assign(socket, :evaluation_form_data, updated_data)}
  end

  @impl true
  def handle_event("evaluation_field_changed", %{"evaluation" => evaluation_data}, socket) do
    current_data = socket.assigns.evaluation_form_data || %{}
    updated_data = Map.merge(current_data, evaluation_data)
    {:noreply, assign(socket, :evaluation_form_data, updated_data)}
  end

  @impl true
  def handle_event("save_evaluation_draft", params, socket) do
    # Extract evaluation data from params
    evaluation_data = params["evaluation"] || %{}
    
    # Update socket with the form data
    socket = assign(socket, :evaluation_form_data, evaluation_data)
    
    # Save evaluation as draft (status: draft)
    case create_evaluation_ticket(socket, "draft") do
      {:ok, _ticket} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Borrador guardado exitosamente")
         |> push_navigate(to: "/evaluations")}
      {:error, _changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al guardar el borrador")}
    end
  end

  @impl true
  def handle_event("submit_evaluation", params, socket) do
    # Debug logging
    IO.inspect("SUBMIT_EVALUATION CALLED!", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] submit_evaluation params")
    IO.inspect(socket.assigns.found_truck, label: "[DEBUG] found_truck")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] photo_entries")
    
    # Extract evaluation data from socket assigns (since we're using phx-change)
    evaluation_data = socket.assigns.evaluation_form_data || %{}
    action = params["action"] || "submit"
    
    # Debug logging for form data
    IO.inspect(params, label: "[DEBUG] ALL PARAMS")
    IO.inspect(evaluation_data, label: "[DEBUG] evaluation_data from form")
    IO.inspect(evaluation_data["damage_areas"], label: "[DEBUG] damage_areas")
    IO.inspect(evaluation_data["description"], label: "[DEBUG] description")
    IO.inspect(evaluation_data["severity_level"], label: "[DEBUG] severity_level")
    IO.inspect(evaluation_data["estimated_cost"], label: "[DEBUG] estimated_cost")
    IO.inspect(evaluation_data["evaluation_type"], label: "[DEBUG] evaluation_type")
    IO.inspect(evaluation_data["delivered_by"], label: "[DEBUG] delivered_by")
    IO.inspect(evaluation_data["driver_cedula"], label: "[DEBUG] driver_cedula")
    IO.inspect(evaluation_data["notes"], label: "[DEBUG] notes")
    
    # Update socket with the form data
    socket = assign(socket, :evaluation_form_data, evaluation_data)
    
    case action do
      "draft" ->
        # Save evaluation as draft
        case create_evaluation_ticket(socket, "draft") do
          {:ok, _ticket} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Borrador guardado exitosamente")
             |> push_navigate(to: "/evaluations")}
          {:error, _changeset} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al guardar el borrador")}
        end
      "submit" ->
        # Submit evaluation (status: check_in)
        case create_evaluation_ticket(socket, "check_in") do
          {:ok, ticket} ->
            # Cargar fotos existentes de la evaluación creada
            existing_photos = FileUploadUtils.get_entity_files(ticket, "evaluation", FileUploadUtils.standard_field_mapping())
            
            {:noreply, 
             socket
             |> assign(current_step: 5)
             |> assign(created_ticket: ticket)
             |> assign(existing_files: existing_photos)
             |> put_flash(:info, "Evaluación enviada exitosamente")}
          {:error, error_message} when is_binary(error_message) ->
            IO.inspect(error_message, label: "[DEBUG] error message")
            {:noreply, 
             socket
             |> put_flash(:error, error_message)}
          {:error, changeset} ->
            IO.inspect(changeset, label: "[DEBUG] changeset errors")
            {:noreply, 
             socket
             |> put_flash(:error, "Error al enviar la evaluación")}
        end
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :evaluation_photos, ref)}
  end

  @impl true
  def handle_event("ignore", _params, socket) do
    {:noreply, socket}
  end

  # Handle upload events
  @impl true
  def handle_event("phx-upload", %{"_target" => ["evaluation_photos"]}, socket) do
    IO.inspect("Upload event triggered", label: "[DEBUG]")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] upload entries")
    {:noreply, socket}
  end

  @impl true
  def handle_event("phx-upload", params, socket) do
    IO.inspect("Generic upload event", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] upload params")
    {:noreply, socket}
  end

  # Handle file selection
  @impl true
  def handle_event("phx-upload", %{"_target" => ["evaluation_photos"], "entries" => entries}, socket) do
    IO.inspect("File selection event", label: "[DEBUG]")
    IO.inspect(entries, label: "[DEBUG] selected files")
    {:noreply, socket}
  end

  # Catch all upload events
  @impl true
  def handle_event("phx-upload", params, socket) do
    IO.inspect("Any upload event", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] any upload params")
    {:noreply, socket}
  end

  # Handle any event that might be related to uploads
  @impl true
  def handle_event(event, params, socket) when event in ["phx-upload", "phx-upload-progress", "phx-upload-error"] do
    IO.inspect("Upload related event: #{event}", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] upload related params")
    {:noreply, socket}
  end

  # Handle automatic upload events
  @impl true
  def handle_event("phx-upload", %{"_target" => ["evaluation_photos"]}, socket) do
    IO.inspect("Auto upload triggered", label: "[DEBUG]")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] auto upload entries")
    {:noreply, socket}
  end

  # Handle any upload event
  @impl true
  def handle_event("phx-upload", params, socket) do
    IO.inspect("Any upload event", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] upload params")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] current entries")
    {:noreply, socket}
  end

  # Handle any event that might be related to uploads
  @impl true
  def handle_event(event, params, socket) when event in ["phx-upload", "phx-upload-progress", "phx-upload-error", "phx-upload-done"] do
    IO.inspect("Upload related event: #{event}", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] upload related params")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] current entries")
    {:noreply, socket}
  end

  # Event handlers for universal file upload component
  def handle_event("show_upload_modal", _params, socket) do
    IO.inspect("Opening upload modal", label: "[DEBUG]")
    IO.inspect(socket.assigns.current_step, label: "[DEBUG] Current step when opening modal")
    {:noreply, assign(socket, :show_upload_modal, true)}
  end

  def handle_event("close_upload_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})}
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
    {:noreply, cancel_upload(socket, :evaluation_photos, ref)}
  end

  def handle_event("validate_attachments", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save_attachments", params, socket) do
    IO.inspect("Save attachments event triggered", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] Save attachments params")
    IO.inspect(socket.assigns.current_step, label: "[DEBUG] Current step")
    
    # Procesar archivos subidos usando el mismo enfoque que ticket_detail_live
    uploaded_files = consume_uploaded_entries(socket, :evaluation_photos, fn %{path: path}, entry ->
      IO.inspect("Processing file: #{entry.client_name}", label: "[DEBUG]")
      
      # Crear directorio para archivos si no existe
      upload_dir = Path.join(["priv", "static", "uploads", "evaluations", "temp"])
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
        path: "/uploads/evaluations/temp/#{unique_filename}",
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

  def handle_event("show_delete_modal", %{"index" => index}, socket) do
    # Implementar lógica de eliminación
    {:noreply, socket}
  end

  def handle_event("delete_file", %{"index" => index}, socket) do
    if socket.assigns.created_ticket do
      case FileUploadUtils.delete_entity_file(
        socket.assigns.created_ticket, 
        String.to_integer(index), 
        :photos
      ) do
        {:ok, updated_ticket} ->
          # Actualizar la lista de archivos existentes
          existing_photos = FileUploadUtils.get_entity_files(updated_ticket, "evaluation", FileUploadUtils.standard_field_mapping())
          
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
      existing_files = List.delete_at(socket.assigns.existing_files, String.to_integer(index))
      {:noreply, 
       socket
       |> assign(:existing_files, existing_files)
       |> put_flash(:info, "Archivo eliminado correctamente")}
    end
  end

  def handle_event("remove_file", %{"file_path" => file_path}, socket) do
    # Encontrar el índice del archivo en la lista
    file_index = Enum.find_index(socket.assigns.existing_files, fn file -> file.path == file_path end)
    
    if file_index do
      if socket.assigns.created_ticket do
        case FileUploadUtils.delete_entity_file(
          socket.assigns.created_ticket, 
          file_index, 
          :photos
        ) do
          {:ok, updated_ticket} ->
            # Actualizar la lista de archivos existentes
            existing_photos = FileUploadUtils.get_entity_files(updated_ticket, "evaluation", FileUploadUtils.standard_field_mapping())
            
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

  def handle_event("validate_attachments", _params, socket) do
    {:noreply, socket}
  end

  # Event handlers para el modal de upload
  def handle_event("show_upload_modal", _params, socket) do
    IO.inspect("show_upload_modal called in LiveView", label: "[DEBUG]")
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
    {:noreply, cancel_upload(socket, :evaluation_photos, ref)}
  end



  # Handle messages from the universal file upload component
  def handle_info({:files_uploaded, uploaded_files}, socket) do
    if length(uploaded_files) > 0 do
      # Actualizar la lista de archivos existentes
      existing_files = socket.assigns.existing_files ++ uploaded_files
      
      # Si ya tenemos un ticket creado, actualizar la base de datos
      if socket.assigns.created_ticket do
        case FileUploadUtils.update_entity_files(socket.assigns.created_ticket, uploaded_files, :photos) do
          {:ok, updated_ticket} ->
            {:noreply, 
             socket
             |> assign(:existing_files, existing_files)
             |> assign(:created_ticket, updated_ticket)
             |> put_flash(:info, "Archivos subidos correctamente")}
          {:error, _changeset} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al guardar los archivos")}
        end
      else
        # Solo actualizar el estado local si no hay ticket creado
        {:noreply, 
         socket
         |> assign(:existing_files, existing_files)
         |> put_flash(:info, "Archivos subidos correctamente")}
      end
    else
      {:noreply, 
       socket
       |> put_flash(:info, "No se seleccionaron archivos")}
    end
  end

  def handle_info({:delete_file, index}, socket) do
    if socket.assigns.created_ticket do
      case FileUploadUtils.delete_entity_file(
        socket.assigns.created_ticket, 
        index, 
        :photos
      ) do
        {:ok, updated_ticket} ->
          # Actualizar la lista de archivos existentes
          existing_photos = FileUploadUtils.get_entity_files(updated_ticket, "evaluation", FileUploadUtils.standard_field_mapping())
          
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
      existing_files = List.delete_at(socket.assigns.existing_files, index)
      {:noreply, 
       socket
       |> assign(:existing_files, existing_files)
       |> put_flash(:info, "Archivo eliminado correctamente")}
    end
  end

  # Catch all events for debugging
  @impl true
  def handle_event(event, params, socket) do
    if String.contains?(event, "upload") or String.contains?(event, "file") do
      IO.inspect("Event that might be upload related: #{event}", label: "[DEBUG]")
      IO.inspect(params, label: "[DEBUG] event params")
    end
    {:noreply, socket}
  end



  # Helper functions for evaluation form
  defp create_evaluation_ticket(socket, _status) do
    found_truck = socket.assigns.found_truck
    evaluation_data = socket.assigns.evaluation_form_data || %{}
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    # Validate that we have a truck
    if is_nil(found_truck) do
      {:error, "No se ha seleccionado un camión"}
    else
      # Build title with evaluation type
      evaluation_type = evaluation_data["evaluation_type"] || "otro"
      type_label = get_evaluation_type_label(evaluation_type)
      title = "#{type_label} - #{found_truck.license_plate}"
      
      # Build description with damage description and evaluation details
      base_description = evaluation_data["description"] || "Sin descripción del daño"
      evaluation_details = evaluation_data["evaluation_details"] || ""
      
      description = if evaluation_details != "" do
        "#{base_description}\n\nDetalles específicos: #{evaluation_details}"
      else
        base_description
      end
      
      # Process damage areas from checkboxes
      damage_areas = case evaluation_data["damage_areas"] do
        areas when is_list(areas) -> areas
        _ -> []
      end
      
      # Debug logging for evaluation data
      IO.inspect(evaluation_data, label: "[DEBUG] evaluation_data in create_evaluation_ticket")
      IO.inspect(damage_areas, label: "[DEBUG] processed damage_areas")
      
      # Create evaluation parameters
      evaluation_params = %{
        "title" => title,
        "description" => description,
        "truck_id" => found_truck.id,
        "business_id" => socket.assigns.current_user.business_id,
        "evaluation_date" => now,
        "evaluation_type" => evaluation_data["evaluation_type"] || "otro",
        "evaluated_by" => evaluation_data["delivered_by"] || "",
        "driver_cedula" => evaluation_data["driver_cedula"] || "",
        "damage_areas" => damage_areas,
        "severity_level" => evaluation_data["severity_level"] || "medium",
        "estimated_cost" => parse_decimal(evaluation_data["estimated_cost"]),
        "notes" => evaluation_data["notes"] || "",
        "evaluation_details" => evaluation_details,
        "status" => "pending"
      }
      
      IO.inspect(evaluation_params, label: "[DEBUG] evaluation_params")
      IO.inspect(evaluation_params["damage_areas"], label: "[DEBUG] damage_areas in params")
      IO.inspect(evaluation_params["description"], label: "[DEBUG] description in params")
      IO.inspect(evaluation_params["severity_level"], label: "[DEBUG] severity_level in params")
      IO.inspect(evaluation_params["estimated_cost"], label: "[DEBUG] estimated_cost in params")
      
      case EvaaCrmGaepell.Evaluation.create_evaluation(evaluation_params, socket.assigns.current_user.id) do
        {:ok, evaluation} ->
          # Procesar archivos automáticamente después de crear la evaluación
          # (Los archivos se suben automáticamente al crear el ticket)
          if length(socket.assigns.uploads.evaluation_photos.entries) > 0 do
            handle_evaluation_photos(socket, evaluation)
          end
          
          # Handle photos from universal system if any
          if length(socket.assigns.existing_files || []) > 0 do
            handle_universal_photos(socket, evaluation)
          end
          
          # Cargar fotos existentes de la evaluación creada
          existing_photos = FileUploadUtils.get_entity_files(evaluation, "evaluation", FileUploadUtils.standard_field_mapping())
          
          {:ok, evaluation}
        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  defp handle_evaluation_photos(socket, evaluation) do
    IO.inspect("Handling evaluation photos with universal system", label: "[DEBUG]")
    
    # Procesar archivos subidos usando las utilidades universales
    uploaded_files = FileUploadUtils.process_uploaded_files(
      socket, 
      :evaluation_photos, 
      "evaluation", 
      evaluation.id, 
      socket.assigns.file_descriptions || %{}
    )
    
    IO.inspect(uploaded_files, label: "[DEBUG] uploaded files")
    
    # Actualizar la evaluación con los archivos procesados
    if length(uploaded_files) > 0 do
      case FileUploadUtils.update_entity_files(evaluation, uploaded_files, :photos) do
        {:ok, _updated_evaluation} -> 
          IO.inspect("Photos saved successfully with universal system", label: "[DEBUG]")
          :ok
        {:error, _changeset} -> 
          IO.inspect("Error saving photos with universal system", label: "[DEBUG]")
          :error
      end
    end
  end

  defp handle_universal_photos(socket, evaluation) do
    IO.inspect("Handling universal photos", label: "[DEBUG]")
    IO.inspect(socket.assigns.existing_files, label: "[DEBUG] existing files")
    
    # Actualizar la evaluación con los archivos del sistema universal
    if length(socket.assigns.existing_files) > 0 do
      case FileUploadUtils.update_entity_files(evaluation, socket.assigns.existing_files, :photos) do
        {:ok, _updated_evaluation} -> 
          IO.inspect("Universal photos saved successfully", label: "[DEBUG]")
          :ok
        {:error, _changeset} -> 
          IO.inspect("Error saving universal photos", label: "[DEBUG]")
          :error
      end
    end
  end

  defp parse_decimal(value) when is_binary(value) and value != "" do
    case Decimal.parse(value) do
      {:ok, decimal} -> decimal
      _ -> nil
    end
  end
  defp parse_decimal(_), do: nil

  defp get_severity_color(severity) do
    case severity do
      "high" -> "bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-400"
      "medium" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-400"
      "low" -> "bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-400"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/50 dark:text-gray-400"
    end
  end

  defp get_severity_label(severity) do
    case severity do
      "high" -> "Alto"
      "medium" -> "Medio"
      "low" -> "Bajo"
      _ -> "No especificado"
    end
  end

  # Upload event handlers for debugging
  def handle_event("phx-upload", %{"_target" => ["evaluation_photos"]} = params, socket) do
    IO.inspect("DEBUG: phx-upload event for evaluation_photos", label: "UPLOAD_EVENT")
    IO.inspect(params, label: "UPLOAD_PARAMS")
    {:noreply, socket}
  end

  def handle_event("phx-upload-progress", %{"_target" => ["evaluation_photos"]} = params, socket) do
    IO.inspect("DEBUG: phx-upload-progress event", label: "UPLOAD_PROGRESS")
    IO.inspect(params, label: "PROGRESS_PARAMS")
    {:noreply, socket}
  end

  def handle_event("phx-upload-error", %{"_target" => ["evaluation_photos"]} = params, socket) do
    IO.inspect("DEBUG: phx-upload-error event", label: "UPLOAD_ERROR")
    IO.inspect(params, label: "ERROR_PARAMS")
    {:noreply, socket}
  end

  def handle_event("phx-upload-done", %{"_target" => ["evaluation_photos"]} = params, socket) do
    IO.inspect("DEBUG: phx-upload-done event", label: "UPLOAD_DONE")
    IO.inspect(params, label: "DONE_PARAMS")
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :evaluation_photos, ref)}
  end

  def handle_event("upload_photos", _params, socket) do
    IO.inspect("Manual upload triggered", label: "[DEBUG]")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] entries to upload")
    {:noreply, socket}
  end

  def handle_event("manual_upload_triggered", params, socket) do
    IO.inspect("Manual upload triggered from JavaScript", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] manual upload params")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] current entries")
    {:noreply, socket}
  end

  def handle_event("evaluation_file_selected", params, socket) do
    IO.inspect("Evaluation file selected from JavaScript", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] evaluation file params")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] current entries")
    IO.inspect(socket.assigns.uploads.evaluation_photos.ref, label: "[DEBUG] upload ref")
    {:noreply, socket}
  end

  def handle_event("force_upload_processing", params, socket) do
    IO.inspect("Force upload processing from JavaScript", label: "[DEBUG]")
    IO.inspect(params, label: "[DEBUG] force upload params")
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] current entries after force")
    
    # Intentar forzar una actualización del socket
    socket = 
      socket
      |> assign(:debug_message, "Forzando procesamiento de upload...")
      |> assign(:upload_debug, %{
        entries_count: length(socket.assigns.uploads.evaluation_photos.entries),
        files_selected: Map.get(params, "files", [])
      })
    
    {:noreply, socket}
  end

  # Generic event handler for debugging
  def handle_event(event, params, socket) when is_binary(event) do
    cond do
      String.contains?(event, "upload") or String.contains?(event, "file") ->
        IO.inspect("DEBUG: Generic upload/file event: #{event}", label: "UPLOAD_DEBUG")
        IO.inspect(params, label: "UPLOAD_PARAMS")
        {:noreply, socket}
      true ->
        {:noreply, socket}
    end
  end

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
        "title" => "Mantenimiento - #{found_truck.license_plate}",
        "description" => maintenance_data["description"] || "",
        "priority" => maintenance_data["priority"] || "medium",
        "entry_date" => parse_date(maintenance_data["date"]),
        "mileage" => parse_integer(maintenance_data["mileage"]),
        "fuel_level" => maintenance_data["fuel_level"],
        "visible_damage" => maintenance_data["visible_damage"],
        "color" => maintenance_data["color"],
        "status" => "check_in",
        "business_id" => current_user.business_id,
        "truck_id" => found_truck.id,
        "damage_photos" => photo_paths,
        # Guardar información adicional en campos existentes
        "deliverer_name" => maintenance_data["delivered_by"],
        "document_number" => maintenance_data["driver_cedula"],
        "evaluation_notes" => "Tipo: #{maintenance_data["maintenance_type"] || "No especificado"}\nÁreas: #{Enum.join(maintenance_data["maintenance_areas"] || [], ", ")}",
        "estimated_repair_cost" => parse_decimal(maintenance_data["estimated_cost"])
      }
    
    case EvaaCrmGaepell.Fleet.create_maintenance_ticket(Map.put(maintenance_params, :user_id, current_user.id)) do
      {:ok, ticket} ->
        # Crear log de actividad
        ActivityLog.create_log(%{
          "action" => "created",
          "description" => "creó maintenance ticket '#{ticket.title}'",
          "user_id" => current_user.id,
          "business_id" => current_user.business_id,
          "entity_id" => ticket.id,
          "entity_type" => "maintenance_ticket"
        })
        {:ok, ticket}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp parse_date(date_string) when is_binary(date_string) and date_string != "" do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
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

  defp parse_decimal(value) when is_binary(value) and value != "" do
    case Decimal.parse(value) do
      {:ok, decimal} -> decimal
      _ -> nil
    end
  end
  defp parse_decimal(_), do: nil

  defp error_to_string_helper(:too_large), do: "El archivo es demasiado grande"
  defp error_to_string_helper(:too_many_files), do: "Demasiados archivos"
  defp error_to_string_helper(:not_accepted), do: "Tipo de archivo no aceptado"
  defp error_to_string_helper(_), do: "Error al subir el archivo"

  defp create_production_order(socket) do
    production_data = socket.assigns.production_form_data
    found_truck = socket.assigns.found_truck
    current_user = socket.assigns.current_user
    
    # Preparar parámetros para crear la orden de producción
    production_params = %{
      "client_name" => production_data["delivered_by"] || "No especificado",
      "truck_brand" => found_truck.brand,
      "truck_model" => found_truck.model,
      "license_plate" => found_truck.license_plate,
      "box_type" => production_data["box_type"] || "seca",
      "specifications" => "Producción de caja #{production_data["box_type"] || "seca"} para camión #{found_truck.brand} #{found_truck.model}",
      "estimated_delivery" => parse_date(production_data["estimated_delivery"]),
      "status" => "new_order",
      "notes" => production_data["notes"] || "",
      "business_id" => current_user.business_id
    }
    
    case EvaaCrmGaepell.ProductionOrder.create_production_order(production_params) do
      {:ok, order} ->
        # Crear log de actividad
        ActivityLog.create_log(%{
          "action" => "created",
          "description" => "creó orden de producción para camión #{found_truck.license_plate}",
          "user_id" => current_user.id,
          "business_id" => current_user.business_id,
          "entity_id" => order.id,
          "entity_type" => "production_order"
        })
        {:ok, order}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp format_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end

  def safe_get_field(struct, field, default \\ nil) do
    case Map.get(struct, field) do
      nil -> default
      value -> value
    end
  end

  defp get_evaluation_type_label(type) do
    case type do
      "garantia" -> "Garantía"
      "colision" -> "Colisión"
      "desgaste" -> "Desgaste"
      "otro" -> "Otro"
      _ -> "Desconocido"
    end
  end

  # Upload Modal - Moved outside of forms to prevent nesting issues
  defp render_upload_modal(assigns) do
    ~H"""
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
              <p class="text-center text-slate-600 dark:text-slate-400">
                Selecciona archivos para subir
              </p>
              
              <.live_file_input upload={@uploads.evaluation_photos} 
                  class="block w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                  accept=".jpg,.jpeg,.png,.gif,.pdf,.doc,.docx,.txt,.xlsx,.xls" />
              
              <%= if length(@uploads.evaluation_photos.entries) > 0 do %>
                <div class="space-y-2">
                  <h4 class="text-sm font-medium">Archivos seleccionados:</h4>
                  <%= for entry <- @uploads.evaluation_photos.entries do %>
                    <div class="flex items-center justify-between p-2 bg-slate-50 rounded">
                      <span class="text-sm"><%= entry.client_name %></span>
                      <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} class="text-red-500">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>

            <div class="flex justify-end space-x-3 mt-6">
              <button type="button" phx-click="close_upload_modal"
                      class="px-4 py-2 border border-slate-300 rounded-lg text-sm">
                Cancelar
              </button>
              <button type="button" phx-click="save_attachments"
                      disabled={length(@uploads.evaluation_photos.entries) == 0}
                      class="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm disabled:opacity-50">
                Subir Archivos
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

