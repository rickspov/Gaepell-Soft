defmodule EvaaCrmWebGaepell.AnalyticsLive do
  use EvaaCrmWebGaepell, :live_view
  import Ecto.Query
  alias EvaaCrmGaepell.Repo
  alias EvaaCrmGaepell.{Contact, Activity, Service, Specialist, Company}

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    today = Date.utc_today()
    start_date = Date.add(today, -30)
    end_date = today

    socket = assign(socket, 
      page_title: "Analytics",
      start_date: start_date,
      end_date: end_date,
      selected_doctor: nil,
      selected_specialist: nil,
      selected_service: nil,
      period_filter: "30d",
      active_tab: "overview",
      current_user: current_user
    )

    socket = load_analytics_data(socket)
    {:ok, socket}
  end

  def handle_event("filter", %{"start_date" => start_date, "end_date" => end_date} = params, socket) do
    socket = assign(socket,
      start_date: Date.from_iso8601!(start_date),
      end_date: Date.from_iso8601!(end_date),
      selected_doctor: parse_id(params["doctor_id"]),
      selected_specialist: parse_id(params["specialist_id"]),
      selected_service: parse_id(params["service_id"]),
      period_filter: params["period_filter"] || "30d"
    )
    
    socket = load_analytics_data(socket)
    {:noreply, socket}
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("quick_period", %{"period" => period}, socket) do
    today = Date.utc_today()
    {start_date, end_date} = case period do
      "7d" -> {Date.add(today, -7), today}
      "30d" -> {Date.add(today, -30), today}
      "90d" -> {Date.add(today, -90), today}
      "1y" -> {Date.add(today, -365), today}
      _ -> {Date.add(today, -30), today}
    end

    socket = assign(socket,
      start_date: start_date,
      end_date: end_date,
      period_filter: period
    )
    
    socket = load_analytics_data(socket)
    {:noreply, socket}
  end

  defp load_analytics_data(socket) do
    socket
    |> load_kpis
    |> load_chart_data
    |> load_specialist_analysis
    |> load_trend_data
    |> load_doctors
    |> load_specialists
    |> load_services
  end

  defp load_kpis(socket) do
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    
    # Aplicar filtros adicionales
    base_activity_query = from a in Activity,
                          where: fragment("DATE(?)", a.due_date) >= ^start_date and 
                                 fragment("DATE(?)", a.due_date) <= ^end_date
    
    base_activity_query = if socket.assigns.selected_doctor do
      from a in base_activity_query, where: a.company_id == ^socket.assigns.selected_doctor
    else
      base_activity_query
    end
    
    base_activity_query = if socket.assigns.selected_specialist do
      from a in base_activity_query, where: a.specialist_id == ^socket.assigns.selected_specialist
    else
      base_activity_query
    end
    
    base_activity_query = if socket.assigns.selected_service do
      from a in base_activity_query, where: a.service_id == ^socket.assigns.selected_service
    else
      base_activity_query
    end
    
    # Total pacientes
    total_patients = from c in Contact,
                    where: c.business_id == 1,
                    select: count(c.id)
    
    # Citas en período
    activities_in_period = from a in base_activity_query,
                          select: count(a.id)
    
    # Citas completadas
    completed_activities = from a in base_activity_query,
                          where: a.status == "completed",
                          select: count(a.id)
    
    # Ingresos estimados
    estimated_revenue = from a in base_activity_query,
                       join: s in Service, on: a.service_id == s.id,
                       where: a.status == "completed",
                       select: sum(s.price)
    
    # Calcular tasas
    total_activities = Repo.one(activities_in_period) || 0
    completed_count = Repo.one(completed_activities) || 0
    completion_rate = if total_activities > 0, do: Float.round(completed_count / total_activities * 100, 1), else: 0.0
    
    avg_revenue_per_activity = if total_activities > 0, do: (Repo.one(estimated_revenue) || 0) / total_activities, else: 0
    
    kpis = %{
      total_patients: Repo.one(total_patients) || 0,
      activities_in_period: total_activities,
      completed_activities: completed_count,
      estimated_revenue: Repo.one(estimated_revenue) || 0,
      completion_rate: completion_rate,
      avg_revenue_per_activity: avg_revenue_per_activity
    }
    
    assign(socket, :kpis, kpis)
  end

  defp load_chart_data(socket) do
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    
    # Aplicar filtros base
    base_query = from a in Activity,
                 where: fragment("DATE(?)", a.due_date) >= ^start_date and 
                        fragment("DATE(?)", a.due_date) <= ^end_date
    
    base_query = if socket.assigns.selected_doctor do
      from a in base_query, where: a.company_id == ^socket.assigns.selected_doctor
    else
      base_query
    end
    
    base_query = if socket.assigns.selected_specialist do
      from a in base_query, where: a.specialist_id == ^socket.assigns.selected_specialist
    else
      base_query
    end
    
    base_query = if socket.assigns.selected_service do
      from a in base_query, where: a.service_id == ^socket.assigns.selected_service
    else
      base_query
    end
    
    # Citas por día
    activities_by_day = from a in base_query,
                        group_by: fragment("DATE(?)", a.due_date),
                        order_by: fragment("DATE(?)", a.due_date),
                        select: {fragment("DATE(?)", a.due_date), count(a.id)}
    
    # Ingresos por servicio
    revenue_by_service = from a in base_query,
                        join: s in Service, on: a.service_id == s.id,
                        where: a.status == "completed",
                        group_by: s.name,
                        order_by: [desc: sum(s.price)],
                        select: {s.name, sum(s.price)}
    
    # Citas por especialista
    activities_by_specialist = from a in base_query,
                              join: s in Specialist, on: a.specialist_id == s.id,
                              group_by: fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name),
                              order_by: [desc: count(a.id)],
                              select: {fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name), count(a.id)}
    
    chart_data = %{
      activities_by_day: Repo.all(activities_by_day),
      revenue_by_service: Repo.all(revenue_by_service),
      activities_by_specialist: Repo.all(activities_by_specialist)
    }
    
    assign(socket, :chart_data, chart_data)
  end

  defp load_specialist_analysis(socket) do
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    
    # Análisis detallado por especialista
    specialist_stats = from a in Activity,
                      join: s in Specialist, on: a.specialist_id == s.id,
                      where: fragment("DATE(?)", a.due_date) >= ^start_date and 
                             fragment("DATE(?)", a.due_date) <= ^end_date,
                      group_by: [s.id, fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name)],
                      select: {
                        s.id,
                        fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name),
                        count(a.id),
                        sum(fragment("CASE WHEN ? = 'completed' THEN 1 ELSE 0 END", a.status))
                      }
    
    specialist_revenue = from a in Activity,
                        join: s in Specialist, on: a.specialist_id == s.id,
                        join: sv in Service, on: a.service_id == sv.id,
                        where: fragment("DATE(?)", a.due_date) >= ^start_date and 
                               fragment("DATE(?)", a.due_date) <= ^end_date and
                               a.status == "completed",
                        group_by: [s.id, fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name)],
                        select: {
                          s.id,
                          fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name),
                          sum(sv.price)
                        }
    
    stats = Repo.all(specialist_stats)
    revenue = Repo.all(specialist_revenue)
    
    # Combinar estadísticas y ingresos
    specialist_analysis = Enum.map(stats, fn {id, name, total, completed} ->
      revenue_amount = Enum.find_value(revenue, 0, fn {r_id, _, amount} -> 
        if r_id == id, do: amount, else: nil
      end)
      
      completion_rate = if total > 0, do: Float.round(completed / total * 100, 1), else: 0.0
      
      %{
        id: id,
        name: name,
        total_activities: total,
        completed_activities: completed,
        completion_rate: completion_rate,
        revenue: revenue_amount
      }
    end)
    
    assign(socket, :specialist_analysis, specialist_analysis)
  end

  defp load_trend_data(socket) do
    # Datos para gráficos de tendencias (últimos 12 meses)
    end_date = socket.assigns.end_date
    start_date = Date.add(end_date, -365)
    
    # Citas por mes
    activities_by_month = from a in Activity,
                          where: fragment("DATE(?)", a.due_date) >= ^start_date and 
                                 fragment("DATE(?)", a.due_date) <= ^end_date,
                          group_by: fragment("DATE_TRUNC('month', ?)", a.due_date),
                          order_by: fragment("DATE_TRUNC('month', ?)", a.due_date),
                          select: {fragment("DATE_TRUNC('month', ?)", a.due_date), count(a.id)}
    
    # Ingresos por mes
    revenue_by_month = from a in Activity,
                       join: s in Service, on: a.service_id == s.id,
                       where: fragment("DATE(?)", a.due_date) >= ^start_date and 
                              fragment("DATE(?)", a.due_date) <= ^end_date and
                              a.status == "completed",
                       group_by: fragment("DATE_TRUNC('month', ?)", a.due_date),
                       order_by: fragment("DATE_TRUNC('month', ?)", a.due_date),
                       select: {fragment("DATE_TRUNC('month', ?)", a.due_date), sum(s.price)}
    
    trend_data = %{
      activities_by_month: Repo.all(activities_by_month),
      revenue_by_month: Repo.all(revenue_by_month)
    }
    
    assign(socket, :trend_data, trend_data)
  end

  defp load_doctors(socket) do
    doctors = from c in Company,
              where: c.business_id == 1,
              order_by: c.name,
              select: {c.name, c.id}
    
    assign(socket, :doctors, Repo.all(doctors))
  end

  defp load_specialists(socket) do
    specialists = from s in Specialist,
                  where: s.business_id == 1,
                  order_by: [s.first_name, s.last_name],
                  select: {fragment("CONCAT(?, ' ', ?)", s.first_name, s.last_name), s.id}
    
    assign(socket, :specialists, Repo.all(specialists))
  end

  defp load_services(socket) do
    services = from s in Service,
               where: s.business_id == 1,
               order_by: s.name,
               select: {s.name, s.id}
    
    assign(socket, :services, Repo.all(services))
  end

  defp format_currency(amount) when is_number(amount) do
    :erlang.float_to_binary(amount / 1, [decimals: 0])
  end
  defp format_currency(_), do: "0"

  defp format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  defp format_month(date) do
    Calendar.strftime(date, "%b %Y")
  end

  defp parse_id(nil), do: nil
  defp parse_id(""), do: nil
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id), do: id

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Analytics</h1>
          <p class="text-gray-600 dark:text-gray-400 mt-1">Métricas y análisis de rendimiento</p>
        </div>
      </div>

      <!-- Filtros Avanzados -->
      <div class="bg-white dark:bg-gray-800 shadow rounded-lg mb-6">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">Filtros</h3>
        </div>
        <div class="p-6">
          <!-- Quick Period Filters -->
          <div class="flex space-x-2 mb-4">
            <button phx-click="quick_period" phx-value-period="7d" class={"px-3 py-1 rounded text-sm font-medium #{if @period_filter == "7d", do: "bg-blue-600 text-white", else: "bg-gray-200 text-gray-700 hover:bg-gray-300"}"}>
              7 días
            </button>
            <button phx-click="quick_period" phx-value-period="30d" class={"px-3 py-1 rounded text-sm font-medium #{if @period_filter == "30d", do: "bg-blue-600 text-white", else: "bg-gray-200 text-gray-700 hover:bg-gray-300"}"}>
              30 días
            </button>
            <button phx-click="quick_period" phx-value-period="90d" class={"px-3 py-1 rounded text-sm font-medium #{if @period_filter == "90d", do: "bg-blue-600 text-white", else: "bg-gray-200 text-gray-700 hover:bg-gray-300"}"}>
              90 días
            </button>
            <button phx-click="quick_period" phx-value-period="1y" class={"px-3 py-1 rounded text-sm font-medium #{if @period_filter == "1y", do: "bg-blue-600 text-white", else: "bg-gray-200 text-gray-700 hover:bg-gray-300"}"}>
              1 año
            </button>
          </div>

          <form phx-change="filter" class="grid grid-cols-1 md:grid-cols-5 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Fecha Inicio</label>
              <input type="date" name="start_date" value={@start_date} class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Fecha Fin</label>
              <input type="date" name="end_date" value={@end_date} class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Doctor</label>
              <select name="doctor_id" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                <option value="">Todos</option>
                <%= for {name, id} <- @doctors do %>
                  <option value={id} selected={@selected_doctor == id}><%= name %></option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Especialista</label>
              <select name="specialist_id" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                <option value="">Todos</option>
                <%= for {name, id} <- @specialists do %>
                  <option value={id} selected={@selected_specialist == id}><%= name %></option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Servicio</label>
              <select name="service_id" class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                <option value="">Todos</option>
                <%= for {name, id} <- @services do %>
                  <option value={id} selected={@selected_service == id}><%= name %></option>
                <% end %>
              </select>
            </div>
          </form>
        </div>
      </div>

      <!-- Tabs -->
      <div class="bg-white dark:bg-gray-800 shadow rounded-lg mb-6">
        <div class="border-b border-gray-200 dark:border-gray-700">
          <nav class="flex space-x-8 px-6">
            <button phx-click="change_tab" phx-value-tab="overview" class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "overview", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}>
              Resumen
            </button>
            <button phx-click="change_tab" phx-value-tab="specialists" class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "specialists", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}>
              Especialistas
            </button>
            <button phx-click="change_tab" phx-value-tab="trends" class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "trends", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}>
              Tendencias
            </button>
            <button phx-click="change_tab" phx-value-tab="charts" class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "charts", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}>
              Gráficos
            </button>
          </nav>
        </div>

        <div class="p-6">
          <%= case @active_tab do %>
            <% "overview" -> %>
              <!-- Overview Tab -->
              <div>
                <!-- KPIs Grid -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
                  <div class="bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg p-6 text-white">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                        </svg>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium opacity-90">Total Pacientes</p>
                        <p class="text-2xl font-bold"><%= @kpis.total_patients %></p>
                      </div>
                    </div>
                  </div>

                  <div class="bg-gradient-to-r from-green-500 to-green-600 rounded-lg p-6 text-white">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                        </svg>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium opacity-90">Citas en Período</p>
                        <p class="text-2xl font-bold"><%= @kpis.activities_in_period %></p>
                      </div>
                    </div>
                  </div>

                  <div class="bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg p-6 text-white">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium opacity-90">Completadas</p>
                        <p class="text-2xl font-bold"><%= @kpis.completed_activities %></p>
                      </div>
                    </div>
                  </div>

                  <div class="bg-gradient-to-r from-yellow-500 to-yellow-600 rounded-lg p-6 text-white">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"></path>
                        </svg>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium opacity-90">Ingresos Estimados</p>
                        <p class="text-2xl font-bold">$<%= format_currency(@kpis.estimated_revenue) %></p>
                      </div>
                    </div>
                  </div>

                  <!-- Gauge Chart for Completion Rate -->
                  <div class="bg-gradient-to-r from-indigo-500 to-indigo-600 rounded-lg p-6 text-white">
                    <div class="text-center">
                      <div class="relative inline-flex items-center justify-center w-24 h-24 mb-4">
                        <svg class="w-24 h-24 transform -rotate-90" viewBox="0 0 100 100">
                          <!-- Background circle -->
                          <circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0.2)" stroke-width="8" fill="none"/>
                          <!-- Progress circle -->
                          <circle cx="50" cy="50" r="40" stroke="white" stroke-width="8" fill="none" 
                                  stroke-dasharray="251.2" 
                                  stroke-dashoffset={251.2 - (251.2 * @kpis.completion_rate / 100)}/>
                        </svg>
                        <div class="absolute">
                          <span class="text-2xl font-bold"><%= @kpis.completion_rate %>%</span>
                        </div>
                      </div>
                      <p class="text-sm font-medium opacity-90">Tasa de Completación</p>
                    </div>
                  </div>

                  <!-- Gauge Chart for Average Revenue -->
                  <div class="bg-gradient-to-r from-pink-500 to-pink-600 rounded-lg p-6 text-white">
                    <div class="text-center">
                      <div class="relative inline-flex items-center justify-center w-24 h-24 mb-4">
                        <svg class="w-24 h-24 transform -rotate-90" viewBox="0 0 100 100">
                          <!-- Background circle -->
                          <circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0.2)" stroke-width="8" fill="none"/>
                          <!-- Progress circle -->
                          <circle cx="50" cy="50" r="40" stroke="white" stroke-width="8" fill="none" 
                                  stroke-dasharray="251.2" 
                                  stroke-dashoffset={251.2 - (251.2 * min(@kpis.avg_revenue_per_activity / 1000 * 100, 100) / 100)}/>
                        </svg>
                        <div class="absolute">
                          <span class="text-lg font-bold">$<%= format_currency(@kpis.avg_revenue_per_activity) %></span>
                        </div>
                      </div>
                      <p class="text-sm font-medium opacity-90">Promedio por Cita</p>
                    </div>
                  </div>
                </div>
              </div>

            <% "specialists" -> %>
              <!-- Specialists Analysis Tab -->
              <div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">Análisis por Especialista</h3>
                
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <!-- Specialist Performance Table -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h4 class="text-lg font-medium text-gray-900 dark:text-white">Rendimiento por Especialista</h4>
                    </div>
                    <div class="overflow-x-auto">
                      <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead class="bg-gray-50 dark:bg-gray-700">
                          <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Especialista</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Citas</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Completadas</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Tasa</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Ingresos</th>
                          </tr>
                        </thead>
                        <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                          <%= for specialist <- @specialist_analysis do %>
                            <tr>
                              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                                <%= specialist.name %>
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                <%= specialist.total_activities %>
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                <%= specialist.completed_activities %>
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                <span class={"px-2 py-1 text-xs font-medium rounded-full #{if(specialist.completion_rate >= 80, do: "bg-green-100 text-green-800", else: if(specialist.completion_rate >= 60, do: "bg-yellow-100 text-yellow-800", else: "bg-red-100 text-red-800"))}"}>
                                  <%= specialist.completion_rate %>%
                                </span>
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                $<%= format_currency(specialist.revenue) %>
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                  </div>

                  <!-- Specialist Gauge Charts -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h4 class="text-lg font-medium text-gray-900 dark:text-white">Tasas de Completación</h4>
                    </div>
                    <div class="p-6">
                      <div class="space-y-6">
                        <%= for specialist <- @specialist_analysis do %>
                          <div class="flex items-center justify-between">
                            <div class="flex-1">
                              <p class="text-sm font-medium text-gray-900 dark:text-white"><%= specialist.name %></p>
                              <div class="flex items-center space-x-2 mt-1">
                                <div class="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                  <div class={"h-2 rounded-full #{if(specialist.completion_rate >= 80, do: "bg-green-600", else: if(specialist.completion_rate >= 60, do: "bg-yellow-600", else: "bg-red-600"))}"} 
                                       style={"width: #{specialist.completion_rate}%"}>
                                  </div>
                                </div>
                                <span class="text-sm text-gray-500 dark:text-gray-400 w-12 text-right">
                                  <%= specialist.completion_rate %>%
                                </span>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

            <% "trends" -> %>
              <!-- Trends Tab -->
              <div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">Tendencias Temporales</h3>
                
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <!-- Citas por Mes -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h4 class="text-lg font-medium text-gray-900 dark:text-white">Citas por Mes (Último Año)</h4>
                    </div>
                    <div class="p-6">
                      <div class="h-64 flex items-end justify-between space-x-1">
                        <%= for {date, count} <- @trend_data.activities_by_month do %>
                          <div class="flex flex-col items-center">
                            <div class="w-6 bg-blue-500 rounded-t" style={"height: #{max(count * 2, 4)}px"}></div>
                            <span class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                              <%= format_month(date) %>
                            </span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <!-- Ingresos por Mes -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h4 class="text-lg font-medium text-gray-900 dark:text-white">Ingresos por Mes (Último Año)</h4>
                    </div>
                    <div class="p-6">
                      <div class="h-64 flex items-end justify-between space-x-1">
                        <%= for {date, revenue} <- @trend_data.revenue_by_month do %>
                          <div class="flex flex-col items-center">
                            <div class="w-6 bg-green-500 rounded-t" style={"height: #{max(revenue / 1000, 4)}px"}></div>
                            <span class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                              <%= format_month(date) %>
                            </span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

            <% "charts" -> %>
              <!-- Charts Tab -->
              <div>
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <!-- Citas por día -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h3 class="text-lg font-medium text-gray-900 dark:text-white">Citas por Día</h3>
                    </div>
                    <div class="p-6">
                      <div class="h-64 flex items-end justify-between space-x-1">
                        <%= for {date, count} <- @chart_data.activities_by_day do %>
                          <div class="flex flex-col items-center">
                            <div class="w-8 bg-blue-500 rounded-t" style={"height: #{max(count * 10, 4)}px"}></div>
                            <span class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                              <%= format_date(date) %>
                            </span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <!-- Ingresos por servicio -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h3 class="text-lg font-medium text-gray-900 dark:text-white">Ingresos por Servicio</h3>
                    </div>
                    <div class="p-6">
                      <div class="space-y-4">
                        <%= for {service_name, revenue} <- @chart_data.revenue_by_service do %>
                          <div class="flex items-center justify-between">
                            <span class="text-sm font-medium text-gray-900 dark:text-white"><%= service_name %></span>
                            <div class="flex items-center space-x-2">
                              <div class="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                <div class="bg-green-600 h-2 rounded-full" style={"width: #{min(revenue / 1000 * 100, 100)}%"}>
                                </div>
                              </div>
                              <span class="text-sm text-gray-500 dark:text-gray-400">$<%= format_currency(revenue) %></span>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <!-- Citas por especialista -->
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                      <h3 class="text-lg font-medium text-gray-900 dark:text-white">Citas por Especialista</h3>
                    </div>
                    <div class="p-6">
                      <div class="space-y-4">
                        <%= for {specialist_name, count} <- @chart_data.activities_by_specialist do %>
                          <div class="flex items-center justify-between">
                            <span class="text-sm font-medium text-gray-900 dark:text-white"><%= specialist_name %></span>
                            <div class="flex items-center space-x-2">
                              <div class="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                <div class="bg-purple-600 h-2 rounded-full" style={"width: #{min(count * 10, 100)}%"}>
                                </div>
                              </div>
                              <span class="text-sm text-gray-500 dark:text-gray-400"><%= count %></span>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
 