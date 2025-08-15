defmodule EvaaCrmWebGaepell.SpecialistsLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Activity, Contact, Company, User, Repo, Service, Specialist}
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    
    {:ok, 
     socket
     |> assign(:page_title, "Especialistas - Horarios")
     |> assign(:activities, [])
     |> assign(:specialists, [])
     |> assign(:current_date, today)
     |> assign(:selected_date, today)
     |> assign(:view_mode, "day")
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> load_activities()
     |> load_specialists()}
  end

  @impl true
  def handle_event("change_date", %{"date" => date}, socket) do
    selected_date = Date.from_iso8601!(date)
    {:noreply, 
     socket
     |> assign(:selected_date, selected_date)
     |> load_activities()}
  end

  @impl true
  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, 
     socket
     |> assign(:view_mode, view)
     |> load_activities()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_status, status)
     |> load_activities()}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, 
     socket
     |> assign(:search_query, query)
     |> load_activities()}
  end

  defp load_activities(socket) do
    query = from a in Activity,
            where: a.business_id == 1,
            preload: [:contact, :company, :user, :service, :specialist],
            order_by: [asc: a.due_date]

    # Aplicar filtros de estado
    query = case socket.assigns.filter_status do
      "all" -> query
      status -> from a in query, where: a.status == ^status
    end

    # Aplicar filtro de búsqueda
    query = case socket.assigns.search_query do
      "" -> query
      search_query ->
        search_pattern = "%#{search_query}%"
        from a in query,
        left_join: c in assoc(a, :contact),
        left_join: s in assoc(a, :service),
        where: ilike(a.title, ^search_pattern) or
               ilike(fragment("? || ' ' || ?", c.first_name, c.last_name), ^search_pattern) or
               ilike(s.name, ^search_pattern)
    end

    # Cargar todas las actividades filtradas
    activities = Repo.all(query)
    assign(socket, :activities, activities)
  end

  defp load_specialists(socket) do
    specialists = Repo.all(from s in Specialist, 
                          where: s.business_id == 1 and s.is_active == true,
                          order_by: [asc: s.first_name, asc: s.last_name])
    assign(socket, :specialists, specialists)
  end

  defp get_activities_for_specialist_and_hour(activities, specialist_id, hour) do
    Enum.filter(activities, fn activity ->
      activity.specialist_id == specialist_id &&
      activity.due_date &&
      (activity.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour
    end)
  end

  defp get_activities_for_specialist_and_date(activities, specialist_id, date) do
    Enum.filter(activities, fn activity ->
      activity.specialist_id == specialist_id &&
      activity.due_date &&
      Date.compare(DateTime.to_date(activity.due_date), date) == :eq
    end)
  end

  defp activity_color(type) do
    case type do
      "service" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "meeting" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "call" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "email" -> "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
      "task" -> "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
      "note" -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

  defp status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "in_progress" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "completed" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

  defp status_text(status) do
    case status do
      "pending" -> "Pendiente"
      "in_progress" -> "En progreso"
      "completed" -> "Completado"
      "cancelled" -> "Cancelado"
      _ -> "Desconocido"
    end
  end

  defp build_activity_tooltip(activity) do
    parts = ["📅 #{activity.title}"]

    parts =
      if activity.due_date do
        date_str = Calendar.strftime(DateTime.to_date(activity.due_date), "%d/%m/%Y")
        time_str = Calendar.strftime(activity.due_date, "%H:%M")
        parts ++ ["🕐 #{date_str} a las #{time_str}"]
      else
        parts
      end

    parts =
      if activity.contact do
        patient_name = EvaaCrmGaepell.Contact.full_name(activity.contact)
        parts = parts ++ ["👤 Paciente: #{patient_name}"]
        parts = if activity.contact.email, do: parts ++ ["📧 #{activity.contact.email}"], else: parts
        parts = if activity.contact.phone, do: parts ++ ["📞 #{activity.contact.phone}"], else: parts
        parts
      else
        parts
      end

    parts =
      if activity.service do
        parts = parts ++ ["💼 Servicio: #{activity.service.name}", "💰 Precio: $#{activity.service.price}"]
        parts = if activity.service.duration_minutes, do: parts ++ ["⏱️ Duración: #{activity.service.duration_minutes} min"], else: parts
        parts
      else
        parts
      end

    parts =
      if activity.company do
        parts ++ ["👨‍⚕️ Doctor: #{activity.company.name}"]
      else
        parts
      end

    parts = parts ++ ["📊 Estado: #{status_text(activity.status)}"]

    parts =
      if activity.description && activity.description != "" do
        parts ++ ["📝 #{activity.description}"]
      else
        parts
      end

    Enum.join(parts, "\n")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Especialistas</h1>
          <p class="text-gray-600 dark:text-gray-400 mt-1">Horarios y disponibilidad por especialista</p>
        </div>
      </div>

      <!-- Calendar Controls -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <div class="flex flex-col md:flex-row gap-4 items-center justify-between">
          <!-- Date Navigation -->
          <div class="flex items-center space-x-2">
            <button 
              phx-click="change_date" 
              phx-value-date={Date.add(@selected_date, -1) |> Date.to_string()}
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
              </svg>
            </button>
            
            <input 
              type="date" 
              value={Date.to_string(@selected_date)}
              phx-change="change_date"
              class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
            
            <button 
              phx-click="change_date" 
              phx-value-date={Date.add(@selected_date, 1) |> Date.to_string()}
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
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

          <!-- Filters -->
          <div class="flex space-x-2">
            <select 
              phx-change="filter_status" 
              name="status"
              class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <option value="all">Todos los estados</option>
              <option value="pending">Pendiente</option>
              <option value="in_progress">En progreso</option>
              <option value="completed">Completado</option>
              <option value="cancelled">Cancelado</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Specialists Schedule View -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <%= case @view_mode do %>
          <% "day" -> %>
            <%= render_day_view(assigns) %>
          <% "week" -> %>
            <%= render_week_view(assigns) %>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_day_view(assigns) do
    grid_columns = "80px " <> String.duplicate("1fr ", length(assigns.specialists))
    assigns = assign(assigns, :grid_columns, grid_columns)
    
    ~H"""
    <div class="p-6">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
        <%= Calendar.strftime(@selected_date, "%A, %d de %B de %Y") %>
      </h3>
      
      <div class="overflow-x-auto">
        <div class="grid" style={"grid-template-columns: #{@grid_columns};"}>
          <!-- Time column header -->
          <div class="text-sm font-medium text-gray-500 dark:text-gray-400 p-2 border-b border-gray-200 dark:border-gray-700">
            Hora
          </div>
          
          <!-- Specialist headers -->
          <%= for specialist <- @specialists do %>
            <div class="text-sm font-medium text-gray-900 dark:text-white p-2 border-b border-gray-200 dark:border-gray-700 text-center">
              <div class="font-semibold"><%= EvaaCrmGaepell.Specialist.full_name(specialist) %></div>
              <div class="text-xs text-gray-500 dark:text-gray-400"><%= specialist.specialization %></div>
            </div>
          <% end %>
          
          <!-- Time slots and activities -->
          <%= for hour <- 8..20 do %>
            <!-- Time label -->
            <div class="text-sm text-gray-500 dark:text-gray-400 p-2 border-b border-gray-200 dark:border-gray-700 flex items-center">
              <%= String.pad_leading("#{hour}:00", 5, "0") %>
            </div>
            
            <!-- Activities for each specialist -->
            <%= for specialist <- @specialists do %>
              <div class="border-b border-gray-200 dark:border-gray-700 p-1 min-h-[60px]">
                <%= for activity <- get_activities_for_specialist_and_hour(@activities, specialist.id, hour) do %>
                  <div class={[
                    "activity-item p-2 rounded-lg mb-1 text-xs cursor-pointer",
                    activity_color(activity.type)
                  ]}
                  title={build_activity_tooltip(activity)}>
                    <div class="font-medium truncate"><%= activity.title %></div>
                    <div class="text-xs opacity-75 truncate">
                      <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp render_week_view(assigns) do
    week_dates = get_week_dates(assigns.selected_date)
    grid_columns = "80px " <> String.duplicate("1fr ", length(assigns.specialists))
    assigns = assign(assigns, :week_dates, week_dates)
    assigns = assign(assigns, :grid_columns, grid_columns)
    
    ~H"""
    <div class="p-6">
      <div class="overflow-x-auto">
        <div class="grid" style={"grid-template-columns: #{@grid_columns};"}>
          <!-- Time column header -->
          <div class="text-sm font-medium text-gray-500 dark:text-gray-400 p-2 border-b border-gray-200 dark:border-gray-700">
            Hora
          </div>
          
          <!-- Specialist headers -->
          <%= for specialist <- @specialists do %>
            <div class="text-sm font-medium text-gray-900 dark:text-white p-2 border-b border-gray-200 dark:border-gray-700 text-center">
              <div class="font-semibold"><%= EvaaCrmGaepell.Specialist.full_name(specialist) %></div>
              <div class="text-xs text-gray-500 dark:text-gray-400"><%= specialist.specialization %></div>
            </div>
          <% end %>
          
          <!-- Time slots and activities -->
          <%= for hour <- 8..20 do %>
            <!-- Time label -->
            <div class="text-sm text-gray-500 dark:text-gray-400 p-2 border-b border-gray-200 dark:border-gray-700 flex items-center">
              <%= String.pad_leading("#{hour}:00", 5, "0") %>
            </div>
            
            <!-- Activities for each specialist -->
            <%= for specialist <- @specialists do %>
              <div class="border-b border-gray-200 dark:border-gray-700 p-1 min-h-[60px]">
                <%= for date <- @week_dates do %>
                  <%= for activity <- get_activities_for_specialist_and_date(@activities, specialist.id, date) do %>
                    <%= if (activity.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour do %>
                      <div class={[
                        "activity-item p-1 rounded mb-1 text-xs cursor-pointer",
                        activity_color(activity.type)
                      ]}
                      title={build_activity_tooltip(activity)}>
                        <div class="font-medium truncate"><%= activity.title %></div>
                        <div class="text-xs opacity-75 truncate">
                          <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp get_week_dates(date) do
    week_start = Date.beginning_of_week(date, :monday)
    for i <- 0..6 do
      Date.add(week_start, i)
    end
  end
end 