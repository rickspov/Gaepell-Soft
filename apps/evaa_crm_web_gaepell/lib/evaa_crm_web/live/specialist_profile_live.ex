defmodule EvaaCrmWebGaepell.SpecialistProfileLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Specialist, Contact, Activity, User, Repo}
  import Ecto.Query

  @impl true
  def mount(params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil
    id = params["id"]
    specialist = Repo.get(Specialist, id)
    
    if specialist do
      today = Date.utc_today()
      
      {:ok, 
       socket
       |> assign(:current_user, current_user)
       |> assign(:page_title, "Perfil del Especialista - #{EvaaCrmGaepell.Specialist.full_name(specialist)}")
       |> assign(:specialist, specialist)
       |> assign(:activities, [])
       |> assign(:patients, [])
       |> assign(:appointments, [])
       |> assign(:current_date, today)
       |> assign(:selected_date, today)
       |> assign(:view_mode, "week")
       |> assign(:active_tab, "overview")
       |> assign(:show_edit_form, false)
       |> assign(:editing_specialist, nil)
       |> assign(:show_credentials_form, false)
       |> assign(:new_user, %User{})
       |> load_specialist_activities()
       |> load_specialist_patients()
       |> load_specialist_appointments()
       |> load_specialist_stats()}
    else
      {:ok, 
       socket
       |> assign(:current_user, current_user)
       |> put_flash(:error, "Especialista no encontrado")
       |> push_navigate(to: "/doctors")}
    end
  end

  @impl true
  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, 
     socket
     |> assign(:view_mode, view)
     |> load_specialist_activities()}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("change_date", %{"date" => date}, socket) do
    selected_date = Date.from_iso8601!(date)
    {:noreply, 
     socket
     |> assign(:selected_date, selected_date)
     |> load_specialist_activities()}
  end

  @impl true
  def handle_event("show_edit_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_edit_form, true)
     |> assign(:editing_specialist, socket.assigns.specialist)}
  end

  @impl true
  def handle_event("hide_edit_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_edit_form, false)
     |> assign(:editing_specialist, nil)}
  end

  @impl true
  def handle_event("update_specialist", %{"specialist" => specialist_params}, socket) do
    case update_specialist(socket.assigns.specialist, specialist_params) do
      {:ok, updated_specialist} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Especialista actualizado exitosamente")
         |> assign(:specialist, updated_specialist)
         |> assign(:show_edit_form, false)
         |> assign(:editing_specialist, nil)}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :editing_specialist, %{socket.assigns.editing_specialist | action: :update, errors: changeset.errors})}
    end
  end

  @impl true
  def handle_event("show_credentials_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_credentials_form, true)
     |> assign(:new_user, %User{})}
  end

  @impl true
  def handle_event("hide_credentials_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_credentials_form, false)
     |> assign(:new_user, %User{})}
  end

  @impl true
  def handle_event("create_credentials", %{"user" => user_params}, socket) do
    case create_user_credentials(user_params) do
      {:ok, _user} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Credenciales creadas exitosamente")
         |> assign(:show_credentials_form, false)
         |> assign(:new_user, %User{})}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :new_user, %{socket.assigns.new_user | action: :insert, errors: changeset.errors})}
    end
  end

  defp load_specialist_activities(socket) do
    query = from a in Activity,
            where: a.specialist_id == ^socket.assigns.specialist.id,
            preload: [:contact, :service, :company],
            order_by: [asc: a.due_date]

    activities = case socket.assigns.view_mode do
      "day" ->
        Enum.filter(Repo.all(query), fn activity ->
          activity.due_date &&
            Date.compare(DateTime.to_date(activity.due_date), socket.assigns.selected_date) == :eq
        end)
      
      "week" ->
        week_start = Date.beginning_of_week(socket.assigns.selected_date, :monday)
        week_end = Date.end_of_week(socket.assigns.selected_date, :monday)
        Enum.filter(Repo.all(query), fn activity ->
          if activity.due_date do
            activity_date = DateTime.to_date(activity.due_date)
            start_compare = Date.compare(activity_date, week_start)
            end_compare = Date.compare(activity_date, week_end)
            start_compare in [:eq, :gt] && end_compare in [:eq, :lt]
          else
            false
          end
        end)
      
      _ -> Repo.all(query)
    end

    assign(socket, :activities, activities)
  end

  defp load_specialist_patients(socket) do
    # Obtener pacientes únicos del especialista
    patients_query = from a in Activity,
                     where: a.specialist_id == ^socket.assigns.specialist.id and not is_nil(a.contact_id),
                     distinct: a.contact_id,
                     preload: [:contact]
    
    patients = Repo.all(patients_query)
    |> Enum.map(fn activity -> activity.contact end)
    |> Enum.sort_by(fn contact -> EvaaCrmGaepell.Contact.full_name(contact) end)
    
    assign(socket, :patients, patients)
  end

  defp load_specialist_appointments(socket) do
    # Obtener todas las citas del especialista (pasadas y futuras)
    appointments_query = from a in Activity,
                        where: a.specialist_id == ^socket.assigns.specialist.id,
                        preload: [:contact, :service, :company],
                        order_by: [desc: a.due_date]
    
    appointments = Repo.all(appointments_query)
    
    assign(socket, :appointments, appointments)
  end

  defp load_specialist_stats(socket) do
    # Estadísticas del especialista
    total_patients = from c in Contact,
                    where: c.specialist_id == ^socket.assigns.specialist.id,
                    select: count(c.id)
    
    total_activities = from a in Activity,
                      where: a.specialist_id == ^socket.assigns.specialist.id,
                      select: count(a.id)
    
    completed_activities = from a in Activity,
                          where: a.specialist_id == ^socket.assigns.specialist.id and a.status == "completed",
                          select: count(a.id)
    
    # Verificar si el especialista tiene credenciales (usuario asociado)
    has_credentials = from u in User,
                     where: u.specialist_id == ^socket.assigns.specialist.id,
                     select: count(u.id)
    
    stats = %{
      total_patients: Repo.one(total_patients) || 0,
      total_activities: Repo.one(total_activities) || 0,
      completed_activities: Repo.one(completed_activities) || 0,
      has_credentials: (Repo.one(has_credentials) || 0) > 0
    }
    
    assign(socket, :stats, stats)
  end

  defp update_specialist(specialist, attrs) do
    specialist
    |> Specialist.changeset(attrs)
    |> Repo.update()
  end

  defp create_user_credentials(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-start">
        <div>
          <div class="flex items-center space-x-4">
            <a href="/doctors" class="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </a>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Perfil del Especialista</h1>
          </div>
          <p class="text-gray-600 dark:text-gray-400 mt-1">Información médica y estadísticas</p>
        </div>
        <div class="flex space-x-3">
          <button 
            phx-click="show_edit_form"
            class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center space-x-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
            </svg>
            <span>Editar Perfil</span>
          </button>
          <button 
            phx-click="show_credentials_form"
            class={[
              "font-bold py-2 px-4 rounded-lg flex items-center space-x-2",
              if @stats.has_credentials do
                "bg-orange-600 hover:bg-orange-700 text-white"
              else
                "bg-green-600 hover:bg-green-700 text-white"
              end
            ]}>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
            </svg>
            <span><%= if @stats.has_credentials, do: "Editar Credenciales", else: "Crear Credenciales" %></span>
          </button>
        </div>
      </div>

      <!-- Specialist Info -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <div class="flex items-start space-x-6">
          <div class="flex-shrink-0">
            <div class="h-20 w-20 rounded-full bg-purple-100 dark:bg-purple-900 flex items-center justify-center">
              <svg class="w-10 h-10 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
              </svg>
            </div>
          </div>
          <div class="flex-1">
            <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
              <%= @specialist.first_name %> <%= @specialist.last_name %>
            </h2>
            <p class="text-gray-600 dark:text-gray-400"><%= @specialist.specialization %></p>
            <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Email</p>
                <p class="text-sm text-gray-900 dark:text-white"><%= @specialist.email %></p>
              </div>
              <div>
                <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Teléfono</p>
                <p class="text-sm text-gray-900 dark:text-white"><%= @specialist.phone %></p>
              </div>
              <div>
                <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Estado</p>
                <span class={[
                  "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                  if @specialist.availability == "available" do
                    "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                  else
                    "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                  end
                ]}>
                  <%= if @specialist.availability == "available", do: "Disponible", else: "No Disponible" %>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                <svg class="w-4 h-4 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Pacientes Totales</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white"><%= @stats.total_patients %></p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                <svg class="w-4 h-4 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Citas Totales</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white"><%= @stats.total_activities %></p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-full bg-yellow-100 dark:bg-yellow-900 flex items-center justify-center">
                <svg class="w-4 h-4 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Completadas</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white"><%= @stats.completed_activities %></p>
            </div>
          </div>
        </div>
      </div>

      <!-- Agenda -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <!-- Tabs -->
        <div class="border-b border-gray-200 dark:border-gray-700">
          <nav class="-mb-px flex space-x-8 px-6" aria-label="Tabs">
            <button 
              phx-click="change_tab" 
              phx-value-tab="agenda"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                if @active_tab == "agenda" do
                  "border-blue-500 text-blue-600 dark:text-blue-400"
                else
                  "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300"
                end
              ]}>
              <div class="flex items-center space-x-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                </svg>
                <span>Agenda</span>
              </div>
            </button>
            
            <button 
              phx-click="change_tab" 
              phx-value-tab="patients"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                if @active_tab == "patients" do
                  "border-blue-500 text-blue-600 dark:text-blue-400"
                else
                  "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300"
                end
              ]}>
              <div class="flex items-center space-x-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                </svg>
                <span>Pacientes (<%= length(@patients) %>)</span>
              </div>
            </button>
            
            <button 
              phx-click="change_tab" 
              phx-value-tab="appointments"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                if @active_tab == "appointments" do
                  "border-blue-500 text-blue-600 dark:text-blue-400"
                else
                  "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300"
                end
              ]}>
              <div class="flex items-center space-x-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                </svg>
                <span>Citas (<%= length(@appointments) %>)</span>
              </div>
            </button>
          </nav>
        </div>

        <!-- Tab Content -->
        <div class="p-6">
          <%= case @active_tab do %>
            <% "overview" -> %>
              <!-- Overview Tab -->
              <div>
                <div class="flex justify-between items-center mb-4">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">Resumen del Especialista</h3>
                </div>

                <!-- Stats Grid -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <div class="h-8 w-8 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                          <svg class="w-4 h-4 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                          </svg>
                        </div>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Pacientes</p>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white"><%= @stats.total_patients %></p>
                      </div>
                    </div>
                  </div>

                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <div class="h-8 w-8 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                          <svg class="w-4 h-4 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                          </svg>
                        </div>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Citas Totales</p>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white"><%= @stats.total_activities %></p>
                      </div>
                    </div>
                  </div>

                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <div class="h-8 w-8 rounded-full bg-yellow-100 dark:bg-yellow-900 flex items-center justify-center">
                          <svg class="w-4 h-4 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                          </svg>
                        </div>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Completadas</p>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white"><%= @stats.completed_activities %></p>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Specialist Info -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                  <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Información del Especialista</h4>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Nombre</p>
                      <p class="text-sm text-gray-900 dark:text-white"><%= EvaaCrmGaepell.Specialist.full_name(@specialist) %></p>
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Especialidad</p>
                      <p class="text-sm text-gray-900 dark:text-white"><%= @specialist.specialization %></p>
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Email</p>
                      <p class="text-sm text-gray-900 dark:text-white"><%= @specialist.email %></p>
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Teléfono</p>
                      <p class="text-sm text-gray-900 dark:text-white"><%= @specialist.phone %></p>
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Estado</p>
                      <span class={[
                        "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                        if @specialist.status == "active" do
                          "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                        else
                          "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                        end
                      ]}>
                        <%= String.capitalize(@specialist.status) %>
                      </span>
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Disponibilidad</p>
                      <span class={[
                        "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                        case @specialist.availability do
                          "available" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                          "busy" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
                          "unavailable" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                          _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
                        end
                      ]}>
                        <%= case @specialist.availability do
                          "available" -> "Disponible"
                          "busy" -> "Ocupado"
                          "unavailable" -> "No Disponible"
                          _ -> "No Definido"
                        end %>
                      </span>
                    </div>
                  </div>
                </div>
              </div>

            <% "agenda" -> %>
              <!-- Agenda Tab -->
              <div>
                <div class="flex justify-between items-center mb-4">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">Agenda del Especialista</h3>
                  <div class="flex items-center space-x-4">
                    <!-- Date Navigation -->
                    <div class="flex items-center space-x-2">
                      <button 
                        phx-click="change_date" 
                        phx-value-date={Date.add(@selected_date, -1) |> Date.to_string()}
                        class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                        </svg>
                      </button>
                      <span class="text-sm font-medium text-gray-900 dark:text-white">
                        <%= Calendar.strftime(@selected_date, "%d/%m/%Y") %>
                      </span>
                      <button 
                        phx-click="change_date" 
                        phx-value-date={Date.add(@selected_date, 1) |> Date.to_string()}
                        class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                        </svg>
                      </button>
                    </div>

                    <!-- View Mode Toggle -->
                    <div class="flex bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
                      <button 
                        phx-click="change_view" 
                        phx-value-view="day"
                        class={[
                          "px-3 py-1 text-sm font-medium rounded-md transition-colors",
                          if @view_mode == "day" do
                            "bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm"
                          else
                            "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                          end
                        ]}>
                        Día
                      </button>
                      <button 
                        phx-click="change_view" 
                        phx-value-view="week"
                        class={[
                          "px-3 py-1 text-sm font-medium rounded-md transition-colors",
                          if @view_mode == "week" do
                            "bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm"
                          else
                            "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                          end
                        ]}>
                        Semana
                      </button>
                    </div>
                  </div>
                </div>

                <%= if @view_mode == "day" do %>
                  <!-- Day View -->
                  <div class="space-y-4">
                    <%= for hour <- 8..20 do %>
                      <div class="flex border-b border-gray-200 dark:border-gray-700 pb-2">
                        <div class="w-20 text-sm text-gray-500 dark:text-gray-400">
                          <%= String.pad_leading("#{hour}:00", 5, "0") %>
                        </div>
                        <div class="flex-1">
                          <%= for activity <- get_activities_for_hour(@activities, hour) do %>
                            <div class={[
                              "p-2 rounded-lg mb-2 text-sm cursor-pointer",
                              activity_color(activity.type)
                            ]}
                            title={build_activity_tooltip(activity)}>
                              <div class="font-medium"><%= activity.title %></div>
                              <div class="text-xs opacity-75">
                                <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %>
                                <%= if activity.service, do: " • " <> activity.service.name %>
                                <%= if activity.company, do: " • Dr. " <> activity.company.name %>
                              </div>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% else %>
                  <!-- Week View -->
                  <div class="grid grid-cols-7 gap-4">
                    <%= for {date, day_name} <- get_week_dates(@selected_date) do %>
                      <div class="space-y-2">
                        <div class="text-center">
                          <div class="text-sm font-medium text-gray-900 dark:text-white"><%= day_name %></div>
                          <div class="text-sm text-gray-500 dark:text-gray-400"><%= Calendar.strftime(date, "%d/%m") %></div>
                        </div>
                        <div class="space-y-1">
                          <%= for hour <- 8..20 do %>
                            <div class="text-xs text-gray-400 dark:text-gray-500">
                              <%= String.pad_leading("#{hour}:00", 5, "0") %>
                            </div>
                            <div class="min-h-[20px]">
                              <%= for activity <- get_activities_for_date_and_hour(@activities, date, hour) do %>
                                <div class={[
                                  "text-xs p-1 rounded mb-1 truncate cursor-pointer",
                                  activity_color(activity.type)
                                ]}
                                title={build_activity_tooltip(activity)}>
                                  <div class="font-medium"><%= activity.title %></div>
                                  <div class="text-xs opacity-75">
                                    <%= if activity.service, do: activity.service.name %>
                                    <%= if activity.company, do: " • Dr. " <> activity.company.name %>
                                  </div>
                                </div>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

            <% "patients" -> %>
              <!-- Patients Tab -->
              <div>
                <div class="flex justify-between items-center mb-4">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">Pacientes del Especialista</h3>
                  <span class="text-sm text-gray-500 dark:text-gray-400">
                    <%= length(@patients) %> pacientes
                  </span>
                </div>

                <%= if @patients == [] do %>
                  <div class="text-center py-8">
                    <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                    </svg>
                    <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay pacientes</h3>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      Este especialista aún no tiene pacientes asignados.
                    </p>
                  </div>
                <% else %>
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <%= for patient <- @patients do %>
                      <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 border border-gray-200 dark:border-gray-600">
                        <div class="flex items-center space-x-3">
                          <div class="flex-shrink-0">
                            <div class="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                              <span class="text-sm font-medium text-blue-600 dark:text-blue-400">
                                <%= String.first(patient.first_name || "") %><%= String.first(patient.last_name || "") %>
                              </span>
                            </div>
                          </div>
                          <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                              <%= EvaaCrmGaepell.Contact.full_name(patient) %>
                            </p>
                            <p class="text-sm text-gray-500 dark:text-gray-400 truncate">
                              <%= patient.email %>
                            </p>
                            <%= if patient.phone do %>
                              <p class="text-sm text-gray-500 dark:text-gray-400 truncate">
                                <%= patient.phone %>
                              </p>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

            <% "appointments" -> %>
              <!-- Appointments Tab -->
              <div>
                <div class="flex justify-between items-center mb-4">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">Historial de Citas</h3>
                  <span class="text-sm text-gray-500 dark:text-gray-400">
                    <%= length(@appointments) %> citas
                  </span>
                </div>

                <%= if @appointments == [] do %>
                  <div class="text-center py-8">
                    <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                    </svg>
                    <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay citas</h3>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      Este especialista aún no tiene citas programadas.
                    </p>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <%= for appointment <- @appointments do %>
                      <div class={[
                        "border rounded-lg p-4",
                        if appointment.due_date && DateTime.compare(appointment.due_date, DateTime.utc_now()) == :gt do
                          "border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-900/20"
                        else
                          "border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800"
                        end
                      ]}>
                        <div class="flex justify-between items-start">
                          <div class="flex-1">
                            <h4 class="text-sm font-medium text-gray-900 dark:text-white">
                              <%= appointment.title %>
                            </h4>
                            <div class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                              <%= if appointment.contact do %>
                                <span class="font-medium">Paciente:</span> <%= EvaaCrmGaepell.Contact.full_name(appointment.contact) %>
                              <% end %>
                              <%= if appointment.service do %>
                                <span class="mx-2">•</span>
                                <span class="font-medium">Servicio:</span> <%= appointment.service.name %>
                              <% end %>
                              <%= if appointment.company do %>
                                <span class="mx-2">•</span>
                                <span class="font-medium">Doctor:</span> <%= appointment.company.name %>
                              <% end %>
                            </div>
                            <%= if appointment.due_date do %>
                              <div class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                                <span class="font-medium">Fecha:</span> 
                                <%= Calendar.strftime(DateTime.to_date(appointment.due_date), "%d/%m/%Y") %>
                                <span class="mx-2">•</span>
                                <span class="font-medium">Hora:</span>
                                <%= Calendar.strftime(appointment.due_date, "%H:%M") %>
                              </div>
                            <% end %>
                          </div>
                          <div class="ml-4">
                            <span class={[
                              "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                              if appointment.due_date && DateTime.compare(appointment.due_date, DateTime.utc_now()) == :gt do
                                "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                              else
                                "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
                              end
                            ]}>
                              <%= if appointment.due_date && DateTime.compare(appointment.due_date, DateTime.utc_now()) == :gt do
                                "Próxima"
                              else
                                "Completada"
                              end %>
                            </span>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
          <% end %>
        </div>
      </div>
    </div>

    <!-- Credentials Modal -->
    <%= if @show_credentials_form do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                <%= if @stats.has_credentials, do: "Credenciales de #{EvaaCrmGaepell.Specialist.full_name(@specialist)}", else: "Crear Credenciales para #{EvaaCrmGaepell.Specialist.full_name(@specialist)}" %>
              </h3>
              <button 
                phx-click="hide_credentials_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <%= if @stats.has_credentials do %>
              <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-4">
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-green-600 dark:text-green-400 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  <span class="text-green-800 dark:text-green-200 font-medium">Credenciales ya creadas</span>
                </div>
                <p class="text-green-700 dark:text-green-300 text-sm mt-1">
                  Este especialista ya tiene credenciales de acceso al sistema.
                </p>
              </div>
            <% else %>
              <form phx-submit="create_credentials">
                <div class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Email *
                    </label>
                    <input 
                      type="email" 
                      name="user[email]" 
                      value={@new_user.email || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
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
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Confirmar Contraseña *
                    </label>
                    <input 
                      type="password" 
                      name="user[password_confirmation]" 
                      required
                      minlength="6"
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  </div>
                </div>

                <div class="mt-6 flex justify-end space-x-3">
                  <button 
                    type="button"
                    phx-click="hide_credentials_form"
                    class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                    Cancelar
                  </button>
                  <button 
                    type="submit"
                    class="px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-md hover:bg-green-700">
                    Crear Credenciales
                  </button>
                </div>
              </form>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Edit Modal -->
    <%= if @show_edit_form do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                Editar Perfil de <%= EvaaCrmGaepell.Specialist.full_name(@specialist) %>
              </h3>
              <button 
                phx-click="hide_edit_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="update_specialist">
              <div class="space-y-4">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Nombre *
                    </label>
                    <input 
                      type="text" 
                      name="specialist[first_name]" 
                      value={@editing_specialist.first_name || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Apellido *
                    </label>
                    <input 
                      type="text" 
                      name="specialist[last_name]" 
                      value={@editing_specialist.last_name || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Especialidad *
                  </label>
                  <input 
                    type="text" 
                    name="specialist[specialty]" 
                    value={@editing_specialist.specialty || ""}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Email
                  </label>
                  <input 
                    type="email" 
                    name="specialist[email]" 
                    value={@editing_specialist.email || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Teléfono
                  </label>
                  <input 
                    type="tel" 
                    name="specialist[phone]" 
                    value={@editing_specialist.phone || ""}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Estado
                    </label>
                    <select 
                      name="specialist[status]" 
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                      <option value="active" selected={@editing_specialist.status == "active"}>Activo</option>
                      <option value="inactive" selected={@editing_specialist.status == "inactive"}>Inactivo</option>
                    </select>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Disponibilidad
                    </label>
                    <select 
                      name="specialist[availability]" 
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                      <option value="available" selected={@editing_specialist.availability == "available"}>Disponible</option>
                      <option value="busy" selected={@editing_specialist.availability == "busy"}>Ocupado</option>
                      <option value="unavailable" selected={@editing_specialist.availability == "unavailable"}>No Disponible</option>
                    </select>
                  </div>
                </div>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button 
                  type="button"
                  phx-click="hide_edit_form"
                  class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                  Cancelar
                </button>
                <button 
                  type="submit"
                  class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700">
                  Guardar Cambios
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp get_activities_for_hour(activities, hour) do
    Enum.filter(activities, fn activity ->
      if activity.due_date do
        activity.due_date.hour == hour
      else
        false
      end
    end)
  end

  defp get_activities_for_date_and_hour(activities, date, hour) do
    Enum.filter(activities, fn activity ->
      if activity.due_date do
        activity_date = DateTime.to_date(activity.due_date)
        Date.compare(activity_date, date) == :eq && activity.due_date.hour == hour
      else
        false
      end
    end)
  end

  defp get_week_dates(selected_date) do
    week_start = Date.beginning_of_week(selected_date, :monday)
    Enum.map(0..6, fn day_offset ->
      date = Date.add(week_start, day_offset)
      day_name = Calendar.strftime(date, "%A")
      {date, day_name}
    end)
  end

  defp activity_color("meeting"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp activity_color("call"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp activity_color("email"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp activity_color("task"), do: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
  defp activity_color("note"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  defp activity_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp build_activity_tooltip(activity) do
    date_str = Calendar.strftime(activity.due_date, "%d/%m/%Y")
    time_str = Calendar.strftime(activity.due_date, "%H:%M")
    
    patient_name = if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente"
    
    tooltip_parts = []
    tooltip_parts = tooltip_parts ++ ["🕐 #{date_str} a las #{time_str}"]
    tooltip_parts = tooltip_parts ++ ["👤 Paciente: #{patient_name}"]
    tooltip_parts = tooltip_parts ++ ["💼 Servicio: #{activity.service.name}"]
    tooltip_parts = tooltip_parts ++ ["👨‍⚕️ Doctor: #{activity.company.name}"]
    
    Enum.join(tooltip_parts, "\n")
  end
end 