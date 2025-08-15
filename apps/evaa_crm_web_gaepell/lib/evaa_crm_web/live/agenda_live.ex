defmodule EvaaCrmWebGaepell.AgendaLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Activity, Contact, Company, User, Repo, Service, Specialist, Truck}
  import Ecto.Query
  import Phoenix.HTML.Form
  import EvaaCrmWebGaepell.CoreComponents

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    today = Date.utc_today()
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Agenda - Eventos Gaepell")
     |> assign(:activities, [])
     |> assign(:contacts, [])
     |> assign(:companies, [])
     |> assign(:users, [])
     |> assign(:current_date, today)
     |> assign(:selected_date, today)
     |> assign(:view_mode, "week")
     |> assign(:detail_view, false)
     |> assign(:show_form, false)
     |> assign(:editing_activity, nil)
     |> assign(:filter_type, "all")
     |> assign(:filter_status, "all")
     |> assign(:filter_company, "all")
     |> assign(:search_query, "")
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)
     |> assign(:show_edit_modal, false)
     |> assign(:editing_activity_modal, nil)
     |> assign(:show_filter_dropdown, false)
     |> assign(:drag_mode, false)
     |> assign(:always_show_buttons, false)
     |> assign(:show_ticket_modal, false)
     |> assign(:editing_ticket, nil)
     |> load_activities()
     |> load_contacts()
     |> load_companies()
     |> load_users()
     |> load_services()
     |> load_specialists()
     |> assign(:trucks, EvaaCrmGaepell.Fleet.list_trucks() || [])}
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
  def handle_event("toggle_detail_view", _params, socket) do
    {:noreply, assign(socket, :detail_view, !socket.assigns.detail_view)}
  end

  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_type, type)
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
  def handle_event("filter_company", %{"company" => company}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_company, company)
     |> load_activities()}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, 
     socket
     |> assign(:search_query, query)
     |> load_activities()}
  end

  @impl true
  def handle_event("show_form", %{"activity_id" => activity_id}, socket) do
    activity = if activity_id == "new" do
      %Activity{due_date: DateTime.utc_now()}
    else
      Repo.get(Activity, activity_id)
    end
    
    {:noreply, 
     socket
     |> assign(:show_form, true)
     |> assign(:editing_activity, activity)}
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_form, false)
     |> assign(:editing_activity, nil)}
  end

  @impl true
  def handle_event("save_activity", %{"activity" => activity_params} = params, socket) do
    activity_params = Map.put(activity_params, "business_id", 1)
    
    # Combine date, hour and minutes into due_date
    activity_params = case {activity_params["due_date_date"], activity_params["due_date_hour"], activity_params["due_date_minutes"]} do
      {date_str, hour_str, minutes_str} when not is_nil(date_str) and not is_nil(hour_str) and not is_nil(minutes_str) and date_str != "" and hour_str != "" and minutes_str != "" ->
        case parse_datetime_from_separate_fields(date_str, hour_str, minutes_str) do
          {:ok, datetime} ->
            Map.put(activity_params, "due_date", datetime)
          
          {:error, _} ->
            activity_params
        end
      
      _ ->
        activity_params
    end
    
    # Remove the separate fields
    activity_params = Map.drop(activity_params, ["due_date_date", "due_date_hour", "due_date_minutes"])
    
    # Auto-generate title if service and specialist are present and title is empty
    activity_params = case {activity_params["service_id"], activity_params["specialist_id"], activity_params["title"]} do
      {service_id, specialist_id, title} when not is_nil(service_id) and not is_nil(specialist_id) and (is_nil(title) or title == "") ->
        # Get service and specialist names
        service = Repo.get(Service, service_id)
        specialist = Repo.get(Specialist, specialist_id)
        
        if service && specialist do
          auto_title = "#{service.name} - #{EvaaCrmGaepell.Specialist.full_name(specialist)}"
          Map.put(activity_params, "title", auto_title)
        else
          activity_params
        end
      
      _ ->
        activity_params
    end
    
    if Map.get(params, "create_ticket") == "true" do
      ticket_attrs = Map.get(params, "ticket", %{})
      # Completar los datos obligatorios del ticket
      ticket_attrs = ticket_attrs
        |> Map.put("business_id", 1)
        |> Map.put("title", activity_params["title"] || "Ticket de mantenimiento")
        |> Map.put("entry_date", activity_params["due_date"])
        |> Map.put("status", activity_params["status"] || "open")
        |> Map.put("priority", ticket_attrs["priority"] || activity_params["priority"] || "medium")
      case EvaaCrmGaepell.Fleet.create_maintenance_ticket(ticket_attrs) do
        {:ok, ticket} ->
          activity_params = Map.put(activity_params, "maintenance_ticket_id", ticket.id)
          case save_activity(socket.assigns.editing_activity, activity_params) do
            {:ok, _activity} ->
              {:noreply, 
               socket
               |> put_flash(:info, "Evento y ticket guardados exitosamente")
               |> assign(:show_form, false)
               |> assign(:editing_activity, nil)
               |> load_activities()}
            {:error, changeset} ->
              {:noreply, assign(socket, :editing_activity, %{socket.assigns.editing_activity | action: :insert, errors: changeset.errors})}
          end
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "No se pudo crear el ticket de mantenimiento")}
      end
    else
      case save_activity(socket.assigns.editing_activity, activity_params) do
        {:ok, _activity} ->
          {:noreply, 
           socket
           |> put_flash(:info, "Evento guardado exitosamente")
           |> assign(:show_form, false)
           |> assign(:editing_activity, nil)
           |> load_activities()}
        {:error, changeset} ->
          {:noreply, assign(socket, :editing_activity, %{socket.assigns.editing_activity | action: :insert, errors: changeset.errors})}
      end
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id, "type" => "activity"}, socket) do
    activity = Repo.get(Activity, id)
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, true)
     |> assign(:delete_target, %{id: id, type: "activity", title: activity.title})}
  end

  @impl true
  def handle_event("hide_delete_confirm", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)}
  end

  @impl true
  def handle_event("edit_activity", %{"activity-id" => activity_id}, socket) do
    activity = Repo.get(Activity, activity_id)
    |> Repo.preload(:contact)
    |> Repo.preload(:service)
    |> Repo.preload(:specialist)
    |> Repo.preload(:company)
    
    {:noreply, 
     socket
     |> assign(:show_edit_modal, true)
     |> assign(:editing_activity_modal, activity)}
  end

  @impl true
  def handle_event("hide_edit_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_edit_modal, false)
     |> assign(:editing_activity_modal, nil)}
  end

  @impl true
  def handle_event("update_activity_modal", %{"activity" => activity_params}, socket) do
    activity = socket.assigns.editing_activity_modal
    
    # Combine date and time into due_date
    activity_params = case {activity_params["due_date_date"], activity_params["due_date_time"]} do
      {date_str, time_str} when not is_nil(date_str) and not is_nil(time_str) and date_str != "" and time_str != "" ->
        case parse_datetime(date_str, time_str) do
          {:ok, datetime} ->
            Map.put(activity_params, "due_date", datetime)
          
          {:error, _} ->
            activity_params
        end
      
      _ ->
        activity_params
    end
    
    # Remove the separate date and time fields
    activity_params = Map.drop(activity_params, ["due_date_date", "due_date_time"])
    
    # Auto-generate title if service and specialist are present and title is empty
    activity_params = case {activity_params["service_id"], activity_params["specialist_id"], activity_params["title"]} do
      {service_id, specialist_id, title} when not is_nil(service_id) and not is_nil(specialist_id) and (is_nil(title) or title == "") ->
        service = Repo.get(Service, service_id)
        specialist = Repo.get(Specialist, specialist_id)
        
        if service && specialist do
          auto_title = "#{service.name} - #{EvaaCrmGaepell.Specialist.full_name(specialist)}"
          Map.put(activity_params, "title", auto_title)
        else
          activity_params
        end
      
      _ ->
        activity_params
    end
    
    case update_activity(activity, activity_params) do
      {:ok, _updated_activity} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Evento actualizado exitosamente")
         |> assign(:show_edit_modal, false)
         |> assign(:editing_activity_modal, nil)
         |> load_activities()}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :editing_activity_modal, %{activity | action: :update, errors: changeset.errors})}
    end
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    case socket.assigns.delete_target do
      %{id: id, type: "activity"} ->
        activity = Repo.get(Activity, id)
        case Repo.delete(activity) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Evento eliminado exitosamente")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_activities()}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al eliminar el evento")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_activities()}
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
  def handle_event("move_activity", %{"activity_id" => activity_id, "new_date" => new_date, "new_time" => new_time}, socket) do
    IO.puts("=== MOVE ACTIVITY EVENT ===")
    IO.puts("Activity ID: #{activity_id}")
    IO.puts("New Date: #{new_date}")
    IO.puts("New Time: #{new_time}")
    IO.puts("Socket assigns: #{inspect(socket.assigns, pretty: true)}")
    
    activity = Repo.get(Activity, activity_id)
    
    if activity do
      IO.puts("Activity found: #{activity.title}")
      IO.puts("Current due_date: #{activity.due_date}")
      IO.puts("Activity struct: #{inspect(activity, pretty: true)}")
      
      # Parse the new date and time
      case parse_datetime(new_date, new_time) do
        {:ok, new_datetime} ->
          IO.puts("Parsed datetime: #{new_datetime}")
          IO.puts("New datetime type: #{inspect(new_datetime)}")
          
          # Solo actualizar fecha/hora, nunca el especialista
          changeset = Activity.changeset(activity, %{"due_date" => new_datetime})
          case Repo.update(changeset) do
            {:ok, updated_activity} ->
              IO.puts("Activity updated successfully")
              IO.puts("New due_date: #{updated_activity.due_date}")
              IO.puts("Updated activity struct: #{inspect(updated_activity, pretty: true)}")
              
              # Reload activities and check if the update is reflected
              socket = load_activities(socket)
              IO.puts("Activities after reload: #{inspect(socket.assigns.activities, pretty: true)}")
              
              {:noreply, 
               socket
               |> put_flash(:info, "Evento movido exitosamente")
               |> load_activities()}
            
            {:error, changeset} ->
              IO.puts("Error updating activity: #{inspect(changeset.errors)}")
              IO.puts("Changeset changes: #{inspect(changeset.changes)}")
              IO.puts("Changeset data: #{inspect(changeset.data)}")
              {:noreply, 
               socket
               |> put_flash(:error, "Error al mover el evento: #{inspect(changeset.errors)}")
               |> load_activities()}
          end
        
        {:error, reason} ->
          IO.puts("Error parsing datetime: #{inspect(reason)}")
          {:noreply, 
           socket
           |> put_flash(:error, "Fecha u hora inválida: #{inspect(reason)}")
           |> load_activities()}
      end
    else
      IO.puts("Activity not found with ID: #{activity_id}")
      {:noreply, 
       socket
       |> put_flash(:error, "Evento no encontrado")
       |> load_activities()}
    end
  end

  defp load_activities(socket) do
    query = from a in Activity,
            where: a.business_id == 1,
            preload: [:contact, :company, :user, :service, :specialist, :truck, :maintenance_ticket],
            order_by: [asc: a.due_date]

    # Aplicar filtros de tipo y estado
    query = case socket.assigns.filter_type do
      "all" -> query
      type -> from a in query, where: a.type == ^type
    end

    query = case socket.assigns.filter_status do
      "all" -> query
      status -> from a in query, where: a.status == ^status
    end

    # Aplicar filtro por empresa
    query = case socket.assigns.filter_company do
      "all" -> query
      company_id when is_binary(company_id) ->
        case Integer.parse(company_id) do
          {id, _} -> from a in query, where: a.company_id == ^id
          :error -> query
        end
      company_id when is_integer(company_id) ->
        from a in query, where: a.company_id == ^company_id
      _ -> query
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

    # Cargar todas las actividades filtradas (sin filtrar por fecha aquí)
    activities = Repo.all(query)
    assign(socket, :activities, activities)
  end

  defp load_contacts(socket) do
    contacts = Repo.all(from c in Contact, where: c.business_id == 1, select: {fragment("? || ' ' || ?", c.first_name, c.last_name), c.id})
    assign(socket, :contacts, contacts)
  end

  defp load_companies(socket) do
    # Empresas específicas para Gaepell
    companies = [
      {"Gaepell", "gaepell"},
      {"Furcar", "furcar"},
      {"Blidomca", "blidomca"},
      {"Polimat", "polimat"}
    ]
    assign(socket, :companies, companies)
  end

  # Función helper para obtener el color de la empresa
  defp company_color("Gaepell"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp company_color("Furcar"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp company_color("Blidomca"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp company_color("Polimat"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp company_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300"

  # Función helper para obtener tipos de eventos por empresa
  defp get_event_types_for_company("Gaepell"), do: EvaaCrmGaepell.Activity.gaepell_types()
  defp get_event_types_for_company("Furcar"), do: EvaaCrmGaepell.Activity.furcar_types()
  defp get_event_types_for_company("Blidomca"), do: EvaaCrmGaepell.Activity.blidomca_types()
  defp get_event_types_for_company("Polimat"), do: EvaaCrmGaepell.Activity.polimat_types()
  defp get_event_types_for_company(_), do: EvaaCrmGaepell.Activity.all_types()

  defp load_users(socket) do
    users = Repo.all(from u in User, where: u.business_id == 1, select: {u.email, u.id})
    assign(socket, :users, users)
  end

  defp load_services(socket) do
    services = Repo.all(from s in Service, where: s.business_id == 1 and s.is_active == true, select: {s.name, s.id})
    assign(socket, :services, services)
  end

  defp load_specialists(socket) do
    specialists = Repo.all(from s in Specialist, where: s.business_id == 1 and s.is_active == true, select: {fragment("? || ' ' || ?", s.first_name, s.last_name), s.id})
    assign(socket, :specialists, specialists)
  end

  defp save_activity(%Activity{} = activity, attrs) do
    activity
    |> Activity.changeset(attrs)
    |> Repo.insert_or_update()
  end

  defp save_activity(nil, attrs) do
    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end

  defp update_activity(%Activity{} = activity, attrs) do
    activity
    |> Activity.changeset(attrs)
    |> Repo.update()
  end

  defp get_week_dates(date) do
    week_start = Date.beginning_of_week(date, :monday)
    for i <- 0..6 do
      Date.add(week_start, i)
    end
  end

  defp get_month_dates(date) do
    month_start = Date.new!(date.year, date.month, 1)
    month_end = Date.end_of_month(date)
    first_week_start = Date.beginning_of_week(month_start, :monday)
    total_days = Date.diff(month_end, first_week_start) + 1
    
    for i <- 0..(total_days - 1) do
      Date.add(first_week_start, i)
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> maybe_assign_week_dates()
      |> maybe_assign_month_dates()

    ~H"""
    <div class="space-y-6" id="agenda-container" phx-hook="AgendaDragDrop" data-drag-mode={@drag_mode}>
      <!-- Header -->
      <div class="flex items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Agenda</h1>
          <p class="text-gray-600 dark:text-gray-400 mt-1">Gestión de eventos y actividades</p>
        </div>
        <button 
          phx-click="show_form" 
          phx-value-activity_id="new"
          class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center space-x-2 ml-4">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          <span>Nuevo Evento</span>
        </button>
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

          <!-- View Mode Toggle y Filtros -->
          <div class="flex items-center gap-2">
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
              <button 
                phx-click="change_view" 
                phx-value-view="month"
                class={[
                  "px-3 py-1 text-sm font-medium rounded-md transition-colors",
                  if @view_mode == "month" do
                    "bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm"
                  else
                    "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                  end
                ]}>
                Mes
              </button>

            </div>
            <!-- Botón de modo mover -->
            <button phx-click="toggle_drag_mode" type="button"
              class={["flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white font-medium shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 transition",
                (if @drag_mode, do: "ring-2 ring-blue-500 bg-blue-50 dark:bg-blue-900", else: "")
              ]}>
              <svg class="w-5 h-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 15v2a2 2 0 002 2h12a2 2 0 002-2v-2M9 10h6m-3-3v6" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l4-4 4 4" />
              </svg>
              <span><%= if @drag_mode, do: "Mover eventos (ON)", else: "Mover eventos" %></span>
            </button>
            <!-- Botón de mostrar botones siempre -->
            <button phx-click="toggle_always_show_buttons" type="button"
              class={["flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white font-medium shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 transition",
                (if @always_show_buttons, do: "ring-2 ring-green-500 bg-green-50 dark:bg-green-900", else: "")
              ]}>
              <svg class="w-5 h-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
              <span><%= if @always_show_buttons, do: "Botones visibles (ON)", else: "Botones visibles" %></span>
            </button>
            <div class="flex space-x-2">
              <!-- Aquí irían los filtros originales para otras vistas -->
            </div>
          </div>
        </div>
      </div>

      <!-- Calendar View -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <%= case @view_mode do %>
          <% "day" -> %>
            <%= render_day_view(assigns) %>
          <% "week" -> %>
            <%= render_week_view(assigns) %>
          <% "month" -> %>
            <%= render_month_view(assigns) %>
        <% end %>
      </div>
    </div>
    <!-- Modal Form -->
    <%= if @show_form do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800" id="agenda-form" phx-hook="AgendaForm">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                <%= if @editing_activity.id, do: "Editar Evento", else: "Nuevo Evento" %>
              </h3>
              <button 
                phx-click="hide_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="save_activity">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Título <span class="text-gray-500">(opcional si hay servicio y especialista)</span>
                  </label>
                  <input 
                    type="text" 
                    name="activity[title]" 
                    value={@editing_activity.title}
                    placeholder="Se generará automáticamente si selecciona servicio y especialista"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                    Si deja vacío y selecciona servicio y especialista, el título se generará automáticamente
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Tipo *
                  </label>
                  <select 
                    name="activity[type]"
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="maintenance" selected={@editing_activity && @editing_activity.type == "maintenance"}>Mantenimiento</option>
                    <option value="delivery" selected={@editing_activity && @editing_activity.type == "delivery"}>Entrega</option>
                    <option value="installation" selected={@editing_activity && @editing_activity.type == "installation"}>Instalación</option>
                    <option value="inspection" selected={@editing_activity && @editing_activity.type == "inspection"}>Inspección</option>
                    <option value="meeting" selected={@editing_activity && @editing_activity.type == "meeting"}>Reunión</option>
                    <option value="call" selected={@editing_activity && @editing_activity.type == "call"}>Llamada</option>
                    <option value="task" selected={@editing_activity && @editing_activity.type == "task"}>Tarea</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fecha *
                  </label>
                  <input 
                    type="date" 
                    name="activity[due_date_date]" 
                    value={if @editing_activity.due_date, do: Date.to_string(DateTime.to_date(@editing_activity.due_date)), else: ""}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Hora *
                  </label>
                  <div class="grid grid-cols-2 gap-2">
                    <select 
                      name="activity[due_date_hour]" 
                      required
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                      <%= for hour <- 0..23 do %>
                        <option value={hour} selected={if @editing_activity.due_date, do: DateTime.to_naive(@editing_activity.due_date).hour == hour, else: false}>
                          <%= String.pad_leading("#{hour}", 2, "0") %>:00
                        </option>
                      <% end %>
                    </select>
                    <select 
                      name="activity[due_date_minutes]" 
                      required
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                      <%= for minute <- [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55] do %>
                        <option value={minute} selected={if @editing_activity.due_date, do: DateTime.to_naive(@editing_activity.due_date).minute == minute, else: false}>
                          :<%= String.pad_leading("#{minute}", 2, "0") %>
                        </option>
                      <% end %>
                    </select>
                  </div>
                  <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                    Los minutos se muestran en incrementos de 5 minutos
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Duración
                  </label>
                  <select 
                    name="activity[duration_minutes]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="15" selected={@editing_activity && @editing_activity.duration_minutes == 15}>15 minutos</option>
                    <option value="30" selected={@editing_activity && @editing_activity.duration_minutes == 30}>30 minutos</option>
                    <option value="45" selected={@editing_activity && @editing_activity.duration_minutes == 45}>45 minutos</option>
                    <option value="60" selected={@editing_activity && (@editing_activity.duration_minutes == 60 || @editing_activity.duration_minutes == nil)}>1 hora</option>
                    <option value="90" selected={@editing_activity && @editing_activity.duration_minutes == 90}>1 hora 30 minutos</option>
                    <option value="120" selected={@editing_activity && @editing_activity.duration_minutes == 120}>2 horas</option>
                    <option value="180" selected={@editing_activity && @editing_activity.duration_minutes == 180}>3 horas</option>
                    <option value="240" selected={@editing_activity && @editing_activity.duration_minutes == 240}>4 horas</option>
                    <option value="360" selected={@editing_activity && @editing_activity.duration_minutes == 360}>6 horas</option>
                    <option value="480" selected={@editing_activity && @editing_activity.duration_minutes == 480}>8 horas</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Cliente
                  </label>
                  <select 
                    name="activity[contact_id]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar cliente</option>
                    <%= for {name, id} <- @contacts do %>
                      <option value={id} selected={@editing_activity.contact_id == id}><%= name %></option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Empresa
                  </label>
                  <select 
                    name="activity[company_id]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar empresa</option>
                    <%= for {name, id} <- @companies do %>
                      <option value={id} selected={@editing_activity.company_id == id}><%= name %></option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Asignado a
                  </label>
                  <select 
                    name="activity[user_id]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar usuario</option>
                    <%= for {email, id} <- @users do %>
                      <option value={id} selected={@editing_activity.user_id == id}><%= email %></option>
                    <% end %>
                  </select>
                </div>

                

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Prioridad
                  </label>
                  <select 
                    name="activity[priority]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="low" selected={@editing_activity && @editing_activity.priority == "low"}>Baja</option>
                    <option value="medium" selected={@editing_activity && @editing_activity.priority == "medium"}>Media</option>
                    <option value="high" selected={@editing_activity && @editing_activity.priority == "high"}>Alta</option>
                    <option value="urgent" selected={@editing_activity && @editing_activity.priority == "urgent"}>Urgente</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Estado
                  </label>
                  <select 
                    name="activity[status]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="pending" selected={@editing_activity && @editing_activity.status == "pending"}>Pendiente</option>
                    <option value="in_progress" selected={@editing_activity && @editing_activity.status == "in_progress"}>En progreso</option>
                    <option value="completed" selected={@editing_activity && @editing_activity.status == "completed"}>Completado</option>
                    <option value="cancelled" selected={@editing_activity && @editing_activity.status == "cancelled"}>Cancelado</option>
                  </select>
                </div>
              </div>

              <div class="mt-4">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Descripción
                </label>
                <textarea 
                  name="activity[description]" 
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"><%= @editing_activity.description %></textarea>
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
                  Guardar Evento
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
              ¿Estás seguro de que quieres eliminar el evento "<%= @delete_target.title %>"?
            </p>
            <p class="text-xs text-gray-400 dark:text-gray-500 mt-2">
              Esta acción no se puede deshacer.
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

    <!-- Edit Activity Modal -->
    <%= if @show_edit_modal and @editing_activity_modal do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-10 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                Editar Evento
              </h3>
              <button 
                phx-click="hide_edit_modal"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="update_activity_modal" class="space-y-4">
              <!-- Title -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Título
                </label>
                <input 
                  type="text" 
                  name="activity[title]" 
                  value={@editing_activity_modal.title}
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Título del evento">
              </div>

              <!-- Date and Time -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fecha
                  </label>
                  <input 
                    type="date" 
                    name="activity[due_date_date]" 
                    value={if @editing_activity_modal.due_date, do: Date.to_string(DateTime.to_date(@editing_activity_modal.due_date))}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Hora
                  </label>
                  <input 
                    type="time" 
                    name="activity[due_date_time]" 
                    value={if @editing_activity_modal.due_date, do: "#{String.pad_leading("#{DateTime.to_naive(@editing_activity_modal.due_date).hour}", 2, "0")}:#{String.pad_leading("#{DateTime.to_naive(@editing_activity_modal.due_date).minute}", 2, "0")}"}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>
              </div>

              <!-- Duration -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Duración
                </label>
                <select 
                  name="activity[duration_minutes]" 
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <option value="15" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 15}>15 minutos</option>
                  <option value="30" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 30}>30 minutos</option>
                  <option value="45" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 45}>45 minutos</option>
                  <option value="60" selected={@editing_activity_modal && (@editing_activity_modal.duration_minutes == 60 || @editing_activity_modal.duration_minutes == nil)}>1 hora</option>
                  <option value="90" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 90}>1 hora 30 minutos</option>
                  <option value="120" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 120}>2 horas</option>
                  <option value="180" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 180}>3 horas</option>
                  <option value="240" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 240}>4 horas</option>
                  <option value="360" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 360}>6 horas</option>
                  <option value="480" selected={@editing_activity_modal && @editing_activity_modal.duration_minutes == 480}>8 horas</option>
                </select>
              </div>

              <!-- Client -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Cliente
                </label>
                <select 
                  name="activity[contact_id]" 
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <option value="">Seleccionar cliente</option>
                  <%= for {name, id} <- @contacts do %>
                    <option value={id} selected={@editing_activity_modal.contact_id == id}>
                      <%= name %>
                    </option>
                  <% end %>
                </select>
              </div>

              <!-- Company -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Empresa
                </label>
                <select 
                  name="activity[company_id]" 
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <option value="">Seleccionar empresa</option>
                  <%= for {name, id} <- @companies do %>
                    <option value={id} selected={@editing_activity_modal.company_id == id}>
                      <%= name %>
                    </option>
                  <% end %>
                </select>
              </div>

              <!-- Service -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Servicio
                </label>
                <select 
                  name="activity[service_id]" 
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <option value="">Seleccionar servicio</option>
                  <%= for {name, id} <- @services do %>
                    <option value={id} selected={@editing_activity_modal.service_id == id}>
                      <%= name %>
                    </option>
                  <% end %>
                </select>
              </div>

              <!-- Specialist -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Especialista
                </label>
                <select 
                  name="activity[specialist_id]" 
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <option value="">Seleccionar especialista</option>
                  <%= for {name, id} <- @specialists do %>
                    <option value={id} selected={@editing_activity_modal.specialist_id == id}>
                      <%= name %>
                    </option>
                  <% end %>
                </select>
              </div>

              <!-- Type -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Tipo de Evento
                </label>
                <select 
                  name="activity[type]" 
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                  <option value="maintenance" selected={@editing_activity_modal && @editing_activity_modal.type == "maintenance"}>Mantenimiento</option>
                  <option value="delivery" selected={@editing_activity_modal && @editing_activity_modal.type == "delivery"}>Entrega</option>
                  <option value="installation" selected={@editing_activity_modal && @editing_activity_modal.type == "installation"}>Instalación</option>
                  <option value="inspection" selected={@editing_activity_modal && @editing_activity_modal.type == "inspection"}>Inspección</option>
                  <option value="meeting" selected={@editing_activity_modal && @editing_activity_modal.type == "meeting"}>Reunión</option>
                  <option value="call" selected={@editing_activity_modal && @editing_activity_modal.type == "call"}>Llamada</option>
                  <option value="task" selected={@editing_activity_modal && @editing_activity_modal.type == "task"}>Tarea</option>
                </select>
              </div>

              <!-- Status and Priority -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Estado
                  </label>
                  <select 
                    name="activity[status]" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="pending" selected={@editing_activity_modal && @editing_activity_modal.status == "pending"}>Pendiente</option>
                    <option value="in_progress" selected={@editing_activity_modal && @editing_activity_modal.status == "in_progress"}>En progreso</option>
                    <option value="completed" selected={@editing_activity_modal && @editing_activity_modal.status == "completed"}>Completado</option>
                    <option value="cancelled" selected={@editing_activity_modal && @editing_activity_modal.status == "cancelled"}>Cancelado</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Prioridad
                  </label>
                  <select 
                    name="activity[priority]" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="low" selected={@editing_activity_modal && @editing_activity_modal.priority == "low"}>Baja</option>
                    <option value="medium" selected={@editing_activity_modal && @editing_activity_modal.priority == "medium"}>Media</option>
                    <option value="high" selected={@editing_activity_modal && @editing_activity_modal.priority == "high"}>Alta</option>
                    <option value="urgent" selected={@editing_activity_modal && @editing_activity_modal.priority == "urgent"}>Urgente</option>
                  </select>
                </div>
              </div>

              <!-- Description -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Descripción
                </label>
                <textarea 
                  name="activity[description]" 
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Descripción del evento"><%= @editing_activity_modal.description %></textarea>
              </div>

              <!-- Buttons -->
              <div class="flex justify-end space-x-3 pt-4">
                <button 
                  type="button"
                  phx-click="hide_edit_modal"
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

    <!-- Edit Ticket Modal -->
    <%= if @show_ticket_modal and @editing_ticket do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg shadow-lg w-full max-w-md max-h-[90vh] flex flex-col">
          <div class="flex justify-between items-center p-3 border-b border-gray-200 shrink-0">
            <h3 class="text-base font-semibold text-gray-900"> <%= if @editing_ticket.data.id, do: "Editar Ticket", else: "Nuevo Ticket" %> </h3>
            <button phx-click="hide_ticket_modal" class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>
          <.form :let={f} for={@editing_ticket} phx-submit="save_ticket_from_agenda" class="flex-1 flex flex-col min-h-0">
            <div class="p-2 space-y-1 overflow-y-auto flex-1 min-h-0">
              <div>
                <label class="block text-xs font-medium text-gray-700">Camión</label>
                <%= if is_list(@trucks) and length(@trucks) > 0 do %>
                  <select name="maintenance_ticket[truck_id]" required class="mt-1 block w-full px-1 py-1 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-xs">
                    <option value="">Seleccionar camión</option>
                    <%= for truck <- @trucks do %>
                      <option value={truck.id} selected={input_value(f, :truck_id) == truck.id}>
                        <%= truck.brand %> <%= truck.model %> (<%= truck.license_plate %>)
                      </option>
                    <% end %>
                  </select>
                <% else %>
                  <div class="text-xs text-red-500">No hay camiones disponibles</div>
                <% end %>
              </div>
              <.input field={f[:entry_date]} type="datetime-local" label="Fecha de Ingreso" required class="w-full text-xs" input_class="px-1 py-1" />
              <.input field={f[:mileage]} type="number" label="Kilometraje" class="w-full text-xs" input_class="px-1 py-1" />
              <div>
                <label class="block text-xs font-medium text-gray-700">Nivel de Combustible</label>
                <select name="maintenance_ticket[fuel_level]" class="mt-1 block w-full px-1 py-1 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-xs">
                  <option value="">Seleccionar nivel</option>
                  <option value="empty" selected={input_value(f, :fuel_level) == "empty"}>Vacío</option>
                  <option value="quarter" selected={input_value(f, :fuel_level) == "quarter"}>1/4</option>
                  <option value="half" selected={input_value(f, :fuel_level) == "half"}>1/2</option>
                  <option value="three_quarters" selected={input_value(f, :fuel_level) == "three_quarters"}>3/4</option>
                  <option value="full" selected={input_value(f, :fuel_level) == "full"}>Lleno</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700">Estado</label>
                <select name="maintenance_ticket[status]" required class="mt-1 block w-full px-1 py-1 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-xs">
                  <option value="open" selected={input_value(f, :status) == "open"}>Pendiente</option>
                  <option value="in_progress" selected={input_value(f, :status) == "in_progress"}>En Reparación</option>
                  <option value="completed" selected={input_value(f, :status) == "completed"}>Listo</option>
                  <option value="cancelled" selected={input_value(f, :status) == "cancelled"}>Finalizado</option>
                </select>
              </div>
              <.input field={f[:visible_damage]} type="textarea" label="Daños Visibles" rows="2" class="w-full text-xs" input_class="px-1 py-1" />
              <.input field={f[:exit_notes]} type="textarea" label="Notas de Salida" rows="2" class="w-full text-xs" input_class="px-1 py-1" />
              <div>
                <label class="block text-xs font-medium text-gray-700 mb-1">Color del Evento</label>
                <input type="color" name="maintenance_ticket[color]" value={input_value(f, :color) || "#2563eb"} class="w-7 h-5 p-0 border-0 bg-transparent cursor-pointer align-middle" />
                <span class="ml-2 text-xs text-gray-500">Color en la agenda</span>
              </div>
            </div>
            <div class="flex justify-end gap-2 p-2 border-t border-gray-200 shrink-0">
              <button type="button" phx-click="hide_ticket_modal" class="px-3 py-1 bg-gray-200 text-gray-700 rounded hover:bg-gray-300">Cancelar</button>
              <button type="submit" class="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">Guardar Ticket</button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>
  """
  end

  defp maybe_assign_week_dates(assigns) do
    if assigns.view_mode == "week" do
      assign(assigns, :week_dates, get_week_dates(assigns.selected_date))
    else
      assigns
    end
  end

  defp maybe_assign_month_dates(assigns) do
    if assigns.view_mode == "month" do
      assign(assigns, :month_dates, get_month_dates(assigns.selected_date))
    else
      assigns
    end
  end

  defp render_day_view(assigns) do
    assigns = assign(assigns, :activities_for_view, get_activities_for_view(assigns.activities, assigns.view_mode, assigns.selected_date))
    
   ~H""" 
    <div class="p-6">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
        <%= Calendar.strftime(@selected_date, "%A, %d de %B de %Y") %>
      </h3>
      <div class="space-y-4">
        <%= if @detail_view do %>
          <!-- Vista detalle con slots de 5 minutos -->
          <%= for hour <- 7..18 do %>
            <%= for minute <- [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55] do %>
                              <div class="flex border-b border-gray-200 dark:border-gray-700 pb-1">
                  <div class="w-20 text-sm text-gray-500 dark:text-gray-400">
                    <%= format_12h_time(hour, minute) %>
                  </div>
                <div class="flex-1">
                  <div class="time-slot"
                        phx-click="new_activity_slot"
                        phx-value-date={Calendar.strftime(@selected_date, "%Y-%m-%d")}
                        phx-value-time={"#{hour}:#{String.pad_leading("#{minute}", 2, "0")}"}
                        data-tooltip="Nuevo evento"
                        data-date={Calendar.strftime(@selected_date, "%Y-%m-%d")}
                        data-time={"#{hour}:#{String.pad_leading("#{minute}", 2, "0")}"}
                        id={"slot-day-#{hour}-#{minute}"}>
                    <%= for activity <- get_activities_for_hour_and_minute(@activities_for_view, hour, minute) do %>
                      <div class={[
                        "activity-item p-2 rounded-lg mb-1 text-sm cursor-pointer",
                        activity_color(activity.type)
                      ]}
                      draggable="true"
                      data-activity-id={activity.id}
                      data-activity-status={activity.status}
                      data-slot-id={"slot-day-#{hour}-#{minute}"}
                      title={build_activity_tooltip(activity)}>
                        <div class="flex items-center justify-between">
                          <div class="flex items-center min-w-0 flex-1">
                            <div class={[
                              "w-2 h-2 rounded-full mr-2 flex-shrink-0",
                              activity_color_dot(activity.type)
                            ]}></div>
                            <div class="font-medium truncate"><%= activity.title %></div>
                          </div>
                          <div class="text-xs text-gray-500 dark:text-gray-400 ml-2 flex-shrink-0">
                            <%= "⏰" <> format_time(activity.due_date) %>
                          </div>
                        </div>
                        <div class="text-xs opacity-75 flex items-center gap-1">
                          <%= if activity.type == "maintenance" do %>
                            <span title="Mantenimiento"><svg class="inline w-4 h-4 text-blue-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg></span>
                            <span><%= if activity.truck, do: "Camión: #{activity.truck.brand} #{activity.truck.model} (#{activity.truck.license_plate})", else: "Mantenimiento de camión" %></span>
                          <% else %>
                            <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %>
                            <%= if activity.service, do: " • " <> activity.service.name %>
                            <%= if activity.specialist, do: " • " <> activity.specialist.first_name %>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
                <% else %>
          <!-- Vista general con slots de 1 hora -->
          <%= for hour <- 7..18 do %>
            <div class="flex border-b border-gray-200 dark:border-gray-700 pb-2">
              <div class="w-20 text-sm text-gray-500 dark:text-gray-400">
                <%= format_12h_time(hour, 0) %>
              </div>
              <div class="flex-1">
                <div class="time-slot"
                      phx-click="new_activity_slot"
                      phx-value-date={Calendar.strftime(@selected_date, "%Y-%m-%d")}
                      phx-value-time={"#{hour}:00"}
                      data-tooltip="Nuevo evento"
                      data-date={Calendar.strftime(@selected_date, "%Y-%m-%d")}
                      data-time={"#{hour}:00"}
                      id={"slot-day-#{hour}-0"}>
                  <%= for activity <- get_activities_for_hour(@activities_for_view, hour) do %>
                    <div class={[
                      "activity-item p-2 rounded-lg mb-2 text-sm cursor-pointer group",
                      activity_color(activity.type)
                    ]}
                    draggable="true"
                    data-activity-id={activity.id}
                    data-activity-status={activity.status}
                    data-slot-id={"slot-day-#{hour}-0"}
                    title={build_activity_tooltip(activity)}>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center min-w-0 flex-1">
                          <div class={[
                            "w-2 h-2 rounded-full mr-2 flex-shrink-0",
                            activity_color_dot(activity.type)
                          ]}></div>
                          <div class="font-medium truncate"><%= activity.title %></div>
                        </div>
                        <div class="flex items-center space-x-2 flex-shrink-0">
                          <div class="text-xs text-gray-500 dark:text-gray-400">
                             <%= "⏰" <> format_time(activity.due_date) %>
                          </div>
                          <div class="flex space-x-1">
                            <button class={"transition-opacity text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-1 border border-blue-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                    phx-click="edit_activity"
                                    phx-value-activity-id={activity.id}
                                    title="Editar evento">
                              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                              </svg>
                            </button>
                            <button class={"transition-opacity text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-1 border border-red-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                    phx-click="show_delete_confirm"
                                    phx-value-id={activity.id}
                                    phx-value-type="activity"
                                    title="Eliminar evento">
                              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                      <div class="text-xs opacity-75 flex items-center gap-1">
                        <%= if activity.type == "maintenance" do %>
                          <span title="Mantenimiento"><svg class="inline w-4 h-4 text-blue-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg></span>
                          <span><%= if activity.truck, do: "Camión: #{activity.truck.brand} #{activity.truck.model} (#{activity.truck.license_plate})", else: "Mantenimiento de camión" %></span>
                        <% else %>
                          <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %>
                          <%= if activity.service, do: " • " <> activity.service.name %>
                          <%= if activity.specialist, do: " • " <> activity.specialist.first_name %>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_week_view(assigns) do
    assigns = assign(assigns, :activities_for_view, get_activities_for_view(assigns.activities, assigns.view_mode, assigns.selected_date))
    
  ~H"""
    <div class="p-6">
      <!-- Tabla de semana con diseño más uniforme -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <!-- Header de la tabla -->
        <div class="grid grid-cols-8 bg-gray-50 dark:bg-gray-700 border-b border-gray-200 dark:border-gray-600">
          <!-- Columna de tiempo -->
          <div class="h-14 flex items-center justify-center text-sm font-semibold text-gray-700 dark:text-gray-300 border-r border-gray-200 dark:border-gray-600">
            Hora
          </div>
          <!-- Columnas de días -->
          <%= for date <- @week_dates do %>
            <div class="h-14 flex items-center justify-center border-r border-gray-200 dark:border-gray-600 last:border-r-0">
              <div class="text-center">
                <div class="text-sm font-semibold text-gray-700 dark:text-gray-300">
                  <%= Calendar.strftime(date, "%a") %>
                </div>
                <div class={[
                  "text-xs rounded-full w-6 h-6 flex items-center justify-center mt-1",
                  if Date.compare(date, @selected_date) == :eq do
                    "bg-blue-600 text-white"
                  else
                    "text-gray-500 dark:text-gray-400"
                  end
                ]}>
                  <%= date.day %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        
        <!-- Cuerpo de la tabla -->
        <div class="grid grid-cols-8">
          <!-- Columna de tiempo -->
          <div class="border-r border-gray-200 dark:border-gray-600">
            <%= for hour <- 7..18 do %>
              <div class="h-16 flex items-center justify-center text-sm text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-600 last:border-b-0">
                <%= String.pad_leading("#{hour}:00", 5, "0") %>
              </div>
            <% end %>
          </div>
          
          <!-- Columnas de días -->
          <%= for date <- @week_dates do %>
            <div class="border-r border-gray-200 dark:border-gray-600 last:border-r-0">
              <%= for hour <- 7..18 do %>
                <div class={[
                  "time-slot h-16 border-b border-gray-200 dark:border-gray-600 last:border-b-0 relative",
                  if Date.compare(date, @selected_date) == :eq do
                    "bg-blue-50 dark:bg-blue-900/20"
                  else
                    "bg-white dark:bg-gray-800"
                  end
                ]}
                phx-click="new_activity_slot"
                phx-value-date={Calendar.strftime(date, "%Y-%m-%d")}
                phx-value-time={"#{hour}:00"}
                data-tooltip="Nuevo evento"
                data-date={Calendar.strftime(date, "%Y-%m-%d")}
                data-time={"#{hour}:00"}
                id={"slot-week-#{Date.to_string(date)}-#{hour}-0"}>
                  
                  <!-- Actividades -->
                  <div class="p-1 space-y-0.5">
                    <%= for activity <- get_activities_for_date_and_hour(@activities_for_view, date, hour) do %>
                      <div class={[
                        "activity-item text-xs p-1 rounded-md truncate cursor-pointer group border shadow-sm",
                        activity_color(activity.type)
                      ]}
                      draggable="true"
                      data-activity-id={activity.id}
                      data-activity-status={activity.status}
                      data-slot-id={"slot-week-#{Date.to_string(date)}-#{hour}-0"}
                      title={build_activity_tooltip(activity)}>
                        <div class="flex items-center justify-between">
                          <div class="flex items-center min-w-0 flex-1">
                            <div class={[
                              "w-1.5 h-1.5 rounded-full mr-1 flex-shrink-0",
                              activity_color_dot(activity.type)
                            ]}></div>
                            <div class="font-medium truncate text-xs"><%= activity.title %></div>
                          </div>
                          <div class="flex space-x-0.5 flex-shrink-0">
                            <button class={"transition-opacity text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-0.5 border border-blue-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                    phx-click="edit_activity"
                                    phx-value-activity-id={activity.id}
                                    title="Editar evento">
                              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                              </svg>
                            </button>
                            <button class={"transition-opacity text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-0.5 border border-red-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                    phx-click="show_delete_confirm"
                                    phx-value-id={activity.id}
                                    phx-value-type="activity"
                                    title="Eliminar evento">
                              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                              </svg>
                            </button>
                          </div>
                        </div>
                        <div class="text-xs opacity-75 flex items-center gap-1 mt-0.5">
                          <%= if activity.type == "maintenance" do %>
                            <span title="Mantenimiento"><svg class="inline w-3 h-3 text-blue-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg></span>
                            <span class="truncate"><%= if activity.truck, do: "Camión: #{activity.truck.brand} #{activity.truck.model} (#{activity.truck.license_plate})", else: "Mantenimiento de camión" %></span>
                          <% else %>
                            <span class="truncate"><%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %></span>
                            <%= if activity.service, do: " • " <> activity.service.name %>
                            <%= if activity.specialist, do: " • " <> activity.specialist.first_name %>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp render_month_view(assigns) do
    assigns = assign(assigns, :activities_for_view, get_activities_for_view(assigns.activities, assigns.view_mode, assigns.selected_date))
    
  ~H"""
    <div class="p-6">
      <!-- Tabla de calendario con diseño más uniforme -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <!-- Header de la tabla -->
        <div class="grid grid-cols-7 bg-gray-50 dark:bg-gray-700 border-b border-gray-200 dark:border-gray-600">
          <%= for day_name <- ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"] do %>
            <div class="h-14 flex items-center justify-center text-sm font-semibold text-gray-700 dark:text-gray-300 border-r border-gray-200 dark:border-gray-600 last:border-r-0">
              <%= day_name %>
            </div>
          <% end %>
        </div>
        
        <!-- Cuerpo de la tabla -->
        <div class="grid grid-cols-7">
          <%= for date <- @month_dates do %>
            <div class={[
              "time-slot min-h-[120px] border-r border-b border-gray-200 dark:border-gray-600 last:border-r-0 relative",
              if Date.compare(date, @selected_date) == :eq do
                "bg-blue-50 dark:bg-blue-900/20"
              else
                "bg-white dark:bg-gray-800"
              end
            ]}
            phx-click="new_activity_slot"
            phx-value-date={Calendar.strftime(date, "%Y-%m-%d")}
            phx-value-time="09:00"
            data-tooltip="Nuevo evento"
            data-date={Calendar.strftime(date, "%Y-%m-%d")}
            data-time="09:00"
            id={"slot-month-#{Date.to_string(date)}"}>
              
              <!-- Número del día -->
              <div class={[
                "absolute top-2 left-2 text-sm font-medium",
                if Date.compare(date, @selected_date) == :eq do
                  "text-blue-700 dark:text-blue-300"
                else
                  "text-gray-900 dark:text-gray-100"
                end
              ]}>
                <%= date.day %>
              </div>
              
              <!-- Actividades -->
              <div class="pt-8 px-2 pb-2 space-y-1">
                <%= for activity <- get_activities_for_date(@activities_for_view, date) do %>
                  <div class={[
                    "activity-item text-xs p-1.5 rounded-md truncate cursor-pointer group border shadow-sm",
                    activity_color(activity.type)
                  ]}
                  draggable="true"
                  data-activity-id={activity.id}
                  data-activity-status={activity.status}
                  data-slot-id={"slot-month-#{Date.to_string(date)}"}
                  title={build_activity_tooltip(activity)}>
                    <div class="flex items-center justify-between">
                      <div class="flex items-center min-w-0 flex-1">
                        <div class={[
                          "w-2 h-2 rounded-full mr-1.5 flex-shrink-0",
                          activity_color_dot(activity.type)
                        ]}></div>
                        <div class="font-medium truncate text-xs"><%= activity.title %></div>
                      </div>
                      <div class="flex space-x-0.5 flex-shrink-0">
                        <button class={"transition-opacity text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-0.5 border border-blue-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                phx-click="edit_activity"
                                phx-value-activity-id={activity.id}
                                title="Editar evento">
                          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                          </svg>
                        </button>
                        <button class={"transition-opacity text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-0.5 border border-red-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                phx-click="show_delete_confirm"
                                phx-value-id={activity.id}
                                phx-value-type="activity"
                                title="Eliminar evento">
                          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                          </svg>
                        </button>
                      </div>
                    </div>
                    <div class="text-xs opacity-75 flex items-center gap-1 mt-0.5">
                      <%= if activity.type == "maintenance" do %>
                        <span title="Mantenimiento"><svg class="inline w-3 h-3 text-blue-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg></span>
                        <span class="truncate"><%= if activity.truck, do: "Camión: #{activity.truck.brand} #{activity.truck.model} (#{activity.truck.license_plate})", else: "Mantenimiento de camión" %></span>
                      <% else %>
                        <span class="truncate"><%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin paciente" %></span>
                        <%= if activity.service, do: " • " <> activity.service.name %>
                        <%= if activity.specialist, do: " • " <> activity.specialist.first_name %>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
  """
  end

  defp get_activities_for_hour(activities, hour) do
    Enum.filter(activities, fn activity ->
      activity.due_date &&
        (activity.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour
    end)
  end

  defp get_activities_for_hour_and_minute(activities, hour, minute) do
    Enum.filter(activities, fn activity ->
      activity.due_date &&
        (activity.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour &&
        (activity.due_date |> DateTime.to_naive() |> Map.get(:minute)) >= minute &&
        (activity.due_date |> DateTime.to_naive() |> Map.get(:minute)) < minute + 5
    end)
  end

  defp format_time(datetime) do
    if datetime do
      format_12h_time(DateTime.to_naive(datetime).hour, DateTime.to_naive(datetime).minute)
    else
      "Sin hora"
    end
  end

  defp format_12h_time(hour, minute) do
    cond do
      hour == 0 -> "12:#{String.pad_leading("#{minute}", 2, "0")} AM"
      hour < 12 -> "#{hour}:#{String.pad_leading("#{minute}", 2, "0")} AM"
      hour == 12 -> "12:#{String.pad_leading("#{minute}", 2, "0")} PM"
      true -> "#{hour - 12}:#{String.pad_leading("#{minute}", 2, "0")} PM"
    end
  end

  defp get_activities_for_specialist_hour_and_minute(activities, specialist_id, hour, minute) do
    Enum.filter(activities, fn activity ->
      activity.specialist_id == specialist_id and
      activity.due_date &&
      (activity.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour &&
      (activity.due_date |> DateTime.to_naive() |> Map.get(:minute)) >= minute &&
      (activity.due_date |> DateTime.to_naive() |> Map.get(:minute)) < minute + 5
    end)
  end

  defp get_activities_for_date_and_hour(activities, date, hour) do
    Enum.filter(activities, fn activity ->
      activity.due_date &&
        Date.compare(DateTime.to_date(activity.due_date), date) == :eq &&
        (activity.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour
    end)
  end

  defp get_activities_for_date(activities, date) do
    Enum.filter(activities, fn activity ->
      activity.due_date &&
        Date.compare(DateTime.to_date(activity.due_date), date) == :eq
    end)
  end

  defp get_activities_for_view(activities, view_mode, selected_date) do
    case view_mode do
      "day" ->
        Enum.filter(activities, fn activity ->
          activity.due_date &&
            Date.compare(DateTime.to_date(activity.due_date), selected_date) == :eq
        end)
      
      "week" ->
        week_start = Date.beginning_of_week(selected_date, :monday)
        week_end = Date.end_of_week(selected_date, :monday)
        Enum.filter(activities, fn activity ->
          if activity.due_date do
            activity_date = DateTime.to_date(activity.due_date)
            start_compare = Date.compare(activity_date, week_start)
            end_compare = Date.compare(activity_date, week_end)
            start_compare != :lt && end_compare != :gt
          else
            false
          end
        end)
      
      "month" ->
        month_start = Date.new!(selected_date.year, selected_date.month, 1)
        month_end = Date.end_of_month(selected_date)
        Enum.filter(activities, fn activity ->
          if activity.due_date do
            activity_date = DateTime.to_date(activity.due_date)
            start_compare = Date.compare(activity_date, month_start)
            end_compare = Date.compare(activity_date, month_end)
            start_compare != :lt && end_compare != :gt
          else
            false
          end
        end)
      
      "list" ->
        # En vista de lista, mostrar todas las actividades ordenadas por fecha
        Enum.sort(activities, fn a, b ->
          case {a.due_date, b.due_date} do
            {nil, nil} -> true
            {nil, _} -> false
            {_, nil} -> true
            {date_a, date_b} -> DateTime.compare(date_a, date_b) == :lt
          end
        end)
    end
  end

  defp activity_color("service"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  defp activity_color("meeting"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp activity_color("call"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp activity_color("email"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp activity_color("task"), do: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
  defp activity_color("note"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  defp activity_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp activity_color_dot("service"), do: "bg-purple-500"
  defp activity_color_dot("meeting"), do: "bg-blue-500"
  defp activity_color_dot("call"), do: "bg-green-500"
  defp activity_color_dot("email"), do: "bg-yellow-500"
  defp activity_color_dot("task"), do: "bg-orange-500"
  defp activity_color_dot("note"), do: "bg-gray-500"
  defp activity_color_dot(_), do: "bg-gray-500"

  defp status_color("pending"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp status_color("in_progress"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp status_color("completed"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp status_color("cancelled"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp status_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp status_text("pending"), do: "Pendiente"
  defp status_text("in_progress"), do: "En progreso"
  defp status_text("completed"), do: "Completado"
  defp status_text("cancelled"), do: "Cancelado"
  defp status_text(_), do: "Desconocido"

  defp status_text_short("pending"), do: "Pendiente"
  defp status_text_short("in_progress"), do: "En progreso"
  defp status_text_short("completed"), do: "Completado"
  defp status_text_short("cancelled"), do: "Cancelado"
  defp status_text_short(_), do: "Desconocido"


  defp build_activity_tooltip(activity) do
    parts = ["📅 #{activity.title}"]

    parts =
      if activity.due_date do
        date_str = Calendar.strftime(DateTime.to_date(activity.due_date), "%d/%m/%Y")
        time_str = format_12h_time(DateTime.to_naive(activity.due_date).hour, DateTime.to_naive(activity.due_date).minute)
        parts ++ ["🕐 #{date_str} a las #{time_str}"]
        
        # Calcular duración si hay duración definida
        if activity.duration_minutes do
          end_time = DateTime.add(activity.due_date, activity.duration_minutes * 60, :second)
          end_time_str = format_12h_time(DateTime.to_naive(end_time).hour, DateTime.to_naive(end_time).minute)
          parts ++ ["⏱️ Duración: #{activity.duration_minutes} min (#{time_str} - #{end_time_str})"]
        else
          parts
        end
      else
        parts
      end

    parts =
      if activity.contact do
        client_name = EvaaCrmGaepell.Contact.full_name(activity.contact)
        parts = parts ++ ["👤 Cliente: #{client_name}"]
        parts = if activity.contact.email, do: parts ++ ["📧 #{activity.contact.email}"], else: parts
        parts = if activity.contact.phone, do: parts ++ ["📞 #{activity.contact.phone}"], else: parts
        parts
      else
        parts
      end

    parts =
      if activity.service do
        parts = parts ++ ["💼 Servicio: #{activity.service.name}", "💰 Precio: $#{activity.service.price}"]
        parts
      else
        parts
      end

    parts =
      if activity.specialist do
        specialist_name = EvaaCrmGaepell.Specialist.full_name(activity.specialist)
        parts = parts ++ ["👩‍⚕️ Especialista: #{specialist_name}", "🏥 #{activity.specialist.specialization}"]
        parts
      else
        parts
      end

    parts =
      if activity.company do
        parts ++ ["🏢 Empresa: #{activity.company.name}"]
      else
        parts
      end

    parts = parts ++ ["📊 Estado: #{status_text(activity.status)}", "⚡ Prioridad: #{priority_text(activity.priority)}"]

    parts =
      if activity.description && activity.description != "" do
        parts ++ ["📝 #{activity.description}"]
      else
        parts
      end

    Enum.join(parts, "\n")
  end

  defp priority_text("low"), do: "Baja"
  defp priority_text("medium"), do: "Media"
  defp priority_text("high"), do: "Alta"
  defp priority_text("urgent"), do: "Urgente"
  defp priority_text(_), do: "Media"

  defp parse_datetime(date_str, time_str) do
    try do
      # Parse date (YYYY-MM-DD)
      date = Date.from_iso8601!(date_str)
      
      # Parse time (HH:MM)
      [hour, minute] = String.split(time_str, ":") |> Enum.map(&String.to_integer/1)
      time = Time.new!(hour, minute, 0)
      
      # Combine date and time into datetime
      datetime = DateTime.new!(date, time, "Etc/UTC")
      {:ok, datetime}
    rescue
      _ -> {:error, :invalid_datetime}
    end
  end

  defp parse_datetime_from_separate_fields(date_str, hour_str, minutes_str) do
    try do
      # Parse date (YYYY-MM-DD)
      date = Date.from_iso8601!(date_str)
      
      # Parse hour and minutes
      hour = String.to_integer(hour_str)
      minutes = String.to_integer(minutes_str)
      time = Time.new!(hour, minutes, 0)
      
      # Combine date and time into datetime
      datetime = DateTime.new!(date, time, "Etc/UTC")
      {:ok, datetime}
    rescue
      _ -> {:error, :invalid_datetime}
    end
  end



  defp render_specialist_view(assigns) do
    assigns = assign(assigns, :activities_for_view, get_activities_for_view(assigns.activities, "day", assigns.selected_date))
  ~H"""
    <div class="p-6" id="agenda-eq-root" phx-hook="AgendaDragDropEq">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
        Agenda por Equipo - <%= Calendar.strftime(@selected_date, "%A, %d de %B de %Y") %>
      </h3>
      <div class="overflow-x-auto">
        <div class="grid border border-gray-200 dark:border-gray-700" style={"grid-template-columns: 80px " <> String.duplicate("1fr ", length(@specialists)) <> ";"}>
          <!-- Time column header -->
          <div class="text-sm font-medium text-gray-500 dark:text-gray-400 p-2 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
            Hora
          </div>
          <!-- Specialist headers -->
          <%= for {name, id} <- @specialists do %>
            <div class="text-sm font-medium text-gray-900 dark:text-white p-2 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-center border-l border-gray-200 dark:border-gray-700 first:border-l-0">
              <div class="font-semibold"><%= name %></div>
              <div class="text-xs text-gray-500 dark:text-gray-400"></div>
            </div>
          <% end %>
          <!-- Time slots and activities -->
          <%= if @detail_view do %>
            <!-- Vista detalle con slots de 5 minutos -->
            <%= for hour <- 7..18 do %>
              <%= for minute <- [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55] do %>
                <!-- Time label -->
                <div class="text-sm text-gray-500 dark:text-gray-400 p-1 border-b border-gray-200 dark:border-gray-700 flex items-center bg-gray-50 dark:bg-gray-800">
                  <%= format_12h_time(hour, minute) %>
                </div>
                <!-- Activities for each specialist -->
                <%= for {_, specialist_id} <- @specialists do %>
                  <div class="time-slot border-b border-gray-200 dark:border-gray-700 border-l border-gray-200 dark:border-gray-700 min-h-[25px] p-1 agenda-eq-slot"
                        phx-click="new_activity_slot"
                        phx-value-date={Date.to_string(@selected_date)}
                        phx-value-hour={hour}
                        phx-value-minute={minute}
                        phx-value-specialist-id={specialist_id}
                        data-tooltip="Crear evento aquí"
                        data-date={Date.to_string(@selected_date)}
                        data-time={"#{hour}:#{String.pad_leading("#{minute}", 2, "0")}"}
                        id={"slot-#{specialist_id}-#{hour}-#{minute}"}>
                    <%= for activity <- get_activities_for_specialist_hour_and_minute(@activities_for_view, specialist_id, hour, minute) do %>
                      <div class="activity-item p-1 rounded mb-1 text-xs cursor-pointer bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 group"
                        draggable="true"
                        data-activity-id={activity.id}
                        data-specialist-id={specialist_id}
                        data-hour={hour}
                        data-minute={minute}
                        data-activity-status={activity.status}
                        data-slot-id={"slot-#{specialist_id}-#{hour}-#{minute}"}
                        title={build_activity_tooltip(activity)}>
                        <div class="flex items-center justify-between">
                          <div class="flex items-center min-w-0 flex-1">
                            <div class={[
                              "w-1.5 h-1.5 rounded-full mr-1 flex-shrink-0",
                              activity_color_dot(activity.type)
                            ]}></div>
                            <div class="font-medium truncate"><%= activity.title %></div>
                          </div>
                          <div class="flex items-center space-x-1 flex-shrink-0">
                            <div class="text-xs text-gray-500 dark:text-gray-400">
                              ⏰ <%= format_time(activity.due_date) %>
                            </div>
                            <div class="flex space-x-1">
                              <button class={"transition-opacity text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-0.5 border border-blue-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                      phx-click="edit_activity"
                                      phx-value-activity-id={activity.id}
                                      title="Editar evento">
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                                </svg>
                              </button>
                              <button class={"transition-opacity text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-0.5 border border-red-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                      phx-click="show_delete_confirm"
                                      phx-value-id={activity.id}
                                      phx-value-type="activity"
                                      title="Eliminar evento">
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                                </svg>
                              </button>
                            </div>
                          </div>
                        </div>
                        <div class="text-xs opacity-75 flex items-center gap-1">
                          <%= if activity.type == "maintenance" do %>
                            <span title="Mantenimiento"><svg class="inline w-4 h-4 text-blue-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg></span>
                            <span><%= if activity.truck, do: "Camión: #{activity.truck.brand} #{activity.truck.model} (#{activity.truck.license_plate})", else: "Mantenimiento de camión" %></span>
                          <% else %>
                            <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin cliente" %>
                            <%= if activity.service, do: " • " <> activity.service.name %>
                            <%= if activity.specialist, do: " • " <> activity.specialist.first_name %>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            <% end %>
          <% else %>
            <!-- Vista general con slots de 1 hora -->
            <%= for hour <- 7..18 do %>
              <!-- Time label -->
              <div class="text-sm text-gray-500 dark:text-gray-400 p-2 border-b border-gray-200 dark:border-gray-700 flex items-center bg-gray-50 dark:bg-gray-800">
                <%= format_12h_time(hour, 0) %>
              </div>
              <!-- Activities for each specialist -->
              <%= for {_, specialist_id} <- @specialists do %>
                <div class="time-slot border-b border-gray-200 dark:border-gray-700 border-l border-gray-200 dark:border-gray-700 min-h-[60px] p-1 agenda-eq-slot"
                      phx-click="new_activity_slot"
                      phx-value-date={Date.to_string(@selected_date)}
                      phx-value-hour={hour}
                      phx-value-specialist-id={specialist_id}
                      data-tooltip="Crear evento aquí"
                      data-date={Date.to_string(@selected_date)}
                      data-time={"#{hour}:00"}
                      id={"slot-#{specialist_id}-#{hour}-0"}>
                  <%= for activity <- Enum.filter(@activities_for_view, fn a ->
                    a.specialist_id == specialist_id and
                    a.due_date &&
                    (a.due_date |> DateTime.to_naive() |> Map.get(:hour)) == hour
                  end) do %>
                    <div class="activity-item p-2 rounded-lg mb-1 text-xs cursor-pointer bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 group"
                      draggable="true"
                      data-activity-id={activity.id}
                      data-specialist-id={specialist_id}
                      data-hour={hour}
                      data-activity-status={activity.status}
                      data-slot-id={"slot-#{specialist_id}-#{hour}-0"}
                      title={build_activity_tooltip(activity)}>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center min-w-0 flex-1">
                          <div class={[
                            "w-1.5 h-1.5 rounded-full mr-1 flex-shrink-0",
                            activity_color_dot(activity.type)
                          ]}></div>
                          <div class="font-medium truncate"><%= activity.title %></div>
                        </div>
                        <div class="flex items-center space-x-1 flex-shrink-0">
                          <div class="text-xs text-gray-500 dark:text-gray-400">
                            ⏰ <%= format_time(activity.due_date) %>
                          </div>
                          <div class="flex space-x-1">
                            <button class={"transition-opacity text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-0.5 border border-blue-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                    phx-click="edit_activity"
                                    phx-value-activity-id={activity.id}
                                    title="Editar evento">
                              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                              </svg>
                            </button>
                            <button class={"transition-opacity text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-0.5 border border-red-300 rounded bg-white dark:bg-gray-700 #{if @always_show_buttons, do: "opacity-100", else: "opacity-0 group-hover:opacity-100"}"}
                                    phx-click="show_delete_confirm"
                                    phx-value-id={activity.id}
                                    phx-value-type="activity"
                                    title="Eliminar evento">
                              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                      <div class="text-xs opacity-75 flex items-center gap-1">
                        <%= if activity.type == "maintenance" do %>
                          <span title="Mantenimiento"><svg class="inline w-4 h-4 text-blue-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg></span>
                          <span><%= if activity.truck, do: "Camión: #{activity.truck.brand} #{activity.truck.model} (#{activity.truck.license_plate})", else: "Mantenimiento de camión" %></span>
                        <% else %>
                          <%= if activity.contact, do: EvaaCrmGaepell.Contact.full_name(activity.contact), else: "Sin cliente" %>
                          <%= if activity.service, do: " • " <> activity.service.name %>
                          <%= if activity.specialist, do: " • " <> activity.specialist.first_name %>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
  """
  end

  @impl true
def handle_event("new_activity_slot", params, socket) do
  date = params["date"]
  time = params["time"]
  hour = params["hour"]
  minute = params["minute"]
  specialist_id = params["specialist-id"] || params["specialist_id"]

  # Parse date defensivamente
  case Date.from_iso8601(date) do
    {:ok, parsed_date} ->
      # Parse time defensivamente
      {h, m} =
        cond do
          time && String.match?(time, ~r/^\d{1,2}:\d{2}$/) ->
            [h, m] = String.split(time, ":") |> Enum.map(&String.to_integer/1)
            {h, m}
          hour && minute ->
            {String.to_integer(hour), String.to_integer(minute)}
          hour ->
            {String.to_integer(hour), 0}
          true ->
            {8, 0}
        end

      with {:ok, naive} <- NaiveDateTime.new(parsed_date, Time.new!(h, m, 0)),
           {:ok, due_date} <- DateTime.from_naive(naive, "Etc/UTC") do
        specialist_id = if specialist_id in [nil, "", 0], do: nil, else: String.to_integer(specialist_id)
        activity = %Activity{
          due_date: due_date,
          specialist_id: specialist_id
        }
        {:noreply,
         socket
         |> assign(:show_form, true)
         |> assign(:editing_activity, activity)}
      else
        _ ->
          {:noreply, put_flash(socket, :error, "No se pudo crear la fecha/hora para el evento")}
      end
    :error ->
      {:noreply, put_flash(socket, :error, "Fecha inválida para el evento")}
  end
end

@impl true
def handle_event("toggle_drag_mode", _params, socket) do
  {:noreply, assign(socket, :drag_mode, !socket.assigns.drag_mode)}
end

@impl true
def handle_event("toggle_filter_dropdown", _params, socket) do
  {:noreply, assign(socket, :show_filter_dropdown, !socket.assigns.show_filter_dropdown)}
end

@impl true
def handle_event("toggle_always_show_buttons", _params, socket) do
  {:noreply, assign(socket, :always_show_buttons, !socket.assigns.always_show_buttons)}
end

# Helper functions for duration formatting
defp format_duration(minutes) when is_integer(minutes) do
  cond do
    minutes < 60 -> "#{minutes} min"
    minutes == 60 -> "1 hora"
    minutes < 120 -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
    minutes == 120 -> "2 horas"
    minutes < 180 -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
    minutes == 180 -> "3 horas"
    minutes < 240 -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
    minutes == 240 -> "4 horas"
    minutes < 360 -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
    minutes == 360 -> "6 horas"
    minutes == 480 -> "8 horas"
    true -> "#{div(minutes, 60)}h #{rem(minutes, 60)}m"
  end
end

defp format_duration(_), do: "Sin duración"

defp format_time_range(start_time, duration_minutes) when is_integer(duration_minutes) do
  end_time = DateTime.add(start_time, duration_minutes * 60, :second)
  start_str = format_time(start_time)
  end_str = format_time(end_time)
  "#{start_str} - #{end_str}"
end

defp format_time_range(_, _), do: ""

# Helper para obtener el nombre de la empresa seleccionada
defp selected_company_name(company_id, companies) do
  case Enum.find(companies, fn {name, id} -> id == company_id end) do
    {name, _} -> name
    _ -> nil
  end
end

@impl true
def handle_event("edit_ticket_from_activity", %{"ticket-id" => ticket_id}, socket) do
  send(self(), {:show_ticket_modal, ticket_id})
  {:noreply, socket}
end

@impl true
def handle_info({:show_ticket_modal, ticket_id}, socket) do
  ticket = EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.MaintenanceTicket, ticket_id) |> EvaaCrmGaepell.Repo.preload(:truck)
  changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(ticket, %{})
  {:noreply,
   socket
   |> assign(:show_ticket_modal, true)
   |> assign(:editing_ticket, changeset)
   |> assign(:trucks, EvaaCrmGaepell.Fleet.list_trucks())}
end

@impl true
def handle_event("save_ticket_from_agenda", %{"maintenance_ticket" => ticket_params}, socket) do
  editing_ticket = socket.assigns.editing_ticket && socket.assigns.editing_ticket.data
  result =
    if editing_ticket && editing_ticket.id do
      EvaaCrmGaepell.Fleet.update_maintenance_ticket(editing_ticket, ticket_params, socket.assigns.current_user && socket.assigns.current_user.id)
    else
      EvaaCrmGaepell.Fleet.create_maintenance_ticket(ticket_params)
    end
  case result do
    {:ok, _ticket} ->
      {:noreply,
       socket
       |> put_flash(:info, "Ticket guardado exitosamente")
       |> assign(:show_ticket_modal, false)
       |> assign(:editing_ticket, nil)
       |> load_activities()}
    {:error, changeset} ->
      {:noreply, assign(socket, :editing_ticket, changeset)}
    {:error, _reason} ->
      {:noreply, put_flash(socket, :error, "Error al guardar el ticket")}
  end
end

@impl true
def handle_event("hide_ticket_modal", _params, socket) do
  {:noreply, socket |> assign(:show_ticket_modal, false) |> assign(:editing_ticket, nil)}
end

end
