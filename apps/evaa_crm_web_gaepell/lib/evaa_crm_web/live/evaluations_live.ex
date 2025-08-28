defmodule EvaaCrmWebGaepell.EvaluationsLive do
  use EvaaCrmWebGaepell, :live_view

  alias EvaaCrmGaepell.{Repo, Evaluation, Truck, Specialist}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil

    {:ok,
      socket
      |> assign(:current_user, current_user)
      |> assign(:page_title, "EVA - Evaluaciones - TEST")
      |> assign(:search, "")
      |> assign(:evaluations, [])
      |> assign(:selected_evaluation, nil)
      |> assign(:show_convert_modal, false)
      |> assign(:show_delete_confirm, false)
      |> assign(:delete_target, nil)
      |> load_evaluations()
    }
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
      socket
      |> assign(:search, search)
      |> load_evaluations()}
  end

  @impl true
  def handle_event("view_evaluation", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/tickets/#{id}")}
  end

  @impl true
  def handle_event("close_evaluation_modal", _params, socket) do
    {:noreply, assign(socket, :selected_evaluation, nil)}
  end

  @impl true
  def handle_event("show_convert_modal", %{"id" => id}, socket) do
    evaluation = Repo.get(Evaluation, id) |> Repo.preload(:truck)
    {:noreply, 
      socket
      |> assign(:selected_evaluation, evaluation)
      |> assign(:show_convert_modal, true)}
  end

  @impl true
  def handle_event("close_convert_modal", _params, socket) do
    {:noreply, assign(socket, :show_convert_modal, false)}
  end

  @impl true
  def handle_event("convert_to_maintenance", _params, socket) do
    evaluation = socket.assigns.selected_evaluation
    
    # Convertir la evaluación a ticket de mantenimiento usando los datos por defecto
    case Evaluation.convert_to_maintenance_ticket(evaluation, socket.assigns.current_user.id) do
      {:ok, _maintenance_ticket} ->
        {:noreply,
          socket
          |> assign(:show_convert_modal, false)
          |> assign(:selected_evaluation, nil)
          |> put_flash(:info, "Evaluación convertida a ticket de mantenimiento exitosamente")
          |> load_evaluations()}
      
      {:error, changeset} ->
        {:noreply,
          socket
          |> put_flash(:error, "Error al convertir la evaluación: #{inspect(changeset.errors)}")}
    end
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
    stats = Evaluation.get_evaluation_stats(socket.assigns.current_user.business_id)

    socket
    |> assign(:evaluations, evaluations)
    |> assign(:stats, stats)
  end

  # Helper functions for template
  defp evaluation_type_label(evaluation_type) do
    case evaluation_type do
      "colision" -> "Colisión"
      "garantia" -> "Garantía"
      "desgaste" -> "Desgaste"
      "otro" -> "Otro"
      _ -> "Evaluación"
    end
  end

  defp evaluation_type_color(evaluation_type) do
    case evaluation_type do
      "colision" -> "bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-400"
      "garantia" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-400"
      "desgaste" -> "bg-orange-100 text-orange-800 dark:bg-orange-900/50 dark:text-orange-400"
      "otro" -> "bg-gray-100 text-gray-800 dark:bg-gray-900/50 dark:text-gray-400"
      _ -> "bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-400"
    end
  end

  defp status_label(status) do
    case status do
      "pending" -> "Pendiente"
      "in_progress" -> "En Progreso"
      "completed" -> "Completada"
      "cancelled" -> "Cancelada"
      "converted" -> "Convertida"
      _ -> "Pendiente"
    end
  end

  defp status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-400"
      "in_progress" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-400"
      "completed" -> "bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-400"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-400"
      "converted" -> "bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-400"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/50 dark:text-gray-400"
    end
  end

  defp format_date(date) do
    if date do
      Calendar.strftime(date, "%d/%m/%Y %H:%M")
    else
      "N/A"
    end
  end

  defp format_currency(amount) do
    if amount do
      :erlang.float_to_binary(Decimal.to_float(amount), [decimals: 2])
      |> Kernel.<>(" $")
    else
      "N/A"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-2xl font-bold text-slate-900 dark:text-slate-100">Evaluaciones</h1>
          <p class="text-slate-600 dark:text-slate-400">Gestión de tickets de evaluación de daños</p>
        </div>
        <div class="flex gap-3">
          <form phx-change="search" class="flex-1 max-w-md">
            <div class="relative">
              <input
                type="text"
                name="search"
                value={@search}
                placeholder="Buscar por placa, modelo, tipo..."
                class="w-full pl-10 pr-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <svg class="absolute left-3 top-2.5 h-5 w-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
              </svg>
            </div>
          </form>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 p-6">
          <div class="flex items-center">
            <div class="p-2 bg-blue-100 dark:bg-blue-900/50 rounded-lg">
              <svg class="h-6 w-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600 dark:text-slate-400">Total Evaluaciones</p>
                             <p class="text-2xl font-bold text-slate-900 dark:text-slate-100"><%= length(@evaluations) %></p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 p-6">
          <div class="flex items-center">
            <div class="p-2 bg-red-100 dark:bg-red-900/50 rounded-lg">
              <svg class="h-6 w-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600 dark:text-slate-400">Colisiones</p>
                             <p class="text-2xl font-bold text-slate-900 dark:text-slate-100">
                 <%= Enum.count(@evaluations, & &1.evaluation_type == "colision") %>
               </p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 p-6">
          <div class="flex items-center">
            <div class="p-2 bg-blue-100 dark:bg-blue-900/50 rounded-lg">
              <svg class="h-6 w-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600 dark:text-slate-400">Garantías</p>
                             <p class="text-2xl font-bold text-slate-900 dark:text-slate-100">
                 <%= Enum.count(@evaluations, & &1.evaluation_type == "garantia") %>
               </p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 p-6">
          <div class="flex items-center">
            <div class="p-2 bg-green-100 dark:bg-green-900/50 rounded-lg">
              <svg class="h-6 w-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600 dark:text-slate-400">Convertidos</p>
                             <p class="text-2xl font-bold text-slate-900 dark:text-slate-100">
                 <%= @stats.converted %>
               </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Evaluations Table -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tickets de Evaluación</h3>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-slate-50 dark:bg-slate-700/50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Camión</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Tipo</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Estado</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Fecha</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Costo Estimado</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-slate-800 divide-y divide-slate-200 dark:divide-slate-700">
                             <%= for evaluation <- @evaluations do %>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-700/50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="flex-shrink-0 h-10 w-10">
                        <div class="h-10 w-10 rounded-full bg-slate-200 dark:bg-slate-600 flex items-center justify-center">
                          <svg class="h-6 w-6 text-slate-600 dark:text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                          </svg>
                        </div>
                      </div>
                      <div class="ml-4">
                                                 <div class="text-sm font-medium text-slate-900 dark:text-slate-100">
                           <%= if evaluation.truck, do: "#{evaluation.truck.brand} #{evaluation.truck.model}", else: "N/A" %>
                         </div>
                         <div class="text-sm text-slate-500 dark:text-slate-400">
                           <%= if evaluation.truck, do: evaluation.truck.license_plate, else: "Sin placa" %>
                         </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                                         <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{evaluation_type_color(evaluation.evaluation_type)}"}>
                       <%= evaluation_type_label(evaluation.evaluation_type) %>
                     </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                                         <span class={"inline-flex px-2 py-1 text-xs font-semibold rounded-full #{status_color(evaluation.status)}"}>
                       <%= status_label(evaluation.status) %>
                     </span>
                  </td>
                                     <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">
                     <%= format_date(evaluation.evaluation_date) %>
                   </td>
                   <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">
                     <%= format_currency(evaluation.estimated_cost) %>
                   </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div class="flex space-x-3">
                      <button
                        phx-click="view_evaluation"
                        phx-value-id={evaluation.id}
                        class="p-2 text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Ver detalles"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                        </svg>
                      </button>
                      <%= if evaluation.status != "converted" do %>
                        <button
                          phx-click="show_convert_modal"
                          phx-value-id={evaluation.id}
                          class="p-2 text-green-600 dark:text-green-400 hover:text-green-900 dark:hover:text-green-300 hover:bg-green-50 dark:hover:bg-green-900/20 rounded-lg transition-colors"
                          title="Convertir a mantenimiento"
                        >
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"/>
                          </svg>
                        </button>
                      <% end %>
                      <button
                        phx-click="show_delete_confirm"
                        phx-value-id={evaluation.id}
                        class="p-2 text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Eliminar evaluación"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
      </div>

             <!-- Convert to Maintenance Modal -->
      <%= if @show_convert_modal do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white dark:bg-slate-800 rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Convertir a Mantenimiento</h3>
              <button phx-click="close_convert_modal" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
                <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>
            
            <div class="space-y-4">
              <!-- Información del camión -->
              <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-3">
                <p class="text-sm font-medium text-slate-700 dark:text-slate-300">Camión</p>
                <p class="text-sm text-slate-900 dark:text-slate-100">
                  <%= if @selected_evaluation.truck, do: "#{@selected_evaluation.truck.brand} #{@selected_evaluation.truck.model} (#{@selected_evaluation.truck.license_plate})", else: "N/A" %>
                </p>
              </div>

              <!-- Tipo de evaluación -->
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Tipo de Evaluación</label>
                <select class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100">
                  <option value="maintenance">Mantenimiento</option>
                  <option value="collision">Colisión</option>
                  <option value="warranty">Garantía</option>
                  <option value="other">Otro</option>
                </select>
              </div>

              <!-- Costo estimado de reparación -->
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Costo Estimado de Reparación ($)</label>
                <input type="number" value={@selected_evaluation.estimated_cost} step="0.01" min="0" 
                       class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                       placeholder="0.00">
              </div>

              <!-- Notas de evaluación -->
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Notas de Evaluación</label>
                <textarea rows="3" 
                          class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                          placeholder="Detalles adicionales de la evaluación..."></textarea>
              </div>
            </div>

            <div class="flex justify-end space-x-3 mt-6">
              <button type="button" phx-click="close_convert_modal" 
                      class="px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-md text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                Cancelar
              </button>
              <button phx-click="convert_to_maintenance" 
                      class="px-4 py-2 bg-green-600 border border-transparent rounded-md text-sm font-medium text-white hover:bg-green-700 transition-colors">
                Convertir a Mantenimiento
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Delete Confirmation Modal -->
      <%= if @show_delete_confirm do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999]" phx-click="hide_delete_confirm" phx-window-keydown="hide_delete_confirm" phx-key="escape">
          <div class="bg-white dark:bg-slate-800 rounded-lg shadow-xl max-w-md w-full mx-4 p-6" phx-click="ignore">
            <div class="flex items-center mb-4">
              <div class="flex-shrink-0">
                <svg class="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-lg font-medium text-slate-900 dark:text-white">Confirmar Eliminación</h3>
              </div>
            </div>
            <div class="mt-2">
              <p class="text-sm text-slate-500 dark:text-slate-400">
                ¿Estás seguro de que quieres eliminar la evaluación <strong class="text-slate-900 dark:text-white">"<%= @delete_target.title %>"</strong>?
              </p>
              <p class="text-xs text-red-600 dark:text-red-400 mt-2">
                Esta acción no se puede deshacer.
              </p>
            </div>
            <div class="mt-6 flex justify-end space-x-3">
              <button phx-click="hide_delete_confirm" 
                      class="px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-md text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                Cancelar
              </button>
              <button phx-click="confirm_delete" 
                      class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 transition-colors">
                Eliminar
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions for template
  defp get_status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400"
      "in-progress" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400"
      "completed" -> "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400"
    end
  end

  defp get_status_label(status) do
    case status do
      "pending" -> "Pendiente"
      "in-progress" -> "En Progreso"
      "completed" -> "Completada"
      "cancelled" -> "Cancelada"
      _ -> "Desconocido"
    end
  end

  defp get_severity_color(severity) do
    case severity do
      "critical" -> "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400"
      "high" -> "bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-400"
      "medium" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400"
      "low" -> "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400"
    end
  end

  defp get_severity_label(severity) do
    case severity do
      "high" -> "Alta"
      "medium" -> "Media"
      "low" -> "Baja"
      "critical" -> "Crítica"
      _ -> "Normal"
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

  @impl true
  def handle_event("view_evaluation", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/tickets/#{id}")}
  end

  @impl true
  def handle_event("edit_evaluation", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/tickets/#{id}")}
  end

  @impl true
  def handle_event("search", %{"value" => search}, socket) do
    {:noreply, 
     socket
     |> assign(:search, search)
     |> load_evaluations()}
  end

  @impl true
  def handle_event("filter_status", %{"value" => status}, socket) do
    {:noreply, 
     socket
     |> assign(:status_filter, status)
     |> load_evaluations()}
  end

  @impl true
  def handle_event("filter_severity", %{"value" => severity}, socket) do
    {:noreply, 
     socket
     |> assign(:severity_filter, severity)
     |> load_evaluations()}
  end

  @impl true
  def handle_event("filter_type", %{"value" => type}, socket) do
    {:noreply, 
     socket
     |> assign(:type_filter, type)
     |> load_evaluations()}
  end

  @impl true
  def handle_event("filter_insurance", %{"value" => insurance}, socket) do
    {:noreply, 
     socket
     |> assign(:insurance_filter, insurance)
     |> load_evaluations()}
  end

  # Delete evaluation events
  @impl true
  def handle_event("show_delete_confirm", %{"id" => id}, socket) do
    evaluation = Repo.get(Evaluation, id)
    if evaluation do
      {:noreply, 
       socket
       |> assign(:show_delete_confirm, true)
       |> assign(:delete_target, evaluation)}
    else
      {:noreply, put_flash(socket, :error, "Evaluación no encontrada")}
    end
  end

  @impl true
  def handle_event("hide_delete_confirm", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    evaluation = socket.assigns.delete_target
    
    case Repo.delete(evaluation) do
      {:ok, _deleted_evaluation} ->
        {:noreply, 
         socket
         |> assign(:show_delete_confirm, false)
         |> assign(:delete_target, nil)
         |> put_flash(:info, "Evaluación eliminada exitosamente")
         |> load_evaluations()}
      
      {:error, _changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al eliminar la evaluación")}
    end
  end
end
