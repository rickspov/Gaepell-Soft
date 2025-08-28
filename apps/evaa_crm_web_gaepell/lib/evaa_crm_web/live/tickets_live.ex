defmodule EvaaCrmWebGaepell.TicketsLive do
  use EvaaCrmWebGaepell, :live_view

  alias EvaaCrmGaepell.{Repo, MaintenanceTicket, ProductionOrder, Evaluation, Truck}
  import Ecto.Query

    @impl true
  def mount(%{"tab" => "evaluation"} = _params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil

    {:ok,
      socket
        |> assign(:current_user, current_user)
        |> assign(:page_title, "EVA - Tickets")
        |> assign(:active_tab, :evaluation)
        |> assign(:search, "")
        |> assign(:maintenance_tickets, [])
        |> assign(:production_orders, [])
        |> assign(:evaluations, [])
        |> assign(:completed_maintenance_tickets, [])
        |> assign(:completed_production_orders, [])
        |> assign(:show_delete_modal, false)
        |> assign(:ticket_to_delete, nil)
        |> assign(:show_status_modal, false)
        |> assign(:selected_order_id, nil)
        |> load_maintenance_tickets()
        |> load_production_orders()
        |> load_evaluations()
        |> load_completed_tickets()
    }
  end

  @impl true
  def mount(%{"tab" => "completed"} = _params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil

    {:ok,
      socket
        |> assign(:current_user, current_user)
        |> assign(:page_title, "EVA - Tickets")
        |> assign(:active_tab, :completed)
        |> assign(:search, "")
        |> assign(:maintenance_tickets, [])
        |> assign(:production_orders, [])
        |> assign(:evaluations, [])
        |> assign(:completed_maintenance_tickets, [])
        |> assign(:completed_production_orders, [])
        |> assign(:show_delete_modal, false)
        |> assign(:ticket_to_delete, nil)
        |> assign(:show_status_modal, false)
        |> assign(:selected_order_id, nil)
        |> load_maintenance_tickets()
        |> load_production_orders()
        |> load_evaluations()
        |> load_completed_tickets()
    }
  end

  @impl true
  def mount(%{"tab" => "production"} = _params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil

    {:ok,
      socket
        |> assign(:current_user, current_user)
        |> assign(:page_title, "EVA - Tickets")
        |> assign(:active_tab, :production)
        |> assign(:search, "")
        |> assign(:maintenance_tickets, [])
        |> assign(:production_orders, [])
        |> assign(:evaluations, [])
        |> assign(:completed_maintenance_tickets, [])
        |> assign(:completed_production_orders, [])
        |> assign(:show_delete_modal, false)
        |> assign(:ticket_to_delete, nil)
        |> assign(:show_status_modal, false)
        |> assign(:selected_order_id, nil)
        |> load_maintenance_tickets()
        |> load_production_orders()
        |> load_evaluations()
        |> load_completed_tickets()
    }
  end

    @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil

    {:ok,
      socket
        |> assign(:current_user, current_user)
        |> assign(:page_title, "EVA - Tickets")
        |> assign(:active_tab, :maintenance)
        |> assign(:search, "")
        |> assign(:maintenance_tickets, [])
        |> assign(:production_orders, [])
        |> assign(:evaluations, [])
        |> assign(:completed_maintenance_tickets, [])
        |> assign(:completed_production_orders, [])
        |> assign(:show_delete_modal, false)
        |> assign(:ticket_to_delete, nil)
        |> assign(:show_status_modal, false)
        |> assign(:selected_order_id, nil)
        |> load_maintenance_tickets()
        |> load_production_orders()
        |> load_evaluations()
        |> load_completed_tickets()
    }
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab_atom = case tab do
      "production" -> :production
      "evaluation" -> :evaluation
      "completed" -> :completed
      _ -> :maintenance
    end
    {:noreply, assign(socket, :active_tab, tab_atom)}
  end

    @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
      socket
        |> assign(:search, search)
        |> load_maintenance_tickets()
        |> load_production_orders()
        |> load_evaluations()
        |> load_completed_tickets()}
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => ticket_id}, socket) do
    ticket = Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload(:truck)
    {:noreply, 
     socket
     |> assign(:show_delete_modal, true)
     |> assign(:ticket_to_delete, ticket)}
  end

  @impl true
  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:ticket_to_delete, nil)}
  end

  @impl true
  def handle_event("delete_maintenance_ticket", %{"id" => ticket_id}, socket) do
    case Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload(:truck) do
      nil ->
        {:noreply, put_flash(socket, :error, "Ticket no encontrado")}
      ticket ->
        case Repo.delete(ticket) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> assign(:show_delete_modal, false)
             |> assign(:ticket_to_delete, nil)
             |> put_flash(:info, "Ticket eliminado exitosamente")
             |> load_maintenance_tickets()}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Error al eliminar el ticket")}
        end
    end
  end

  defp load_maintenance_tickets(socket) do
    search = socket.assigns.search

    base = from t in MaintenanceTicket,
      preload: [:truck],
      where: t.status in ["check_in", "in_workshop", "new_ticket", "reception", "diagnosis", "repair", "final_check", "cancelled"],
      order_by: [desc: t.inserted_at]

    query = case search do
      "" -> base
      s ->
        like = "%#{s}%"
        from t in base,
          join: truck in assoc(t, :truck),
          where: ilike(truck.brand, ^like) or ilike(truck.model, ^like) or ilike(truck.license_plate, ^like)
    end

    tickets = Repo.all(query)
    assign(socket, :maintenance_tickets, tickets)
  end

  defp load_production_orders(socket) do
    search = socket.assigns.search

    base = from o in ProductionOrder,
      where: o.status != "completed",
      order_by: [desc: o.inserted_at]

    query = case search do
      "" -> base
      s ->
        like = "%#{s}%"
        from o in base,
          where: ilike(o.client_name, ^like) or ilike(o.truck_brand, ^like) or ilike(o.truck_model, ^like) or ilike(o.license_plate, ^like)
    end

    orders = Repo.all(query)
    assign(socket, :production_orders, orders)
  end

  defp load_evaluations(socket) do
    search = socket.assigns.search

    base = from e in Evaluation,
      preload: [:truck, :specialist],
      where: e.converted_to_maintenance == false,
      order_by: [desc: e.inserted_at]

    query = case search do
      "" -> base
      s ->
        like = "%#{s}%"
        from e in base,
          preload: [:truck, :specialist],
          join: truck in assoc(e, :truck),
          where: ilike(truck.brand, ^like) or 
                 ilike(truck.model, ^like) or 
                 ilike(truck.license_plate, ^like) or
                 ilike(e.title, ^like) or
                 ilike(e.evaluation_type, ^like)
    end

    evaluations = Repo.all(query)
    assign(socket, :evaluations, evaluations)
  end

  defp load_completed_tickets(socket) do
    search = socket.assigns.search

    # Load completed maintenance tickets
    maintenance_base = from t in MaintenanceTicket,
      preload: [:truck],
      where: t.status in ["check_out", "car_wash", "final_review", "completed"],
      order_by: [desc: t.inserted_at]

    maintenance_query = case search do
      "" -> maintenance_base
      s ->
        like = "%#{s}%"
        from t in maintenance_base,
          join: truck in assoc(t, :truck),
          where: ilike(truck.brand, ^like) or ilike(truck.model, ^like) or ilike(truck.license_plate, ^like)
    end

    completed_maintenance = Repo.all(maintenance_query)
    IO.inspect(completed_maintenance, label: "[DEBUG] Completed maintenance tickets")

    # Load completed production orders
    production_base = from o in ProductionOrder,
      where: o.status == "completed",
      order_by: [desc: o.inserted_at]

    production_query = case search do
      "" -> production_base
      s ->
        like = "%#{s}%"
        from o in production_base,
          where: ilike(o.client_name, ^like) or ilike(o.truck_brand, ^like) or ilike(o.truck_model, ^like) or ilike(o.license_plate, ^like)
    end

    completed_production = Repo.all(production_query)
    IO.inspect(completed_production, label: "[DEBUG] Completed production orders")

    # Format completed maintenance tickets
    completed_maintenance_formatted = Enum.map(completed_maintenance, fn ticket -> 
      %{
        id: ticket.id,
        type: "maintenance",
        title: "Mantenimiento - #{ticket.truck.brand} #{ticket.truck.model}",
        license_plate: ticket.truck.license_plate,
        client_name: ticket.truck.owner || "N/A",
        status: ticket.status,
        status_label: get_completion_status_label(ticket.status),
        inserted_at: ticket.inserted_at,
        completed_at: ticket.updated_at,
        truck: ticket.truck
      }
    end)

    # Format completed production orders
    completed_production_formatted = Enum.map(completed_production, fn order -> 
      %{
        id: order.id,
        type: "production",
        title: "Producción - #{order.client_name}",
        license_plate: order.license_plate,
        client_name: order.client_name,
        status: order.status,
        status_label: get_completion_status_label(order.status),
        inserted_at: order.inserted_at,
        completed_at: order.updated_at,
        truck: nil
      }
    end)

    # Sort by completion date (most recent first)
    sorted_maintenance = Enum.sort_by(completed_maintenance_formatted, & &1.completed_at, {:desc, Date})
    sorted_production = Enum.sort_by(completed_production_formatted, & &1.completed_at, {:desc, Date})

    assign(socket, :completed_maintenance_tickets, sorted_maintenance)
    |> assign(:completed_production_orders, sorted_production)
  end

  # Helper functions for template
  defp tab_class(active_tab, tab) do
    if active_tab == tab do
      "px-4 py-2 text-sm font-medium bg-blue-600 text-white"
    else
      "px-4 py-2 text-sm font-medium bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300"
    end
  end

  defp production_tab_class(active_tab) do
    base_class = tab_class(active_tab, :production)
    if active_tab != :production do
      base_class <> " border-l border-gray-200 dark:border-gray-700"
    else
      base_class
    end
  end



  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto p-6">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Tickets</h1>
            <p class="mt-1 text-gray-600 dark:text-gray-400">Mantenimiento, Evaluaciones y Producción</p>
          </div>
          <div class="w-72">
            <form phx-change="search">
              <input name="search" value={@search} placeholder="Buscar por camión, cliente o placa" class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </form>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="mb-6">
        <div class="inline-flex rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
          <button phx-click="set_tab" phx-value-tab="maintenance" class={tab_class(@active_tab, :maintenance)}>Mantenimiento</button>
          <button phx-click="set_tab" phx-value-tab="evaluation" class={tab_class(@active_tab, :evaluation)}>Evaluaciones</button>
          <button phx-click="set_tab" phx-value-tab="production" class={tab_class(@active_tab, :production)}>Producción</button>
          <button phx-click="set_tab" phx-value-tab="completed" class={tab_class(@active_tab, :completed)}>Completados</button>
        </div>
      </div>

      <%= if @active_tab == :maintenance do %>
        <!-- Mensaje informativo para el tab de Mantenimiento -->
        <div class="bg-white dark:bg-gray-800 shadow rounded-lg p-8 text-center">
          <svg class="mx-auto h-16 w-16 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
          <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">Tickets de Mantenimiento</h3>
          <p class="text-gray-500 dark:text-gray-400 mb-4">
            Los tickets de mantenimiento activos se muestran en el tab "Completados" cuando están en progreso.
          </p>
          <p class="text-sm text-gray-400 dark:text-gray-500">
            Para ver los tickets completados, ve al tab "Completados".
          </p>
        </div>
      <% else %>
        <%= if @active_tab == :evaluation do %>
          <!-- Tabla de Evaluaciones -->
        <div class="bg-white dark:bg-gray-800 shadow rounded-lg overflow-hidden">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">ID</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Título</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Camión</th>
                                     <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Tipo</th>
                   <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Propietario</th>
                   <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Fecha</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for evaluation <- @evaluations do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">#<%= evaluation.id %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= evaluation.title %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <div>
                        <div class="font-medium"><%= evaluation.truck && (evaluation.truck.brand <> " " <> evaluation.truck.model) %></div>
                        <div class="text-gray-500 dark:text-gray-400"><%= evaluation.truck && evaluation.truck.license_plate %></div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <span class={evaluation_type_color(evaluation.evaluation_type) <> " inline-flex px-2 py-1 text-xs font-semibold rounded-full"}>
                        <%= get_evaluation_type_label(evaluation.evaluation_type) %>
                      </span>
                    </td>
                                         <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                       <%= evaluation.truck && evaluation.truck.owner %>
                     </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= Calendar.strftime(evaluation.inserted_at, "%d/%m/%Y") %>
                    </td>
                                         <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                       <div class="flex space-x-2">
                         <a href={"/tickets/#{evaluation.id}"} class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300" title="Ver detalles">
                           <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                             <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                             <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                           </svg>
                         </a>
                         <a href={"/trucks/#{evaluation.truck_id}"} class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300" title="Ver perfil del camión">
                           <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                             <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
                           </svg>
                         </a>
                         <button phx-click="convert_evaluation_to_maintenance" phx-value-evaluation_id={evaluation.id}
                                 class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300"
                                 title="Convertir a mantenimiento">
                           <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                             <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                           </svg>
                         </button>
                         <button phx-click="delete_evaluation" phx-value-evaluation_id={evaluation.id}
                                 class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                                 title="Eliminar evaluación"
                                 onclick="return confirm('¿Estás seguro de que quieres eliminar esta evaluación?')">
                           <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                             <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                           </svg>
                         </button>
                       </div>
                     </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          
          <%= if Enum.empty?(@evaluations) do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay evaluaciones</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                No se encontraron evaluaciones para mostrar.
              </p>
            </div>
          <% end %>
        </div>
        <% else %>
          <%= if @active_tab == :production do %>
            <!-- Tabla de Órdenes de Producción -->
          <div class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-md">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Orden #
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Cliente
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Camión
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Tipo de Caja
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Estado
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Progreso
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Fecha Creación
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Entrega Estimada
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Acciones
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for order <- @production_orders do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                      #<%= order.id %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= order.client_name %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <div>
                        <div class="font-medium"><%= order.truck_brand %> <%= order.truck_model %></div>
                        <div class="text-gray-500 dark:text-gray-400"><%= order.license_plate %></div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= EvaaCrmGaepell.ProductionOrder.box_type_label(order.box_type) %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={production_status_color(order.status) <> " inline-flex px-2 py-1 text-xs font-semibold rounded-full"}>
                        <%= production_status_text(order.status) %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      <div class="flex items-center gap-2">
                        <div class="w-16 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                          <div class="bg-gradient-to-r from-blue-600 to-purple-600 h-2 rounded-full transition-all duration-300" 
                               style={"width: #{get_production_progress(order.status)}%"}>
                          </div>
                        </div>
                        <span class="text-xs font-medium"><%= get_production_progress(order.status) %>%</span>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= Calendar.strftime(order.inserted_at, "%d/%m/%Y") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= if order.estimated_delivery do %>
                        <%= Calendar.strftime(order.estimated_delivery, "%d/%m/%Y") %>
                      <% else %>
                        No especificada
                      <% end %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div class="flex space-x-2">
                        <button phx-click="view_production_order" phx-value-order_id={order.id}
                                class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                                title="Ver detalles">
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                          </svg>
                        </button>
                        <button phx-click="edit_production_order" phx-value-order_id={order.id}
                                class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300"
                                title="Editar orden">
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                          </svg>
                        </button>
                        <button phx-click="delete_production_order" phx-value-order_id={order.id}
                                class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                                title="Eliminar orden"
                                onclick="return confirm('¿Estás seguro de que quieres eliminar esta orden de producción?')">
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                          </svg>
                        </button>
                        <button phx-click="show_status_modal" phx-value-order_id={order.id}
                                class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300"
                                title="Cambiar estado">
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                          </svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          
          <%= if Enum.empty?(@production_orders) do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay órdenes de producción</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Comienza creando tu primera orden de producción.
              </p>
            </div>
          <% end %>
        </div>
          <% end %>
        <% end %>
      <% end %>

      <%= if @active_tab == :completed do %>
        <!-- Tabla de Tickets de Mantenimiento Completados -->
        <div class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-md mb-6">
          <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Tickets de Mantenimiento Completados</h3>
          </div>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">ID</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Título</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Propietario</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Placa</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Fecha Creación</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado Completado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Fecha Completado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for ticket <- @completed_maintenance_tickets do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">#<%= ticket.id %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"><%= ticket.title %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"><%= ticket.client_name %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"><%= ticket.license_plate %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      <%= Calendar.strftime(ticket.inserted_at, "%d/%m/%Y %H:%M") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 inline-flex px-2 py-1 text-xs font-semibold rounded-full">
                        <%= ticket.status_label %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      <%= Calendar.strftime(ticket.completed_at, "%d/%m/%Y %H:%M") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button phx-click="view_maintenance_ticket" phx-value-id={ticket.id}
                              class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                              title="Ver detalles">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          
          <%= if length(@completed_maintenance_tickets) == 0 do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay tickets de mantenimiento completados</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Los tickets de mantenimiento completados aparecerán aquí automáticamente.
              </p>
            </div>
          <% end %>
        </div>

        <!-- Tabla de Órdenes de Producción Completadas -->
        <div class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-md">
          <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Órdenes de Producción Completadas</h3>
          </div>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">ID</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Título</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Cliente</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Placa</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Fecha Creación</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado Completado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Fecha Completado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for order <- @completed_production_orders do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">#<%= order.id %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"><%= order.title %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"><%= order.client_name %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"><%= order.license_plate %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      <%= Calendar.strftime(order.inserted_at, "%d/%m/%Y %H:%M") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 inline-flex px-2 py-1 text-xs font-semibold rounded-full">
                        <%= order.status_label %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      <%= Calendar.strftime(order.completed_at, "%d/%m/%Y %H:%M") %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button phx-click="view_production_order" phx-value-order_id={order.id}
                              class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                              title="Ver detalles">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                        </svg>
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          
          <%= if length(@completed_production_orders) == 0 do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay órdenes de producción completadas</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Las órdenes de producción completadas aparecerán aquí automáticamente.
              </p>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Modal de Confirmación de Eliminación -->
       <%= if @show_delete_modal and @ticket_to_delete do %>
         <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
           <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-md w-full mx-4">
             <div class="p-6">
               <div class="flex items-center gap-3 mb-4">
                 <div class="flex-shrink-0">
                   <div class="w-10 h-10 bg-red-100 dark:bg-red-900 rounded-full flex items-center justify-center">
                     <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"/>
                     </svg>
                   </div>
                 </div>
                 <div>
                   <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Confirmar Eliminación</h3>
                   <p class="text-sm text-gray-600 dark:text-gray-400">Esta acción no se puede deshacer</p>
                 </div>
               </div>
               
                               <div class="mb-6">
                  <p class="text-gray-700 dark:text-gray-300">
                    ¿Estás seguro de que quieres eliminar el ticket 
                    <span class="font-semibold">#<%= @ticket_to_delete.id %></span> 
                    <%= if @ticket_to_delete.truck do %>
                      del camión <span class="font-semibold"><%= @ticket_to_delete.truck.brand <> " " <> @ticket_to_delete.truck.model %></span>?
                    <% else %>
                      (camión no especificado)?
                    <% end %>
                  </p>
                </div>
               
               <div class="flex gap-3">
                 <button phx-click="hide_delete_modal" 
                         class="flex-1 px-4 py-2 text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors">
                   Cancelar
                 </button>
                 <button phx-click="delete_maintenance_ticket" phx-value-id={@ticket_to_delete.id}
                         class="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-colors">
                   Eliminar
                 </button>
               </div>
             </div>
           </div>
         </div>
       <% end %>
     </div>

     <!-- Status Change Modal for Production Orders -->
     <%= if @show_status_modal and @selected_order_id do %>
       <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
         <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white dark:bg-gray-800">
           <div class="mt-3">
             <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
               Cambiar Estado de la Orden
             </h3>
             <div class="space-y-2">
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="new_order"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-gray-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Nueva Orden</span>
                 </div>
               </button>
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="reception"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-blue-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Recepción</span>
                 </div>
               </button>
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="assembly"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-yellow-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Ensamblaje</span>
                 </div>
               </button>
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="mounting"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-purple-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Montaje</span>
                 </div>
               </button>
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="final_check"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-orange-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Final Check</span>
                 </div>
               </button>
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="completed"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-green-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Completada</span>
                 </div>
               </button>
               <button phx-click="change_order_status" phx-value-order_id={@selected_order_id} phx-value-status="cancelled"
                       class="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                 <div class="flex items-center">
                   <span class="inline-block w-3 h-3 bg-red-500 rounded-full mr-3"></span>
                   <span class="text-gray-900 dark:text-white">Cancelada</span>
                 </div>
               </button>
             </div>
             <div class="flex justify-end mt-6">
               <button phx-click="hide_status_modal" 
                       class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                 Cancelar
               </button>
             </div>
           </div>
         </div>
       </div>
     <% end %>
     """
  end

  defp status_color(status) do
    case status do
      "check_in" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "in_workshop" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "final_review" -> "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
      "car_wash" -> "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
      "check_out" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

  # Helper functions for production orders
  defp production_status_color("new_order"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  defp production_status_color("reception"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp production_status_color("assembly"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp production_status_color("mounting"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  defp production_status_color("final_check"), do: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
  defp production_status_color("completed"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp production_status_color("cancelled"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp production_status_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp production_status_text("new_order"), do: "Nueva Orden"
  defp production_status_text("reception"), do: "Recepción"
  defp production_status_text("assembly"), do: "Ensamblaje"
  defp production_status_text("mounting"), do: "Montaje"
  defp production_status_text("final_check"), do: "Final Check"
  defp production_status_text("completed"), do: "Completada"
  defp production_status_text("cancelled"), do: "Cancelada"
  defp production_status_text(_), do: "Desconocido"

  defp get_production_progress(status) do
    case status do
      "new_order" -> 0
      "reception" -> 20
      "assembly" -> 40
      "mounting" -> 60
      "final_check" -> 80
      "completed" -> 100
      "cancelled" -> 0
      _ -> 0
    end
  end

  defp get_completion_status_label(status) do
    case status do
      "check_out" -> "Completado"
      "car_wash" -> "Lavado Completado"
      "final_review" -> "Revisión Final"
      "completed" -> "Completado"
      _ -> "Completado"
    end
  end

  # Production order action handlers
  @impl true
  def handle_event("view_maintenance_ticket", %{"id" => ticket_id}, socket) do
    {:noreply, push_navigate(socket, to: "/tickets/#{ticket_id}")}
  end

  @impl true
  def handle_event("view_production_order", %{"order_id" => order_id}, socket) do
    {:noreply, push_navigate(socket, to: "/production-orders/#{order_id}")}
  end

  @impl true
  def handle_event("edit_production_order", %{"order_id" => order_id}, socket) do
    # Por ahora solo redirigimos a una página de edición (puedes implementar esto después)
    {:noreply, put_flash(socket, :info, "Funcionalidad de edición próximamente")}
  end

  @impl true
  def handle_event("delete_production_order", %{"order_id" => order_id}, socket) do
    order_id = String.to_integer(order_id)
    order = Repo.get(ProductionOrder, order_id)
    
    if order do
      case Repo.delete(order) do
        {:ok, _deleted_order} ->
          {:noreply, 
           socket
           |> load_production_orders()
           |> put_flash(:success, "Orden de producción eliminada exitosamente")}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al eliminar la orden de producción")}
      end
    else
      {:noreply, put_flash(socket, :error, "Orden de producción no encontrada")}
    end
  end

  @impl true
  def handle_event("show_status_modal", %{"order_id" => order_id}, socket) do
    order_id = String.to_integer(order_id)
    {:noreply, 
     socket
     |> assign(:show_status_modal, true)
     |> assign(:selected_order_id, order_id)}
  end

  @impl true
  def handle_event("hide_status_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_status_modal, false)
     |> assign(:selected_order_id, nil)}
  end

     @impl true
   def handle_event("change_order_status", %{"order_id" => order_id, "status" => status}, socket) do
     order_id = String.to_integer(order_id)
     order = Repo.get(ProductionOrder, order_id)
     
     if order do
       case Repo.update(Ecto.Changeset.change(order, %{status: status})) do
         {:ok, _updated_order} ->
           {:noreply, 
            socket
            |> load_production_orders()
            |> assign(:show_status_modal, false)
            |> assign(:selected_order_id, nil)
            |> put_flash(:success, "Estado de la orden actualizado exitosamente")}
         
         {:error, _changeset} ->
           {:noreply, put_flash(socket, :error, "Error al actualizar el estado de la orden")}
       end
     else
       {:noreply, put_flash(socket, :error, "Orden de producción no encontrada")}
     end
   end

   # Evaluation action handlers
   @impl true
   def handle_event("convert_evaluation_to_maintenance", %{"evaluation_id" => evaluation_id}, socket) do
     evaluation_id = String.to_integer(evaluation_id)
     evaluation = Repo.get(Evaluation, evaluation_id) |> Repo.preload([:truck, :business])
     
     if evaluation do
       case EvaaCrmGaepell.Evaluation.convert_to_maintenance_ticket(evaluation, socket.assigns.current_user.id) do
         {:ok, _maintenance_ticket} ->
           {:noreply, 
            socket
            |> load_evaluations()
            |> put_flash(:success, "Evaluación convertida a ticket de mantenimiento exitosamente")}
         
         {:error, _changeset} ->
           {:noreply, put_flash(socket, :error, "Error al convertir la evaluación a ticket de mantenimiento")}
       end
     else
       {:noreply, put_flash(socket, :error, "Evaluación no encontrada")}
     end
   end

   @impl true
   def handle_event("delete_evaluation", %{"evaluation_id" => evaluation_id}, socket) do
     evaluation_id = String.to_integer(evaluation_id)
     evaluation = Repo.get(Evaluation, evaluation_id)
     
     if evaluation do
       case Repo.delete(evaluation) do
         {:ok, _deleted_evaluation} ->
           {:noreply, 
            socket
            |> load_evaluations()
            |> put_flash(:success, "Evaluación eliminada exitosamente")}
         
         {:error, _changeset} ->
           {:noreply, put_flash(socket, :error, "Error al eliminar la evaluación")}
       end
     else
       {:noreply, put_flash(socket, :error, "Evaluación no encontrada")}
     end
   end

  # Helper functions for evaluation types
  defp get_evaluation_type_label(type) do
    case type do
      "garantia" -> "Garantía"
      "colision" -> "Colisión"
      "desgaste" -> "Desgaste"
      "otro" -> "Otro"
      _ -> "Desconocido"
    end
  end

  defp evaluation_type_color(type) do
    case type do
      "garantia" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "colision" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      "desgaste" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "otro" -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

end
