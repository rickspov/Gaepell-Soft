defmodule EvaaCrmWebGaepell.PatientProfileLive do
  use EvaaCrmWebGaepell, :live_view

  alias EvaaCrmGaepell.{Contact, Activity, Repo}
  import Ecto.Query

  @impl true
  def mount(%{"id" => id}, session, socket) do
    current_user =
      case session do
        %{"user_id" => user_id} ->
          EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id)
        _ ->
          nil
      end
    contact = Repo.get(Contact, id)
    
    if contact do
      socket = assign(socket, :contact, contact)
      socket = assign(socket, :show_edit_form, false)
      socket = assign(socket, :editing_contact, contact)
      socket = assign(socket, :current_user, current_user)
      socket = load_contact_stats(socket)
      socket = load_all_contact_activities(socket)
      socket = load_contact_trucks(socket)
      socket = load_contact_specialists(socket)
      
      {:ok, socket}
    else
      {:ok, push_redirect(socket, to: ~p"/crm")}
    end
  end

  @impl true
  def handle_event("show_edit_form", _params, socket) do
    {:noreply, assign(socket, :show_edit_form, true)}
  end

  @impl true
  def handle_event("hide_edit_form", _params, socket) do
    {:noreply, assign(socket, :show_edit_form, false)}
  end

  @impl true
  def handle_event("update_contact", %{"contact" => contact_params}, socket) do
    case update_contact(socket.assigns.contact, contact_params) do
      {:ok, updated_contact} ->
        socket = assign(socket, :contact, updated_contact)
        socket = assign(socket, :show_edit_form, false)
        socket = load_contact_stats(socket)
        
        {:noreply, socket}
      
      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-50 dark:bg-gray-900 min-h-screen">
      <!-- Breadcrumb -->
      <div class="px-4 pt-6">
        <nav class="flex mb-5" aria-label="Breadcrumb">
          <ol class="inline-flex items-center space-x-1 md:space-x-2">
            <li class="inline-flex items-center">
              <a href="/crm" class="inline-flex items-center text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
                <svg class="w-5 h-5 mr-2.5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                  <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L9 4.414V17a1 1 0 102 0V4.414l5.293 5.293a1 1 0 001.414-1.414l-7-7z"></path>
                </svg>
                Clientes
              </a>
            </li>
            <li>
              <div class="flex items-center">
                <svg class="w-6 h-6 text-gray-400" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                  <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
                </svg>
                <span class="ml-1 text-sm font-medium text-gray-500 md:ml-2 dark:text-gray-400">Perfil del Cliente</span>
              </div>
            </li>
          </ol>
        </nav>
      </div>

      <!-- Main Content -->
      <div class="px-4 pb-6">
        <!-- Header -->
        <div class="mb-6">
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Perfil del Cliente</h1>
          <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">Información completa y estadísticas del cliente</p>
        </div>

        <!-- Profile Grid -->
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
          <!-- Left Column - Profile Info -->
          <div class="lg:col-span-1">
            <!-- Profile Card -->
            <div class="p-4 mb-4 bg-white rounded-lg shadow sm:p-6 xl:p-8 dark:bg-gray-800">
              <div class="flex items-center space-x-4">
                <div class="flex-shrink-0">
                  <div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center dark:bg-blue-200">
                    <svg class="w-8 h-8 text-blue-600 dark:text-blue-700" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"></path>
                    </svg>
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-lg font-medium text-gray-900 truncate dark:text-white">
                    <%= EvaaCrmGaepell.Contact.full_name(@contact) %>
                  </p>
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    <%= @contact.email || "Sin email" %>
                  </p>
                </div>
              </div>
              <div class="mt-4">
                <ul class="space-y-2 text-sm text-gray-500 dark:text-gray-400">
                  <li class="flex items-center">
                    <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"></path>
                      <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"></path>
                    </svg>
                    <%= @contact.phone || "Sin teléfono" %>
                  </li>
                  <li class="flex items-center">
                    <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fill-rule="evenodd" d="M4 4a2 2 0 00-2 2v4a2 2 0 002 2V6h10a2 2 0 00-2-2H4zm2 6a2 2 0 012-2h8a2 2 0 012 2v4a2 2 0 01-2 2H8a2 2 0 01-2-2v-4zm6 4a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"></path>
                    </svg>
                    <%= @contact.company_name || "Sin empresa" %>
                  </li>
                </ul>
              </div>
            </div>

            <!-- Stats Card -->
            <div class="p-4 mb-4 bg-white rounded-lg shadow sm:p-6 xl:p-8 dark:bg-gray-800">
              <div class="flow-root">
                <h3 class="text-xl font-bold dark:text-white">Estadísticas</h3>
                <div class="mt-4 space-y-3">
                  <div class="flex justify-between items-center">
                    <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Actividades</span>
                    <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= @stats.total_activities %></span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Completadas</span>
                    <span class="text-sm font-semibold text-green-600 dark:text-green-400"><%= @stats.completed_activities %></span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Pendientes</span>
                    <span class="text-sm font-semibold text-yellow-600 dark:text-yellow-400"><%= @stats.pending_activities %></span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Tickets Mantenimiento</span>
                    <span class="text-sm font-semibold text-blue-600 dark:text-blue-400"><%= @stats.maintenance_tickets %></span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Skills/Tags Card -->
            <div class="p-4 mb-4 bg-white rounded-lg shadow sm:p-6 xl:p-8 dark:bg-gray-800">
              <div class="flow-root">
                <h3 class="text-xl font-bold dark:text-white">Información</h3>
                <ul class="flex flex-wrap mt-4">
                  <li class="bg-blue-100 dark:bg-blue-200 text-blue-800 text-base font-medium px-3 py-1.5 rounded-md mb-2 mr-2">
                    <%= @contact.status || "Sin estado" %>
                  </li>
                  <li class="bg-green-100 dark:bg-green-200 text-green-800 text-base font-medium px-3 py-1.5 rounded-md mb-2 mr-2">
                    <%= @contact.source || "Sin origen" %>
                  </li>
                  <%= if @contact.company_name do %>
                    <li class="bg-purple-100 dark:bg-purple-200 text-purple-800 text-base font-medium px-3 py-1.5 rounded-md mb-2 mr-2">
                      <%= @contact.company_name %>
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>
          </div>

          <!-- Right Column - Detailed Information -->
          <div class="lg:col-span-2">
            <!-- General Information -->
            <div class="p-4 mb-4 bg-white rounded-lg shadow sm:p-6 xl:p-8 dark:bg-gray-800">
              <h3 class="mb-4 text-xl font-bold dark:text-white">Información General</h3>
              <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
                <div class="sm:col-span-2">
                  <dt class="text-lg font-medium text-gray-900 dark:text-white">Detalles del Cliente</dt>
                  <dd class="mt-1 space-y-3 max-w-prose text-sm text-gray-500 dark:text-gray-400">
                    <p>Cliente registrado en el sistema con información completa de contacto y seguimiento de actividades.</p>
                    <p>Este perfil muestra todas las interacciones, actividades programadas y tickets de mantenimiento asociados.</p>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Nombre Completo</dt>
                  <dd class="text-sm font-semibold text-gray-900 dark:text-white"><%= EvaaCrmGaepell.Contact.full_name(@contact) %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Email</dt>
                  <dd class="text-sm font-semibold text-gray-900 dark:text-white"><%= @contact.email || "Sin email" %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Teléfono</dt>
                  <dd class="text-sm font-semibold text-gray-900 dark:text-white"><%= @contact.phone || "Sin teléfono" %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Empresa</dt>
                  <dd class="text-sm font-semibold text-gray-900 dark:text-white"><%= @contact.company_name || "Sin empresa" %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Estado</dt>
                  <dd class="text-sm font-semibold text-gray-900 dark:text-white"><%= @contact.status || "Sin estado" %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Origen</dt>
                  <dd class="text-sm font-semibold text-gray-900 dark:text-white"><%= @contact.source || "Sin origen" %></dd>
                </div>
              </dl>
            </div>

            <!-- Progress Bars -->
            <div class="p-4 mb-4 bg-white rounded-lg shadow sm:p-6 xl:p-8 dark:bg-gray-800">
              <div class="grid grid-cols-1 gap-6 md:grid-cols-2 md:gap-16 lg:gap-8 2xl:gap-24">
                <div class="space-y-6">
                  <div>
                    <div class="mb-1 text-base font-medium text-gray-500 dark:text-gray-400">Actividades Completadas</div>
                    <div class="w-full h-2 bg-gray-200 rounded-full dark:bg-gray-700">
                      <div class="h-2 bg-green-600 rounded-full dark:bg-green-500" style={"width: #{if @stats.total_activities > 0, do: (@stats.completed_activities / @stats.total_activities * 100) |> round(), else: 0}%"}></div>
                    </div>
                  </div>
                  <div>
                    <div class="mb-1 text-base font-medium text-gray-500 dark:text-gray-400">Actividades Pendientes</div>
                    <div class="w-full h-2 bg-gray-200 rounded-full dark:bg-gray-700">
                      <div class="h-2 bg-yellow-600 rounded-full dark:bg-yellow-500" style={"width: #{if @stats.total_activities > 0, do: (@stats.pending_activities / @stats.total_activities * 100) |> round(), else: 0}%"}></div>
                    </div>
                  </div>
                </div>
                <div class="space-y-6">
                  <div>
                    <div class="mb-1 text-base font-medium text-gray-500 dark:text-gray-400">Tickets de Mantenimiento</div>
                    <div class="w-full h-2 bg-gray-200 rounded-full dark:bg-gray-700">
                      <div class="h-2 bg-blue-600 rounded-full dark:bg-blue-500" style={"width: #{if @stats.total_activities > 0, do: (@stats.maintenance_tickets / @stats.total_activities * 100) |> round(), else: 0}%"}></div>
                    </div>
                  </div>
                  <div>
                    <div class="mb-1 text-base font-medium text-gray-500 dark:text-gray-400">Eficiencia General</div>
                    <div class="w-full h-2 bg-gray-200 rounded-full dark:bg-gray-700">
                      <div class="h-2 bg-purple-600 rounded-full dark:bg-purple-500" style={"width: #{if @stats.total_activities > 0, do: (@stats.completed_activities / @stats.total_activities * 100) |> round(), else: 0}%"}></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="p-4 mb-4 bg-white rounded-lg shadow sm:p-6 xl:p-8 dark:bg-gray-800">
              <h3 class="mb-4 text-xl font-bold dark:text-white">Acciones</h3>
              <div class="flex flex-wrap gap-3">
                <button phx-click="show_edit_form" class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
                  <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                    <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path>
                  </svg>
                  Editar Cliente
                </button>
                <a href="/crm" class="inline-flex items-center px-4 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-lg hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700">
                  <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                    <path fill-rule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd"></path>
                  </svg>
                  Volver a Clientes
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Edit Form Modal -->
      <%= if @show_edit_form do %>
        <div class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
          <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
            <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
            <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full dark:bg-gray-800">
              <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4 dark:bg-gray-800">
                <div class="sm:flex sm:items-start">
                  <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                    <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white" id="modal-title">
                      Editar Cliente
                    </h3>
                    <div class="mt-2">
                      <form id="contact-form" phx-submit="update_contact" class="space-y-4">
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Nombre</label>
                          <input type="text" name="contact[first_name]" value={@editing_contact.first_name} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Apellido</label>
                          <input type="text" name="contact[last_name]" value={@editing_contact.last_name} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Email</label>
                          <input type="email" name="contact[email]" value={@editing_contact.email} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Teléfono</label>
                          <input type="text" name="contact[phone]" value={@editing_contact.phone} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Empresa</label>
                          <input type="text" name="contact[company_name]" value={@editing_contact.company_name} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Estado</label>
                          <select name="contact[status]" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            <option value="active" selected={@editing_contact.status == "active"}>Activo</option>
                            <option value="inactive" selected={@editing_contact.status == "inactive"}>Inactivo</option>
                            <option value="prospect" selected={@editing_contact.status == "prospect"}>Prospecto</option>
                          </select>
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Origen</label>
                          <select name="contact[source]" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            <option value="website" selected={@editing_contact.source == "website"}>Website</option>
                            <option value="referral" selected={@editing_contact.source == "referral"}>Referido</option>
                            <option value="social" selected={@editing_contact.source == "social"}>Redes Sociales</option>
                            <option value="other" selected={@editing_contact.source == "other"}>Otro</option>
                          </select>
                        </div>
                      </form>
                    </div>
                  </div>
                </div>
              </div>
              <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse dark:bg-gray-700">
                <button type="submit" form="contact-form" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm">
                  Guardar
                </button>
                <button phx-click="hide_edit_form" type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm dark:bg-gray-600 dark:text-gray-300 dark:border-gray-500 dark:hover:bg-gray-500">
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp load_all_contact_activities(socket) do
    query = from a in Activity,
            where: a.contact_id == ^socket.assigns.contact.id,
            preload: [:company, :service, :specialist, :truck, :maintenance_ticket],
            order_by: [asc: a.due_date]

    all_activities = Repo.all(query)
    assign(socket, :all_activities, all_activities)
  end

  defp load_contact_trucks(socket) do
    # Obtener camiones asociados al cliente a través de actividades
    trucks_query = from a in Activity,
                   where: a.contact_id == ^socket.assigns.contact.id and not is_nil(a.truck_id),
                   distinct: a.truck_id,
                   preload: [:truck]
    
    trucks = Repo.all(trucks_query)
    |> Enum.map(fn activity -> activity.truck end)
    
    assign(socket, :trucks, trucks)
  end

  defp load_contact_specialists(socket) do
    # Obtener especialistas únicos del cliente
    specialists_query = from a in Activity,
                       where: a.contact_id == ^socket.assigns.contact.id and not is_nil(a.specialist_id),
                       distinct: a.specialist_id,
                       preload: [:specialist]
    
    specialists = Repo.all(specialists_query)
    |> Enum.map(fn activity -> activity.specialist end)
    
    assign(socket, :specialists, specialists)
  end

  defp load_contact_stats(socket) do
    # Estadísticas del cliente
    total_activities = from a in Activity,
                      where: a.contact_id == ^socket.assigns.contact.id
    
    completed_activities = from a in Activity,
                          where: a.contact_id == ^socket.assigns.contact.id and a.status == "completed"
    
    pending_activities = from a in Activity,
                        where: a.contact_id == ^socket.assigns.contact.id and a.status == "pending"
    
    maintenance_tickets = from a in Activity,
                         where: a.contact_id == ^socket.assigns.contact.id and not is_nil(a.maintenance_ticket_id)
    
    stats = %{
      total_activities: Repo.aggregate(total_activities, :count, :id) || 0,
      completed_activities: Repo.aggregate(completed_activities, :count, :id) || 0,
      pending_activities: Repo.aggregate(pending_activities, :count, :id) || 0,
      maintenance_tickets: Repo.aggregate(maintenance_tickets, :count, :id) || 0
    }
    
    assign(socket, :stats, stats)
  end

  defp update_contact(contact, contact_params) do
    contact
    |> Contact.changeset(contact_params)
    |> Repo.update()
  end
end 