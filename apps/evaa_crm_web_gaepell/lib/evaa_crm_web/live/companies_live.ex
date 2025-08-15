defmodule EvaaCrmWebGaepell.CompaniesLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Company, Specialist, User, Repo}
  import Ecto.Query
  alias Bcrypt

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Doctores y Especialistas")
     |> assign(:companies, [])
     |> assign(:specialists, [])
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:show_form, false)
     |> assign(:editing_company, nil)
     |> assign(:editing_specialist, nil)
     |> assign(:active_tab, "doctors")
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)
     |> assign(:create_user, false)
     |> load_companies()
     |> load_specialists()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    socket = socket
     |> assign(:search, search)
     |> assign(:page, 1)
    
    # Load appropriate data based on active tab
    socket = case socket.assigns.active_tab do
      "doctors" -> load_companies(socket)
      "specialists" -> load_specialists(socket)
      _ -> socket
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    socket = socket
     |> assign(:filter_status, status)
     |> assign(:page, 1)
    
    # Load appropriate data based on active tab
    socket = case socket.assigns.active_tab do
      "doctors" -> load_companies(socket)
      "specialists" -> load_specialists(socket)
      _ -> socket
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_form", %{"company_id" => company_id}, socket) do
    company = if company_id == "new" do
      %Company{
        name: "",
        email: "",
        phone: "",
        industry: "",
        status: "active",
        city: "",
        state: "",
        address: "",
        description: "",
        size: ""
      }
    else
      Repo.get(Company, company_id)
    end
    
    {:noreply, 
     socket
     |> assign(:show_form, true)
     |> assign(:editing_company, company)
     |> assign(:editing_specialist, nil)}
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_form, false)
     |> assign(:editing_company, nil)
     |> assign(:editing_specialist, nil)}
  end

  @impl true
  def handle_event("save_company", %{"company" => company_params}, socket) do
    # For demo purposes, use business_id = 1 (Spa Demo)
    company_params = Map.put(company_params, "business_id", 1)
    
    case save_company(socket.assigns.editing_company, company_params) do
      {:ok, _company} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Doctor guardado exitosamente")
         |> assign(:show_form, false)
         |> assign(:editing_company, nil)
         |> load_companies()}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :editing_company, %{socket.assigns.editing_company | action: :insert, errors: changeset.errors})}
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id, "type" => type}, socket) do
    case type do
      "company" ->
        company = Repo.get(Company, id)
        {:noreply, 
         socket
         |> assign(:show_delete_confirm, true)
         |> assign(:delete_target, %{id: id, type: "company", name: company.name})}
      
      "specialist" ->
        specialist = Repo.get(Specialist, id)
        {:noreply, 
         socket
         |> assign(:show_delete_confirm, true)
         |> assign(:delete_target, %{id: id, type: "specialist", name: EvaaCrmGaepell.Specialist.full_name(specialist)})}
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
    case socket.assigns.delete_target do
      %{id: id, type: "company"} ->
        company = Repo.get(Company, id)
        case Repo.delete(company) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Doctor eliminado exitosamente")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_companies()}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al eliminar el doctor")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_companies()}
        end
      
      %{id: id, type: "specialist"} ->
        specialist = Repo.get(Specialist, id)
        case Repo.delete(specialist) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Especialista eliminado exitosamente")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_specialists()}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al eliminar el especialista")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_specialists()}
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
  def handle_event("paginate", %{"page" => page}, socket) do
    socket = socket |> assign(:page, String.to_integer(page))
    
    # Load appropriate data based on active tab
    socket = case socket.assigns.active_tab do
      "doctors" -> load_companies(socket)
      "specialists" -> load_specialists(socket)
      _ -> socket
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    socket = socket
     |> assign(:active_tab, tab)
     |> assign(:page, 1)
     |> assign(:search, "")
     |> assign(:filter_status, "all")
    
    # Load appropriate data based on tab
    socket = case tab do
      "doctors" -> load_companies(socket)
      "specialists" -> load_specialists(socket)
      _ -> socket
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_specialist_form", %{"specialist_id" => specialist_id}, socket) do
    specialist = if specialist_id == "new" do
      %Specialist{
        first_name: "",
        last_name: "",
        email: "",
        phone: "",
        specialization: "",
        status: "active",
        availability: "",
        is_active: true
      }
    else
      Repo.get(Specialist, specialist_id)
    end
    
    {:noreply, 
     socket
     |> assign(:show_form, true)
     |> assign(:editing_company, nil)
     |> assign(:editing_specialist, specialist)
     |> assign(:create_user, specialist_id == "new")}
  end

  @impl true
  def handle_event("save_specialist", %{"specialist" => specialist_params, "user" => user_params}, socket) do
    # For demo purposes, use business_id = 1 (Spa Demo)
    specialist_params = Map.put(specialist_params, "business_id", 1)
    
    case save_specialist_with_user(socket.assigns.editing_specialist, specialist_params, user_params, socket.assigns.create_user) do
      {:ok, _specialist} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Especialista guardado exitosamente")
         |> assign(:show_form, false)
         |> assign(:editing_specialist, nil)
         |> assign(:create_user, false)
         |> load_specialists()}
      
      {:error, error} ->
        # Handle different types of errors
        errors = case error do
          %{errors: errors} when is_list(errors) -> errors
          %{errors: errors} -> [{"error", errors}]
          _ -> [{"error", "Error desconocido al guardar el especialista"}]
        end
        {:noreply, assign(socket, :editing_specialist, %{socket.assigns.editing_specialist | action: :insert, errors: errors})}
    end
  end

  @impl true
  def handle_event("save_specialist", %{"specialist" => specialist_params}, socket) do
    # Handle case when no user data is provided
    handle_event("save_specialist", %{"specialist" => specialist_params, "user" => %{}}, socket)
  end

  @impl true
  def handle_event("toggle_create_user", _params, socket) do
    {:noreply, assign(socket, :create_user, !socket.assigns.create_user)}
  end

  defp load_companies(socket) do
    try do
      query = from c in Company,
              where: c.business_id == 1,
              order_by: [desc: c.inserted_at]

      query = case socket.assigns.search do
        "" -> query
        search -> 
          search_term = "%#{search}%"
          from c in query,
          where: ilike(c.name, ^search_term) or 
                 ilike(c.email, ^search_term) or
                 ilike(c.industry, ^search_term)
      end

      query = case socket.assigns.filter_status do
        "all" -> query
        status -> from c in query, where: c.status == ^status
      end

      total = Repo.aggregate(query, :count)
      companies = query
                  |> limit(^socket.assigns.per_page)
                  |> offset(^((socket.assigns.page - 1) * socket.assigns.per_page))
                  |> Repo.all()

      assign(socket, :companies, companies)
      |> assign(:total_companies, total)
      |> assign(:total_pages, ceil(total / socket.assigns.per_page))
    rescue
      e ->
        IO.puts("Error loading companies: #{inspect(e)}")
        assign(socket, :companies, [])
        |> assign(:total_companies, 0)
        |> assign(:total_pages, 0)
    end
  end

  defp save_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.insert_or_update()
  end

  defp save_company(nil, attrs) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  defp load_specialists(socket) do
    try do
      query = from s in Specialist,
              where: s.business_id == 1,
              order_by: [desc: s.inserted_at]

      # Apply search filter
      query = case socket.assigns.search do
        "" -> query
        search -> 
          search_term = "%#{search}%"
          from s in query,
          where: ilike(s.first_name, ^search_term) or 
                 ilike(s.last_name, ^search_term) or
                 ilike(s.email, ^search_term) or
                 ilike(s.specialization, ^search_term)
      end

      # Apply status filter
      query = case socket.assigns.filter_status do
        "all" -> query
        status -> from s in query, where: s.status == ^status
      end

      total = Repo.aggregate(query, :count)
      specialists = query
                    |> limit(^socket.assigns.per_page)
                    |> offset(^((socket.assigns.page - 1) * socket.assigns.per_page))
                    |> Repo.all()

      assign(socket, :specialists, specialists)
      |> assign(:total_specialists, total)
      |> assign(:total_specialists_pages, ceil(total / socket.assigns.per_page))
    rescue
      e ->
        IO.puts("Error loading specialists: #{inspect(e)}")
        assign(socket, :specialists, [])
        |> assign(:total_specialists, 0)
        |> assign(:total_specialists_pages, 0)
    end
  end

  defp save_specialist(%Specialist{} = specialist, attrs) do
    specialist
    |> Specialist.changeset(attrs)
    |> Repo.insert_or_update()
  end

  defp save_specialist(nil, attrs) do
    %Specialist{}
    |> Specialist.changeset(attrs)
    |> Repo.insert()
  end

  defp save_specialist_with_user(specialist, specialist_params, user_params, create_user) do
    Repo.transaction(fn ->
      # Save specialist first
      specialist_result = save_specialist(specialist, specialist_params)
      
      case specialist_result do
        {:ok, saved_specialist} ->
          # If create_user is true and user_params are provided, create user
          if create_user and user_params["email"] && user_params["email"] != "" do
            user_attrs = %{
              "email" => user_params["email"],
              "password_hash" => Bcrypt.hash_pwd_salt(user_params["password"]),
              "role" => "specialist",
              "business_id" => 1,
              "specialist_id" => saved_specialist.id
            }
            
            case User.changeset(%User{}, user_attrs) |> Repo.insert() do
              {:ok, _user} ->
                saved_specialist
              {:error, user_changeset} ->
                Repo.rollback(user_changeset)
            end
          else
            # If no user is being created, check if we should create one automatically
            # when specialist has email but no user exists
            if specialist_params["email"] && specialist_params["email"] != "" do
              # Check if a user with this email already exists
              existing_user = Repo.get_by(User, email: specialist_params["email"])
              if !existing_user do
                # Create a default user account for the specialist
                user_attrs = %{
                  "email" => specialist_params["email"],
                  "password_hash" => Bcrypt.hash_pwd_salt("password123"), # Default password
                  "role" => "specialist",
                  "business_id" => 1,
                  "specialist_id" => saved_specialist.id
                }
                
                case User.changeset(%User{}, user_attrs) |> Repo.insert() do
                  {:ok, _user} -> saved_specialist
                  {:error, _} -> saved_specialist # Don't rollback if user creation fails
                end
              else
                saved_specialist
              end
            else
              saved_specialist
            end
          end
        
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
            <%= if @active_tab == "doctors", do: "Doctores", else: "Especialistas" %>
          </h1>
          <p class="text-gray-600 dark:text-gray-400 mt-1">
            <%= if @active_tab == "doctors" do %>
              Gestión de doctores referentes externos
            <% else %>
              Gestión de especialistas internos de la clínica
            <% end %>
          </p>
        </div>
        <button 
          phx-click={if @active_tab == "doctors", do: "show_form", else: "show_specialist_form"}
          phx-value-company_id={if @active_tab == "doctors", do: "new", else: nil}
          phx-value-specialist_id={if @active_tab == "specialists", do: "new", else: nil}
          class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center space-x-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          <span><%= if @active_tab == "doctors", do: "Nuevo Doctor", else: "Nuevo Especialista" %></span>
        </button>
      </div>

      <!-- Tabs -->
      <div class="border-b border-gray-200 dark:border-gray-700">
        <nav class="-mb-px flex space-x-8">
          <button 
            phx-click="change_tab" 
            phx-value-tab="doctors"
            class={[
              "py-2 px-1 border-b-2 font-medium text-sm",
              if @active_tab == "doctors" do
                "border-blue-500 text-blue-600 dark:text-blue-400"
              else
                "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300"
              end
            ]}>
            👨‍⚕️ Doctores
          </button>
          <button 
            phx-click="change_tab" 
            phx-value-tab="specialists"
            class={[
              "py-2 px-1 border-b-2 font-medium text-sm",
              if @active_tab == "specialists" do
                "border-blue-500 text-blue-600 dark:text-blue-400"
              else
                "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300"
              end
            ]}>
            👩‍⚕️ Especialistas
          </button>
        </nav>
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
                placeholder={if @active_tab == "doctors", do: "Buscar doctores...", else: "Buscar especialistas..."}
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

      <!-- Data Table -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            {if @active_tab == "doctors", do: "Doctores", else: "Especialistas"} (<%= if @active_tab == "doctors", do: @total_companies, else: @total_specialists %>)
          </h3>
        </div>
        
        <%= if @active_tab == "doctors" do %>
          <!-- Doctors Table -->
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Doctor</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Contacto</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Especialidad</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Ubicación</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for company <- @companies do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex-shrink-0 h-10 w-10">
                          <div class="h-10 w-10 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                            <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                          </div>
                        </div>
                        <div class="ml-4">
                          <div class="text-sm font-medium text-gray-900 dark:text-white">
                            <%= company.name %>
                          </div>
                          <div class="text-sm text-gray-500 dark:text-gray-400">
                            <%= company.size %>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-900 dark:text-white"><%= company.email %></div>
                      <div class="text-sm text-gray-500 dark:text-gray-400"><%= company.phone %></div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= company.industry %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={[
                        "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                        status_color(company.status)
                      ]}>
                        <%= status_label(company.status) %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= company.city %>, <%= company.state %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div class="flex space-x-2">
                        <a 
                          href={"/doctors/#{company.id}"}
                          class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300 p-1"
                          title="Ver perfil del doctor">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                          </svg>
                        </a>
                        <button 
                          phx-click="show_form" 
                          phx-value-company_id={company.id}
                          class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-1"
                          title="Editar doctor">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                          </svg>
                        </button>
                        <button 
                          phx-click="show_delete_confirm" 
                          phx-value-id={company.id}
                          phx-value-type="company"
                          class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-1"
                          title="Eliminar doctor">
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

          <%= if @companies == [] do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay doctores</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Comienza agregando tu primer doctor.
              </p>
            </div>
          <% end %>
        <% else %>
          <!-- Specialists Table -->
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Especialista</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Contacto</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Especialización</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Horario</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for specialist <- @specialists do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex-shrink-0 h-10 w-10">
                          <div class="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900 flex items-center justify-center">
                            <svg class="w-5 h-5 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                          </div>
                        </div>
                        <div class="ml-4">
                          <div class="text-sm font-medium text-gray-900 dark:text-white">
                            <%= EvaaCrmGaepell.Specialist.full_name(specialist) %>
                          </div>
                          <div class="text-sm text-gray-500 dark:text-gray-400">
                            ID: <%= specialist.id %>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-900 dark:text-white"><%= specialist.email %></div>
                      <div class="text-sm text-gray-500 dark:text-gray-400"><%= specialist.phone %></div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= specialist.specialization %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={[
                        "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                        status_color(specialist.status)
                      ]}>
                        <%= status_label(specialist.status) %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      <%= specialist.availability %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div class="flex space-x-2">
                        <a 
                          href={"/especialistas/#{specialist.id}"}
                          class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300 p-1"
                          title="Ver perfil del especialista">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                          </svg>
                        </a>
                        <button 
                          phx-click="show_specialist_form" 
                          phx-value-specialist_id={specialist.id}
                          class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-1"
                          title="Editar especialista">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                          </svg>
                        </button>
                        <button 
                          phx-click="show_delete_confirm" 
                          phx-value-id={specialist.id}
                          phx-value-type="specialist"
                          class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-1"
                          title="Eliminar especialista">
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

          <%= if @specialists == [] do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay especialistas</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Comienza agregando tu primer especialista.
              </p>
            </div>
          <% end %>
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

    <!-- Doctor Modal Form -->
    <%= if @show_form and @editing_company != nil and @editing_specialist == nil do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                <%= if @editing_company.id, do: "Editar Doctor", else: "Nuevo Doctor" %>
              </h3>
              <button 
                phx-click="hide_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="save_company">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="md:col-span-2">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nombre del Doctor *
                  </label>
                  <input 
                    type="text" 
                    name="company[name]" 
                    value={@editing_company.name || ""}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                  <input 
                    type="email" 
                    name="company[email]" 
                    value={@editing_company.email || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Teléfono</label>
                  <input 
                    type="tel" 
                    name="company[phone]" 
                    value={@editing_company.phone || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Especialidad</label>
                  <select 
                    name="company[industry]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar especialidad</option>
                    <%= for option <- ["Cirugía Plástica", "Dermatología", "Medicina Estética", "Odontología", "Oftalmología", "Ginecología", "Otra"] do %>
                      <option value={option} selected={@editing_company.industry == option}><%= option %></option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Estado</label>
                  <select 
                    name="company[status]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="active" selected={@editing_company.status == "active"}>Activo</option>
                    <option value="inactive" selected={@editing_company.status == "inactive"}>Inactivo</option>
                    <option value="prospect" selected={@editing_company.status == "prospect"}>Prospecto</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Ciudad</label>
                  <input 
                    type="text" 
                    name="company[city]" 
                    value={@editing_company.city || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Estado/Provincia</label>
                  <input 
                    type="text" 
                    name="company[state]" 
                    value={@editing_company.state || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div class="md:col-span-2">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Dirección</label>
                  <textarea 
                    name="company[address]" 
                    rows="2"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"><%= @editing_company.address || "" %></textarea>
                </div>

                <div class="md:col-span-2">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Descripción</label>
                  <textarea 
                    name="company[description]" 
                    rows="3"
                    placeholder="Información adicional sobre el doctor..."
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"><%= @editing_company.description || "" %></textarea>
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
                  Guardar Doctor
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Specialist Modal Form -->
    <%= if @show_form and @editing_specialist != nil and @editing_company == nil do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                <%= if @editing_specialist.id, do: "Editar Especialista", else: "Nuevo Especialista" %>
              </h3>
              <button 
                phx-click="hide_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="save_specialist">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nombre(s) *
                  </label>
                  <input 
                    type="text" 
                    name="specialist[first_name]" 
                    value={@editing_specialist.first_name || ""}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Apellidos *
                  </label>
                  <input 
                    type="text" 
                    name="specialist[last_name]" 
                    value={@editing_specialist.last_name || ""}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                  <input 
                    type="email" 
                    name="specialist[email]" 
                    value={@editing_specialist.email || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Teléfono</label>
                  <input 
                    type="tel" 
                    name="specialist[phone]" 
                    value={@editing_specialist.phone || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Especialización</label>
                  <select 
                    name="specialist[specialization]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar especialización</option>
                    <%= for option <- ["Masaje Terapéutico", "Facial", "Corporal", "Depilación", "Manicure/Pedicure", "Maquillaje", "Estética Dental", "Otra"] do %>
                      <option value={option} selected={@editing_specialist.specialization == option}><%= option %></option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Estado</label>
                  <select 
                    name="specialist[status]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="active" selected={@editing_specialist.status == "active"}>Activo</option>
                    <option value="inactive" selected={@editing_specialist.status == "inactive"}>Inactivo</option>
                    <option value="vacation" selected={@editing_specialist.status == "vacation"}>Vacaciones</option>
                  </select>
                </div>

                <div class="md:col-span-2">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Horario de Disponibilidad</label>
                  <textarea 
                    name="specialist[availability]" 
                    rows="2"
                    placeholder="Ej: Lunes a Viernes 9:00 AM - 6:00 PM"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"><%= @editing_specialist.availability || "" %></textarea>
                </div>

                <div class="md:col-span-2">
                  <label class="flex items-center">
                    <input 
                      type="checkbox" 
                      name="specialist[is_active]" 
                      value="true"
                      checked={@editing_specialist.is_active}
                      class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50" />
                    <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">Especialista activo</span>
                  </label>
                </div>
              </div>

              <!-- User Data Section -->
              <div class="mt-6 border-t pt-4">
                <div class="mb-4">
                  <label class="flex items-center">
                    <input 
                      type="checkbox" 
                      name="create_user" 
                      value="true"
                      checked={@create_user}
                      phx-click="toggle_create_user"
                      class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50" />
                    <span class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300">Crear usuario para este especialista</span>
                  </label>
                  <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                    Esto permitirá al especialista acceder al sistema con email y contraseña
                  </p>
                </div>

                <%= if @create_user do %>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Email del Usuario *
                      </label>
                      <input 
                        type="email" 
                        name="user[email]" 
                        required
                        placeholder="especialista@clinica.com"
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                    </div>

                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Contraseña *
                      </label>
                      <input 
                        type="password" 
                        name="user[password]" 
                        required
                        minlength="6"
                        placeholder="Mínimo 6 caracteres"
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                    </div>
                  </div>
                <% end %>
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
                  Guardar Especialista
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
                <%= if @delete_target.type == "company", do: "Eliminar Doctor", else: "Eliminar Especialista" %>
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
              <%= if @delete_target.type == "company", do: "¿Estás seguro de que quieres eliminar este doctor?", else: "¿Estás seguro de que quieres eliminar este especialista?" %>
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
  defp status_color("vacation"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp status_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp status_label("active"), do: "Activo"
  defp status_label("inactive"), do: "Inactivo"
  defp status_label("prospect"), do: "Prospecto"
  defp status_label("vacation"), do: "Vacaciones"
  defp status_label(_), do: "Desconocido"
end 