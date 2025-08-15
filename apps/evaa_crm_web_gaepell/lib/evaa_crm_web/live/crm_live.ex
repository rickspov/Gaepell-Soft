defmodule EvaaCrmWebGaepell.CrmLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Contact, Company, Repo}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "CRM - Representantes")
     |> assign(:contacts, [])
     |> assign(:companies, [])
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:show_form, false)
     |> assign(:editing_contact, nil)
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)
     |> load_contacts()
     |> load_companies()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, 
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> load_contacts()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_status, status)
     |> assign(:page, 1)
     |> load_contacts()}
  end

  @impl true
  def handle_event("show_form", %{"contact_id" => contact_id}, socket) do
    contact = if contact_id == "new" do
      %Contact{}
    else
      Repo.get(Contact, contact_id)
    end
    
    {:noreply, 
     socket
     |> assign(:show_form, true)
     |> assign(:editing_contact, contact)}
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_form, false)
     |> assign(:editing_contact, nil)}
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id, "type" => "contact"}, socket) do
    contact = Repo.get(Contact, id)
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, true)
     |> assign(:delete_target, %{id: id, type: "contact", name: EvaaCrmGaepell.Contact.full_name(contact)})}
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
    case socket.assigns.delete_target do
      %{id: id, type: "contact"} ->
        contact = Repo.get(Contact, id)
        case Repo.delete(contact) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Representante eliminado exitosamente")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_contacts()}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al eliminar el representante")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_contacts()}
        end
      
      _ ->
        {:noreply, 
         socket
         |> put_flash(:error, "Tipo de eliminación no válido")
         |> assign(:show_delete_confirm, false)
         |> assign(:delete_target, nil)}
    end
  end

  @impl true
  def handle_event("save_contact", %{"contact" => contact_params}, socket) do
    # For demo purposes, use business_id = 1 (Spa Demo)
    contact_params = Map.put(contact_params, "business_id", 1)
    
    case save_contact(socket.assigns.editing_contact, contact_params) do
      {:ok, _contact} ->
        {:noreply, 
         socket
                      |> put_flash(:info, "Representante guardado exitosamente")
         |> assign(:show_form, false)
         |> assign(:editing_contact, nil)
         |> load_contacts()}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :editing_contact, %{socket.assigns.editing_contact | action: :insert, errors: changeset.errors})}
    end
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, 
     socket
     |> assign(:page, String.to_integer(page))
     |> load_contacts()}
  end

  defp load_contacts(socket) do
    query = from c in Contact,
            where: c.business_id == 1,
            preload: [:company],
            order_by: [desc: c.inserted_at]

    query = case socket.assigns.search do
      "" -> query
      search -> 
        search_term = "%#{search}%"
        from c in query,
        where: ilike(c.first_name, ^search_term) or 
               ilike(c.last_name, ^search_term) or 
               ilike(c.email, ^search_term)
    end

    query = case socket.assigns.filter_status do
      "all" -> query
      status -> from c in query, where: c.status == ^status
    end

    total = Repo.aggregate(query, :count)
    contacts = query
               |> limit(^socket.assigns.per_page)
               |> offset(^((socket.assigns.page - 1) * socket.assigns.per_page))
               |> Repo.all()

    assign(socket, :contacts, contacts)
    |> assign(:total_contacts, total)
    |> assign(:total_pages, ceil(total / socket.assigns.per_page))
  end

  defp load_companies(socket) do
    companies = Repo.all(from c in Company, where: c.business_id == 1, select: {c.name, c.id})
    assign(socket, :companies, companies)
  end

  defp save_contact(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset(attrs)
    |> Repo.insert_or_update()
  end

  defp save_contact(nil, attrs) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-center">
        <div>
                  <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Representantes</h1>
        <p class="text-gray-600 dark:text-gray-400 mt-1">Gestión de representantes y contactos empresariales</p>
        </div>
        <button 
          phx-click="show_form" 
          phx-value-contact_id="new"
          class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center space-x-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
                          <span>Nuevo Representante</span>
        </button>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <div class="flex flex-col md:flex-row gap-4">
          <!-- Search -->
          <div class="flex-1">
            <form phx-change="search" class="relative">
              <input 
                type="text" 
                name="search" 
                value={@search}
                placeholder="Buscar representantes..." 
                class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
            </form>
          </div>
          
          <!-- Status Filter -->
          <div>
            <select 
              phx-change="filter_status" 
              name="status"
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <option value="all">Todos los estados</option>
              <option value="active">Activo</option>
              <option value="inactive">Inactivo</option>
              <option value="prospect">Prospecto</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Contacts Table -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Representantes (<%= @total_contacts %>)
          </h3>
        </div>
        
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Empresa</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Representante</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Contacto</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Origen</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <%= for contact <- @contacts do %>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    <%= if contact.company_name && contact.company_name != "", do: contact.company_name, else: "—" %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="flex-shrink-0 h-10 w-10">
                        <div class="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                          <span class="text-sm font-medium text-blue-600 dark:text-blue-400">
                            <%= String.first(contact.first_name) %><%= String.first(contact.last_name) %>
                          </span>
                        </div>
                      </div>
                      <div class="ml-4">
                        <div class="text-sm font-medium text-gray-900 dark:text-white">
                          <%= contact.first_name %> <%= contact.last_name %>
                        </div>
                        <div class="text-sm text-gray-500 dark:text-gray-400">
                          <%= contact.job_title %>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm text-gray-900 dark:text-white"><%= contact.email %></div>
                    <div class="text-sm text-gray-500 dark:text-gray-400"><%= contact.phone %></div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={[
                      "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                      status_color(contact.status)
                    ]}>
                      <%= status_label(contact.status) %>
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    <%= source_label(contact.source) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div class="flex space-x-2">
                      <a 
                        href={"/pacientes/#{contact.id}"}
                        class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-1"
                        title="Ver perfil del representante">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                        </svg>
                      </a>
                      <button 
                        phx-click="show_form" 
                        phx-value-contact_id={contact.id}
                        class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-1"
                        title="Editar representante">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                        </svg>
                      </button>
                      <button 
                        phx-click="show_delete_confirm" 
                        phx-value-id={contact.id}
                        phx-value-type="contact"
                        class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-1"
                        title="Eliminar representante">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <%= if @contacts == [] do %>
          <div class="text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay representantes</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              Comienza agregando tu primer representante.
            </p>
          </div>
        <% end %>
      </div>

      <!-- Pagination -->
      <%= if @total_pages > 1 do %>
        <div class="flex justify-center">
          <nav class="flex space-x-2">
            <%= for page <- 1..@total_pages do %>
              <button 
                phx-click="paginate" 
                phx-value-page={page}
                class={[
                  "px-3 py-2 text-sm font-medium rounded-md",
                  if page == @page do
                    "bg-blue-600 text-white"
                  else
                    "text-gray-500 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700"
                  end
                ]}>
                <%= page %>
              </button>
            <% end %>
          </nav>
        </div>
      <% end %>
    </div>

    <!-- Modal Form -->
    <%= if @show_form do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                <%= if @editing_contact.id, do: "Editar Representante", else: "Nuevo Representante" %>
              </h3>
              <button 
                phx-click="hide_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="save_contact">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nombre *
                  </label>
                  <input 
                    type="text" 
                    name="contact[first_name]" 
                    value={@editing_contact.first_name}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Apellido *
                  </label>
                  <input 
                    type="text" 
                    name="contact[last_name]" 
                    value={@editing_contact.last_name}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Email
                  </label>
                  <input 
                    type="email" 
                    name="contact[email]" 
                    value={@editing_contact.email}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Teléfono
                  </label>
                  <input 
                    type="tel" 
                    name="contact[phone]" 
                    value={@editing_contact.phone}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Empresa
                  </label>
                  <input 
                    type="text" 
                    name="contact[company_name]" 
                    value={@editing_contact.company_name}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Estado
                  </label>
                  <select 
                    name="contact[status]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="active" selected={@editing_contact.status == "active"}>Activo</option>
                    <option value="inactive" selected={@editing_contact.status == "inactive"}>Inactivo</option>
                    <option value="prospect" selected={@editing_contact.status == "prospect"}>Prospecto</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Origen
                  </label>
                  <select 
                    name="contact[source]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar origen</option>
                    <option value="website" selected={@editing_contact.source == "website"}>Sitio web</option>
                    <option value="referral" selected={@editing_contact.source == "referral"}>Referido</option>
                    <option value="event" selected={@editing_contact.source == "event"}>Evento</option>
                    <option value="social_media" selected={@editing_contact.source == "social_media"}>Redes sociales</option>
                    <option value="other" selected={@editing_contact.source == "other"}>Otro</option>
                  </select>
                </div>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button 
                  type="button"
                  phx-click="hide_form"
                  class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                  Cancelar
                </button>
                <button 
                  type="submit"
                  class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700">
                  Guardar Representante
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Delete Confirmation Modal -->
    <%= if @show_delete_confirm do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                Confirmar Eliminación
              </h3>
              <button 
                phx-click="hide_delete_confirm"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <p class="text-sm text-gray-500 dark:text-gray-400">
              ¿Estás seguro de que quieres eliminar el representante "<%= @delete_target.name %>"?
            </p>

            <div class="mt-6 flex justify-end space-x-3">
              <button 
                type="button"
                phx-click="hide_delete_confirm"
                class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                Cancelar
              </button>
              <button 
                type="button"
                phx-click="confirm_delete"
                class="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700">
                Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp status_color("active"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp status_color("inactive"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp status_color("prospect"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp status_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp status_label("active"), do: "Activo"
  defp status_label("inactive"), do: "Inactivo"
  defp status_label("prospect"), do: "Prospecto"
  defp status_label(_), do: "Desconocido"

  defp source_label("website"), do: "Sitio web"
  defp source_label("referral"), do: "Referido"
  defp source_label("event"), do: "Evento"
  defp source_label("social_media"), do: "Redes sociales"
  defp source_label("other"), do: "Otro"
  defp source_label(_), do: "—"
end 