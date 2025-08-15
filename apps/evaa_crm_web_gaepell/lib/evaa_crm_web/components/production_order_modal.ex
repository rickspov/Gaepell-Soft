defmodule EvaaCrmWebGaepell.ProductionOrderModal do
  use EvaaCrmWebGaepell, :live_component

  alias EvaaCrmGaepell.{MaintenanceTicket, Quotation, Repo, ProductionOrder}
  import Ecto.Query

  @impl true
  def update(assigns, socket) do
    changeset = assigns[:changeset] || MaintenanceTicket.changeset(%MaintenanceTicket{}, %{})
    
    # Cargar tipos de caja disponibles
    box_types = [
      {"Plataforma", "plataforma"},
      {"Caja Seca", "caja_seca"},
      {"Caja Refrigerada", "caja_refrigerada"},
      {"Caja Térmica", "caja_termica"},
      {"Caja Especializada", "caja_especializada"},
      {"Otro", "otro"}
    ]
    
    # Cargar cotizaciones disponibles
    quotations = assigns[:quotations] || []
    
    {:ok, 
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:box_types, box_types)
     |> assign(:quotations, quotations)
     |> assign(:selected_quotation, nil)
     |> assign(:show_quotation_details, false)}
  end

  @impl true
  def handle_event("save", %{"maintenance_ticket" => params}, socket) do
    # Obtener información del camión
    truck = if socket.assigns[:truck_id] do
      EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.Truck, socket.assigns.truck_id)
    else
      nil
    end

    # Preparar parámetros para la orden de producción
    production_params = %{
      "client_name" => truck && truck.owner || "Cliente",
      "truck_brand" => truck && truck.brand || "",
      "truck_model" => truck && truck.model || "",
      "license_plate" => truck && truck.license_plate || "",
      "box_type" => map_box_type(params["box_type"]),
      "specifications" => params["description"] || "",
      "estimated_delivery" => parse_date(params["estimated_delivery"]),
      "status" => "new_order",
      "notes" => params["title"] || "Orden de producción",
      "business_id" => socket.assigns.business_id
    }
    
    # Si hay quotation_id seleccionado, agregarlo
    production_params = if socket.assigns.selected_quotation do
      Map.put(production_params, "notes", "Orden basada en cotización #{socket.assigns.selected_quotation.quotation_number}")
    else
      production_params
    end

    case %EvaaCrmGaepell.ProductionOrder{}
         |> EvaaCrmGaepell.ProductionOrder.changeset(production_params)
         |> Repo.insert() do
      {:ok, order} ->
        send(self(), {:production_order_created, order})
        {:noreply, 
         socket
         |> put_flash(:success, "Orden de producción creada exitosamente")}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("select_quotation", %{"quotation_id" => quotation_id}, socket) do
    quotation = Enum.find(socket.assigns.quotations, & &1.id == String.to_integer(quotation_id))
    
    if quotation do
      # Auto-llenar detalles de la cotización
      changeset = socket.assigns.changeset
      |> Ecto.Changeset.put_change(:title, "Orden de producción - #{quotation.client_name}")
      |> Ecto.Changeset.put_change(:description, quotation.special_requirements || "Orden basada en cotización #{quotation.quotation_number}")
      
      {:noreply,
       socket
       |> assign(:selected_quotation, quotation)
       |> assign(:changeset, changeset)
       |> assign(:show_quotation_details, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_quotation", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_quotation, nil)
     |> assign(:show_quotation_details, false)}
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), :close_production_order_modal)
    {:noreply, socket}
  end



  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" 
         phx-click="close" phx-target={@myself}>
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto"
           phx-click="ignore">
        
        <!-- Header -->
        <div class="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center">
              <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
              </svg>
            </div>
            <div>
              <h2 class="text-xl font-bold text-gray-900 dark:text-white">Nueva Orden de Producción</h2>
              <p class="text-sm text-gray-500 dark:text-gray-400">Crear orden para fabricación de caja</p>
            </div>
          </div>
          <button phx-click="close" phx-target={@myself} class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <!-- Form -->
        <form phx-submit="save" phx-target={@myself} class="p-6 space-y-6">
          
          <!-- Tipo de Caja -->
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
            <h3 class="text-lg font-semibold mb-3 text-blue-900 dark:text-blue-100">Tipo de Caja</h3>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
              <%= for {label, value} <- @box_types do %>
                <label class="relative">
                  <input type="radio" name="maintenance_ticket[box_type]" value={value} 
                         class="sr-only peer" required>
                  <div class="p-3 border-2 border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer
                              peer-checked:border-blue-500 peer-checked:bg-blue-50 dark:peer-checked:bg-blue-900/30
                              hover:border-gray-300 dark:hover:border-gray-500 transition-colors">
                    <div class="text-center">
                      <div class="text-sm font-medium text-gray-900 dark:text-white"><%= label %></div>
                    </div>
                  </div>
                </label>
              <% end %>
            </div>
          </div>

          <!-- Cotización de Symasoft (Opcional) -->
          <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
            <h3 class="text-lg font-semibold mb-3 text-yellow-900 dark:text-yellow-100">
              Cotización de Symasoft (Opcional)
            </h3>
            <p class="text-sm text-yellow-700 dark:text-yellow-300 mb-4">
              Si seleccionas una cotización, los detalles se llenarán automáticamente
            </p>
            
            <div class="space-y-3">
              <select name="quotation_select" phx-change="select_quotation" phx-target={@myself}
                      class="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white">
                <option value="">-- Seleccionar cotización (opcional) --</option>
                <%= for quotation <- @quotations do %>
                  <option value={quotation.id}>
                    <%= quotation.quotation_number %> - <%= quotation.client_name %> 
                    (<%= Quotation.status_label(quotation.status) %>)
                  </option>
                <% end %>
              </select>

              <%= if @show_quotation_details and @selected_quotation do %>
                <div class="bg-white dark:bg-gray-700 rounded-lg p-4 border border-yellow-200 dark:border-yellow-800">
                  <div class="flex items-center justify-between mb-3">
                    <h4 class="font-semibold text-gray-900 dark:text-white">Detalles de la Cotización</h4>
                    <button type="button" phx-click="clear_quotation" phx-target={@myself}
                            class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300 text-sm">
                      Limpiar
                    </button>
                  </div>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="font-medium text-gray-700 dark:text-gray-300">Número:</span>
                      <span class="text-gray-900 dark:text-white"><%= @selected_quotation.quotation_number %></span>
                    </div>
                    <div>
                      <span class="font-medium text-gray-700 dark:text-gray-300">Cliente:</span>
                      <span class="text-gray-900 dark:text-white"><%= @selected_quotation.client_name %></span>
                    </div>
                    <div>
                      <span class="font-medium text-gray-700 dark:text-gray-300">Cantidad:</span>
                      <span class="text-gray-900 dark:text-white"><%= @selected_quotation.quantity %></span>
                    </div>
                    <div>
                      <span class="font-medium text-gray-700 dark:text-gray-300">Estado:</span>
                      <span class="text-gray-900 dark:text-white"><%= Quotation.status_label(@selected_quotation.status) %></span>
                    </div>
                  </div>
                  <%= if @selected_quotation.special_requirements do %>
                    <div class="mt-3">
                      <span class="font-medium text-gray-700 dark:text-gray-300">Requerimientos:</span>
                      <p class="text-gray-900 dark:text-white text-sm mt-1"><%= @selected_quotation.special_requirements %></p>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Detalles de la Orden -->
          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
            <h3 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">Detalles de la Orden</h3>
            
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Título de la Orden *
                </label>
                <input type="text" name="maintenance_ticket[title]" 
                       value={@changeset.data.title || ""}
                       placeholder="Ej: Orden de producción - Caja seca para transporte"
                       class="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                       required>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Descripción Detallada
                </label>
                <textarea name="maintenance_ticket[description]" rows="4"
                          placeholder="Especificaciones técnicas, materiales, medidas, etc."
                          class="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"><%= @changeset.data.description || "" %></textarea>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Prioridad
                  </label>
                  <select name="maintenance_ticket[priority]" 
                          class="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white">
                    <option value="medium">Media</option>
                    <option value="high">Alta</option>
                    <option value="urgent">Urgente</option>
                    <option value="low">Baja</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fecha de Entrega Estimada
                  </label>
                  <input type="date" name="maintenance_ticket[estimated_delivery]"
                         class="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white">
                </div>
              </div>
            </div>
          </div>

          <!-- Información del Entregador (si viene del wizard) -->
          <%= if @truck_id do %>
            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
              <h3 class="text-lg font-semibold mb-3 text-green-900 dark:text-green-100">Información del Entregador</h3>
              <p class="text-sm text-green-700 dark:text-green-300 mb-4">
                Esta información se capturará durante el check-in del camión
              </p>
            </div>
          <% end %>

          <!-- Botones -->
          <div class="flex justify-end gap-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button type="button" phx-click="close" phx-target={@myself}
                    class="px-6 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
              Cancelar
            </button>
            <button type="submit"
                    class="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium">
              Crear Orden de Producción
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  # Helper functions
  defp map_box_type(box_type) do
    case box_type do
      "plataforma" -> "flatbed"
      "caja_seca" -> "dry_box"
      "caja_refrigerada" -> "refrigerated"
      "caja_termica" -> "refrigerated"
      "caja_especializada" -> "custom"
      "otro" -> "custom"
      _ -> "dry_box"
    end
  end

  defp parse_date(date_string) when is_binary(date_string) and date_string != "" do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end
  defp parse_date(_), do: nil
end 