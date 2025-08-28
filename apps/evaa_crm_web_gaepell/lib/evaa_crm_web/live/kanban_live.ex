defmodule EvaaCrmWebGaepell.KanbanLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Activity, MaintenanceTicket, ProductionOrder, Company, Truck, Repo, WorkflowService, Workflow, WorkflowState, Lead}
  import Ecto.Query
  import Phoenix.HTML.Form
  import Phoenix.Naming
  alias EvaaCrmWebGaepell.AuthHelper
  alias EvaaCrmGaepell.MaintenanceTicketCheckout

  # Ruta absoluta para los uploads
  @uploads_dir Path.expand("priv/static/uploads")

  @default_filters %{tipo: "todos", workflow: "todos", compania: "1", camion: "todos", fecha: "todos"}

  @gaepell_companies [
    %{id: 1, nombre: "Furcar", color: "#2563eb", badge: "bg-blue-700 text-white"},
    %{id: 2, nombre: "Blidomca", color: "#f59e42", badge: "bg-orange-600 text-white"},
    %{id: 3, nombre: "Polimat", color: "#7c3aed", badge: "bg-purple-700 text-white"}
  ]

  @impl true
  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(EvaaCrmGaepell.PubSub, "feedbacks:updated")
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil

    # Stats globales
    stats = get_dashboard_stats()
    recent_activities = get_recent_activities()
    activity_chart_data = get_activity_chart_data()
    status_distribution_data = get_status_distribution_data()

    {
      :ok,
      socket
      |> assign(:current_user, current_user)
      |> assign(:page_title, "Kanban Dashboard")
      |> assign(:filters, @default_filters)
      |> assign(:items, [])
      |> assign(:loading, false)
      |> assign(:show_modal, false)
      |> assign(:modal_item, nil)
      |> assign(:modal_changeset, nil)
      |> assign(:modal_type, nil)
      |> assign(:current_view, "integrated")
      |> assign(:workflow_type, nil)
      |> assign(:companias, gaepell_companies())
      |> assign(:camiones, [])
      |> assign(:workflows, [])
      |> allow_upload(:damage_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
      |> assign(:show_ticket_details_modal, false)
      |> assign(:ticket_details, nil)
      |> assign(:show_lead_details_modal, false)
      |> assign(:lead_details, nil)
      |> assign(:show_production_details_modal, false)
      |> assign(:production_details, nil)
      |> assign(:current_tab, "dashboard")
      |> assign(:show_ticket_profile, false)
      |> assign(:selected_ticket, nil)
      |> assign(:ticket_logs, [])
      |> assign(:ticket_checkouts, [])
      |> assign(:dashboard_stats, stats)
      |> assign(:dashboard_recent_activities, recent_activities)
      |> assign(:activity_chart_data, activity_chart_data)
      |> assign(:status_distribution_data, status_distribution_data)
    }
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_and_clean_filters(params)
    
    # Determinar la vista actual basada en los parámetros
    current_view = case params do
      %{"view" => view} -> view
      %{"workflow" => _workflow} -> "individual"
      _ -> "integrated"
    end
    
    # Si es vista individual, asegurar que Furcar esté seleccionado por defecto
    filters = if current_view == "individual" do
      Map.put(filters, :compania, "1")
    else
      filters
    end
    
    # Determinar el tipo de workflow si estamos en vista individual
    workflow_type = case params do
      %{"workflow" => workflow_id} when is_binary(workflow_id) ->
        case Integer.parse(workflow_id) do
          {id, _} -> 
            workflow = Repo.get(Workflow, id)
            if workflow, do: workflow.workflow_type, else: nil
          :error -> nil
        end
      _ -> nil
    end
    
    # Cargar datos según la vista
    {items, workflows, camiones} = case current_view do
      "integrated" ->
        items = load_kanban_items(filters, current_view)
        workflows = Repo.all(from w in Workflow, where: w.is_active == true)
        camiones = load_trucks_for_company(filters[:compania])
        {items, workflows, camiones}
      "individual" ->
        items = load_kanban_items(filters, current_view)
        workflows = Repo.all(from w in Workflow, where: w.is_active == true)
        camiones = load_trucks_for_company(filters[:compania])
        {items, workflows, camiones}
      _ ->
        items = load_kanban_items(filters, "integrated")
        workflows = Repo.all(from w in Workflow, where: w.is_active == true)
        camiones = load_trucks_for_company(filters[:compania])
        {items, workflows, camiones}
    end
    
    {:noreply, 
      socket
      |> assign(:filters, filters)
      |> assign(:items, items)
      |> assign(:current_view, current_view)
      |> assign(:workflow_type, workflow_type)
      |> assign(:workflows, workflows)
      |> assign(:camiones, camiones)
    }
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    normalized_filters = normalize_and_clean_filters(filters)
    {:noreply, push_patch(socket, to: kanban_path(normalized_filters))}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket =
      if tab == "dashboard" do
        stats = get_dashboard_stats()
        recent_activities = get_recent_activities()
        activity_chart_data = get_activity_chart_data()
        status_distribution_data = get_status_distribution_data()
        # Notificación push solo si hay actividades
        socket = assign(socket, dashboard_stats: stats, dashboard_recent_activities: recent_activities, activity_chart_data: activity_chart_data, status_distribution_data: status_distribution_data)
        if recent_activities != [] do
          act = hd(recent_activities)
          msg = case act.type do
            :ticket -> "Nuevo ticket creado: #{act.title}"
            :lead -> "Nuevo lead: #{act.title}"
            :order -> "Nueva orden: #{act.title}"
            :activity -> "Nueva actividad: #{act.title}"
            :feedback -> "Nuevo bug/feedback: #{act.title}"
            :feedback_comment -> "Nuevo comentario en bug: #{act.title}"
            _ -> "Nueva actividad"
          end
          push_event(socket, "actividad_reciente", %{message: msg})
        else
          socket
        end
      else
        socket
      end
    {:noreply, assign(socket, :current_tab, tab)}
  end

  @impl true
  def handle_event("move_card", %{"item_id" => _item_id, "from" => _from, "to" => _to}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("kanban:move", %{"id" => id, "new_status" => new_status, "old_status" => _old_status, "workflow_id" => workflow_id}, socket) do
    IO.puts("[DEBUG] kanban:move event received")
    IO.puts("[DEBUG] id: #{id}")
    IO.puts("[DEBUG] new_status: #{new_status}")
    IO.puts("[DEBUG] workflow_id: #{workflow_id}")
    
    # Determinar el tipo de item basado en el ID
    case String.split(id, "-") do
      ["a", activity_id] ->
        # Es una actividad
        activity = Repo.get(Activity, String.to_integer(activity_id))
        if activity do
          # Actualizar el estado de la actividad
          changeset = Activity.changeset(activity, %{status: new_status})
          case Repo.update(changeset) do
            {:ok, _updated_activity} ->
              IO.puts("[DEBUG] Activity #{activity_id} updated to status: #{new_status}")
            {:error, changeset} ->
              IO.puts("[ERROR] Failed to update activity: #{inspect(changeset.errors)}")
          end
        end
        
      ["t", ticket_id] ->
        # Es un ticket de mantenimiento
        ticket = Repo.get(MaintenanceTicket, String.to_integer(ticket_id))
        if ticket do
          # Actualizar el estado del ticket
          changeset = MaintenanceTicket.changeset(ticket, %{status: new_status})
          case Repo.update(changeset) do
            {:ok, _updated_ticket} ->
              IO.puts("[DEBUG] Ticket #{ticket_id} updated to status: #{new_status}")
            {:error, changeset} ->
              IO.puts("[ERROR] Failed to update ticket: #{inspect(changeset.errors)}")
          end
        end
        
      ["l", lead_id] ->
        # Es un lead
        lead = Repo.get(Lead, String.to_integer(lead_id))
        if lead do
          old_status = lead.status
          changeset = Lead.changeset(lead, %{status: new_status})
          case Repo.update(changeset) do
            {:ok, updated_lead} ->
              IO.puts("[DEBUG] Lead #{lead_id} status field updated from #{old_status} to #{new_status}")
              
              # Si el estado cambió a "converted", crear contacto y orden de producción
              if new_status == "converted" do
                IO.puts("[DEBUG] Lead converted, creating contact and production order...")
                case convert_lead_to_contact_and_production_order(updated_lead) do
                  {:ok, _contact} ->
                    IO.puts("[DEBUG] ✅ Lead converted successfully: contact and production order created")
                  {:error, error} ->
                    IO.puts("[ERROR] ❌ Failed to convert lead: #{inspect(error)}")
                end
              end
              
              # Si el estado cambió desde "converted" a otro estado, revertir la conversión
              if old_status == "converted" and new_status != "converted" do
                IO.puts("[DEBUG] Lead reverted from converted, removing contact and production order...")
                case revert_lead_conversion(updated_lead) do
                  {:ok, _result} ->
                    IO.puts("[DEBUG] ✅ Lead conversion reverted successfully")
                  {:error, error} ->
                    IO.puts("[ERROR] ❌ Failed to revert lead conversion: #{inspect(error)}")
                end
              end
              
              # Broadcast para que otros LiveViews recarguen leads
              Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, lead.id, new_status})
            {:error, changeset} ->
              IO.puts("[ERROR] Failed to update lead status field: #{inspect(changeset.errors)}")
          end
        end
        
      ["p", production_order_id] ->
        # Es una orden de producción
        production_order = Repo.get(ProductionOrder, String.to_integer(production_order_id))
        if production_order do
          # Actualizar el estado de la orden de producción
          changeset = ProductionOrder.changeset(production_order, %{status: new_status})
          case Repo.update(changeset) do
            {:ok, updated_order} ->
              IO.puts("[DEBUG] Production Order #{production_order_id} updated to status: #{new_status}")
              
              # Si el estado cambió a "check_out", crear automáticamente una nueva orden de producción
              if new_status == "check_out" do
                IO.puts("[DEBUG] Production order reached check_out status, creating new order...")
                case create_new_production_order_from_completed(updated_order) do
                  {:ok, new_order} ->
                    IO.puts("[DEBUG] ✅ New production order created successfully: #{new_order.id}")
                  {:error, changeset} ->
                    IO.puts("[ERROR] ❌ Failed to create new production order: #{inspect(changeset.errors)}")
                end
              end
              
            {:error, changeset} ->
              IO.puts("[ERROR] Failed to update production order: #{inspect(changeset.errors)}")
          end
        end
        
      _ ->
        IO.puts("[ERROR] Unknown item type for id: #{id}")
    end
    
    # Recargar los items del Kanban
    filters = socket.assigns.filters
    current_view = socket.assigns.current_view
    items = load_kanban_items(filters, current_view)
    
    {:noreply, assign(socket, items: items)}
  end

  @impl true
    def handle_event("filter_chip", %{"key" => key, "value" => value}, socket) do
    IO.puts("[DEBUG] ===== filter_chip EVENT RECEIVED =====")
    IO.puts("[DEBUG] key: #{key}")
    IO.puts("[DEBUG] value: #{value}")
    IO.puts("[DEBUG] value type: #{inspect(value)}")
    
    # Si el valor está vacío, no hacer nada
    if value == "" or value == nil do
      IO.puts("[DEBUG] Value is empty, ignoring event")
      {:noreply, socket}
    else
      filters = socket.assigns.filters
      current_view = socket.assigns.current_view
      
      IO.puts("[DEBUG] Current filters before: #{inspect(filters)}")
      IO.puts("[DEBUG] Current view: #{current_view}")
      
      # Si se está cambiando el filtro de compañía
      if key == "compania" do
        # Si la nueva compañía no es Furcar (business_id = 1), limpiar el filtro de camión
        filters = if value != "1" do
          Map.put(filters, :camion, "todos")
        else
          filters
        end
        
        # Actualizar la lista de camiones según la compañía seleccionada
        camiones = case value do
          "1" -> 
            # Solo camiones de Furcar
            Repo.all(from t in Truck, 
              where: t.business_id == 1,
              select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
          "2" -> 
            # Solo camiones de Blidomca
            Repo.all(from t in Truck, 
              where: t.business_id == 2,
              select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
          "3" -> 
            # Solo camiones de Polimat
            Repo.all(from t in Truck, 
              where: t.business_id == 3,
              select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
          _ -> 
            # Por defecto, camiones de Furcar
            Repo.all(from t in Truck, 
              where: t.business_id == 1,
              select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
        end
        
        # Aplicar el nuevo filtro
        filters = Map.put(filters, String.to_atom(key), value)
        
        # Recargar los items con los nuevos filtros
        items = load_kanban_items(filters, current_view)
        
        # Actualizar todos los assigns inmediatamente
        IO.puts("[DEBUG] Final filters: #{inspect(filters)}")
        IO.puts("[DEBUG] Items loaded: #{length(items)} workflows")
        IO.puts("[DEBUG] Camiones loaded: #{length(camiones)} trucks")
        
        {:noreply, 
          socket
          |> assign(:filters, filters)
          |> assign(:camiones, camiones)
          |> assign(:items, items)
          |> push_patch(to: kanban_path(filters))
        }
      else
        # Para otros filtros, aplicar el filtro y recargar
        filters = Map.put(filters, String.to_atom(key), value)
        items = load_kanban_items(filters, current_view)
        
        IO.puts("[DEBUG] Other filter - Final filters: #{inspect(filters)}")
        IO.puts("[DEBUG] Other filter - Items loaded: #{length(items)} workflows")
        
        {:noreply, 
          socket
          |> assign(:filters, filters)
          |> assign(:items, items)
          |> push_patch(to: kanban_path(filters))
        }
      end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: "/")}
  end



  @impl true
  def handle_event("show_modal", %{"id" => id}, socket) do
    case String.split(id, "-") do
      ["a", activity_id] ->
        item = EvaaCrmGaepell.Activity |> EvaaCrmGaepell.Repo.get(String.to_integer(activity_id))
        changeset = if item, do: EvaaCrmGaepell.Activity.changeset(item, %{}), else: nil
        {:noreply, assign(socket, modal_item: item, show_modal: true, modal_changeset: changeset, modal_type: "evento")}
      ["t", ticket_id] ->
        # Use the ticket_profile_modal instead of the inline modal
        ticket = Repo.get(MaintenanceTicket, String.to_integer(ticket_id)) |> Repo.preload([:truck, :specialist])
        logs = EvaaCrmGaepell.ActivityLog.get_logs_for_entity("maintenance_ticket", ticket_id)
        checkouts = Repo.all(from c in MaintenanceTicketCheckout, where: c.maintenance_ticket_id == ^String.to_integer(ticket_id), order_by: [desc: c.inserted_at])
        {:noreply, 
         socket
         |> assign(:show_ticket_profile, true)
         |> assign(:selected_ticket, ticket)
         |> assign(:ticket_logs, logs)
         |> assign(:ticket_checkouts, checkouts)
        }
      ["p", production_order_id] ->
        item = EvaaCrmGaepell.ProductionOrder |> EvaaCrmGaepell.Repo.get(String.to_integer(production_order_id))
        changeset = if item, do: EvaaCrmGaepell.ProductionOrder.changeset(item, %{}), else: nil
        {:noreply, assign(socket, modal_item: item, show_modal: true, modal_changeset: changeset, modal_type: "production")}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, modal_item: nil, modal_changeset: nil)}
  end

  @impl true
  def handle_event("save_modal_ticket", %{"maintenance_ticket" => params}, socket) do
    ticket = socket.assigns.modal_item
    upload = socket.assigns.uploads.damage_photos
    
    # Check if any files are still uploading
    uploading_files = Enum.any?(upload.entries, fn entry -> !entry.done? end)
    if uploading_files do
      {:noreply, put_flash(socket, :error, "Espera a que se completen todas las subidas antes de guardar")}
    else
      uploaded_files = consume_uploaded_entries(socket, :damage_photos, fn %{path: path} = meta, entry ->
        IO.inspect(meta, label: "[DEBUG] meta")
        IO.inspect(entry, label: "[DEBUG] entry")
        filename = "ticket_#{ticket && ticket.id || "new"}_#{System.system_time()}.jpg"
        dest = Path.join([@uploads_dir, filename])
        IO.puts("[DEBUG] Copiando de #{path} a #{dest}")
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)
        IO.puts("[DEBUG] Archivo copiado exitosamente")
        {:ok, "/uploads/#{filename}"}
      end)
      IO.inspect(uploaded_files, label: "[DEBUG] uploaded_files")
      
      # Fix: uploaded_files is already a list of URLs, not tuples
      photo_urls = Enum.map(uploaded_files, fn 
        {:ok, url} -> url
        url when is_binary(url) -> url
        _ -> nil
      end) |> Enum.filter(& &1)
      
      IO.inspect(photo_urls, label: "[DEBUG] photo_urls")
      
      # Merge with existing photos if editing
      params = if ticket && ticket.damage_photos do
        Map.update(params, "damage_photos", ticket.damage_photos ++ photo_urls, fn old ->
          (old || []) ++ photo_urls
        end)
      else
        Map.put(params, "damage_photos", photo_urls)
      end
      
      IO.inspect(params, label: "[DEBUG] params before save")
      
      _changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(ticket, params)
      case EvaaCrmGaepell.Fleet.update_maintenance_ticket(ticket, params, socket.assigns.current_user && socket.assigns.current_user.id) do
        {:ok, _ticket} ->
          filters = socket.assigns[:filters] || @default_filters
          {:noreply,
            socket
            |> assign(show_modal: false, modal_item: nil, modal_changeset: nil)
            |> assign(items: load_kanban_items(filters))
            |> put_flash(:info, "Ticket actualizado exitosamente")
          }
        {:error, changeset} ->
          {:noreply, assign(socket, modal_changeset: changeset)}
      end
    end
  end

  @impl true
  def handle_event("new_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: true, modal_item: nil, modal_changeset: nil, modal_type: nil)}
  end

  @impl true
  def handle_event("select_modal_type", %{"type" => "ticket"}, socket) do
    changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(%EvaaCrmGaepell.MaintenanceTicket{}, %{})
    {:noreply, assign(socket, modal_type: "ticket", modal_item: %EvaaCrmGaepell.MaintenanceTicket{}, modal_changeset: changeset)}
  end

  @impl true
  def handle_event("select_modal_type", %{"type" => "evento"}, socket) do
    # Placeholder: en el futuro, aquí se prepara el changeset de Activity
    {:noreply, assign(socket, modal_type: "evento", modal_item: nil, modal_changeset: nil)}
  end

  @impl true
  def handle_event("change_view", %{"view" => view_type}, socket) do
    filters = socket.assigns.filters
    items = load_kanban_items(filters, view_type)
    {:noreply, assign(socket, current_view: view_type, items: items)}
  end

  @impl true
  def handle_event("change_company", %{"company" => company_id}, socket) do
    current_view = socket.assigns.current_view
    filters = Map.put(socket.assigns.filters, :compania, company_id)
    items = load_kanban_items(filters, current_view)
    {:noreply, assign(socket, filters: filters, items: items)}
  end

  @impl true
  def handle_event("change_truck", %{"truck" => truck_id}, socket) do
    current_view = socket.assigns.current_view
    filters = Map.put(socket.assigns.filters, :camion, truck_id)
    items = load_kanban_items(filters, current_view)
    {:noreply, assign(socket, filters: filters, items: items)}
  end

  @impl true
  def handle_event("ignore", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("show_item_details", %{"id" => id}, socket) do
    case String.split(id, "-") do
      ["t", ticket_id] ->
        ticket = EvaaCrmGaepell.MaintenanceTicket
          |> EvaaCrmGaepell.Repo.get(String.to_integer(ticket_id))
          |> EvaaCrmGaepell.Repo.preload([:truck, :specialist])
        logs = EvaaCrmGaepell.ActivityLog.get_logs_for_entity("maintenance_ticket", ticket_id)
        checkouts = EvaaCrmGaepell.Repo.all(from c in EvaaCrmGaepell.MaintenanceTicketCheckout, where: c.maintenance_ticket_id == ^String.to_integer(ticket_id), order_by: [desc: c.inserted_at])
        {:noreply, 
         socket
         |> assign(:show_ticket_profile, true)
         |> assign(:selected_ticket, ticket)
         |> assign(:ticket_logs, logs)
         |> assign(:ticket_checkouts, checkouts)
         |> assign(:lead_details, nil)
         |> assign(:show_lead_details_modal, false)
         |> assign(:production_details, nil)
         |> assign(:show_production_details_modal, false)
        }
      ["l", lead_id] ->
        lead = EvaaCrmGaepell.Lead |> EvaaCrmGaepell.Repo.get(String.to_integer(lead_id))
        {:noreply, assign(socket, lead_details: lead, show_lead_details_modal: true, ticket_details: nil, show_ticket_details_modal: false, production_details: nil, show_production_details_modal: false)}
      ["p", production_id] ->
        production = EvaaCrmGaepell.ProductionOrder |> EvaaCrmGaepell.Repo.get(String.to_integer(production_id))
        {:noreply, assign(socket, production_details: production, show_production_details_modal: true, ticket_details: nil, show_ticket_details_modal: false, lead_details: nil, show_lead_details_modal: false)}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_ticket_details", _params, socket) do
    {:noreply, assign(socket, show_ticket_details_modal: false, ticket_details: nil, show_lead_details_modal: false, lead_details: nil, show_production_details_modal: false, production_details: nil)}
  end

  @impl true
  def handle_event("progress", %{"entry" => entry, "progress" => progress}, socket) do
    IO.puts("[DEBUG] Upload progress for #{entry}: #{progress}%")
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_photo", %{"url" => photo_url}, socket) do
    modal_item = socket.assigns.modal_item
    
    if modal_item && modal_item.damage_photos do
      # Remove the photo from the list
      updated_photos = Enum.reject(modal_item.damage_photos, fn url -> url == photo_url end)
      
      # Update the changeset with the new photos list
      changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(modal_item, %{damage_photos: updated_photos})
      
      {:noreply, assign(socket, modal_changeset: changeset, modal_item: %{modal_item | damage_photos: updated_photos})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :damage_photos, ref)}
  end

  @impl true
  def handle_event("new_ticket", %{"workflow" => _workflow_id}, socket) do
    # Replicar lógica de /maintenance para nuevo ticket
    changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(%EvaaCrmGaepell.MaintenanceTicket{}, %{})
    {:noreply, assign(socket, show_modal: true, modal_type: "ticket", modal_item: %EvaaCrmGaepell.MaintenanceTicket{}, modal_changeset: changeset)}
  end

  @impl true
  def handle_event("new_lead", %{"workflow" => _workflow_id}, socket) do
    # Replicar lógica de /prospectos para nuevo lead
    changeset = EvaaCrmGaepell.Lead.changeset(%EvaaCrmGaepell.Lead{}, %{})
    {:noreply, assign(socket, show_modal: true, modal_type: "lead", modal_item: %EvaaCrmGaepell.Lead{}, modal_changeset: changeset)}
  end

  @impl true
  def handle_event("new_production_order", %{"workflow" => _workflow_id}, socket) do
    # Replicar lógica de /trucks para nueva orden de producción
    changeset = EvaaCrmGaepell.ProductionOrder.changeset(%EvaaCrmGaepell.ProductionOrder{}, %{})
    {:noreply, assign(socket, show_modal: true, modal_type: "production", modal_item: %EvaaCrmGaepell.ProductionOrder{}, modal_changeset: changeset)}
  end

  @impl true
  def handle_event("show_ticket_profile", %{"ticket_id" => ticket_id}, socket) do
    ticket = Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload([:truck, :specialist])
    logs = EvaaCrmGaepell.ActivityLog.get_logs_for_entity("maintenance_ticket", ticket_id)
    checkouts = Repo.all(from c in MaintenanceTicketCheckout, where: c.maintenance_ticket_id == ^ticket_id, order_by: [desc: c.inserted_at])
    
    {:noreply, 
     socket
     |> assign(:show_ticket_profile, true)
     |> assign(:selected_ticket, ticket)
     |> assign(:ticket_logs, logs)
     |> assign(:ticket_checkouts, checkouts)}
  end

  @impl true
  def handle_event("hide_ticket_profile", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_ticket_profile, false)
     |> assign(:selected_ticket, nil)
     |> assign(:ticket_logs, [])
     |> assign(:ticket_checkouts, [])}
  end

  @impl true
  def handle_event("edit_ticket_from_profile", %{"ticket_id" => ticket_id}, socket) do
    # Cerrar el modal de perfil
    socket = socket
     |> assign(:show_ticket_profile, false)
     |> assign(:selected_ticket, nil)
     |> assign(:ticket_logs, [])
    
    # Abrir el modal de edición
    ticket = Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload(:truck)
    ticket_changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(ticket, %{
      truck_id: ticket.truck_id,
      entry_date: ticket.entry_date,
      mileage: ticket.mileage,
      fuel_level: ticket.fuel_level,
      status: ticket.status,
      title: ticket.title,
      visible_damage: ticket.visible_damage,
      exit_notes: ticket.exit_notes,
      color: ticket.color,
      damage_photos: ticket.damage_photos
    })
    
    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:modal_type, "ticket")
     |> assign(:modal_item, ticket)
     |> assign(:modal_changeset, ticket_changeset)}
  end

  defp normalize_and_clean_filters(params) do
    normalized_params = 
      params
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Enum.into(%{})
      |> Enum.map(fn {k, v} -> 
        cleaned_value = case v do
          nil -> @default_filters[k]
          "" -> @default_filters[k]
          value when is_binary(value) -> 
            if String.trim(value) == "", do: @default_filters[k], else: value
          value -> value
        end
        {k, cleaned_value}
      end)
      |> Enum.into(%{})
    @default_filters |> Map.merge(normalized_params)
  end

  defp load_kanban_items(filters, current_view \\ "integrated") do
    # Obtener empresa seleccionada
    _selected_company_id = get_selected_company_id(filters)
    
    # Obtener workflows activos filtrados por empresa
    workflows = Repo.all(from w in Workflow, 
      where: w.is_active == true,
      preload: [workflow_states: ^(from ws in WorkflowState, order_by: ws.order_index)])
    |> filter_workflows_by_company(_selected_company_id)
    
    # Cargar actividades, tickets, órdenes de producción y leads con filtros por empresa
    activities = load_activities_with_company_filters(filters, _selected_company_id)
    tickets = load_tickets_with_company_filters(filters, _selected_company_id)
    production_orders = load_production_orders_with_company_filters(filters, _selected_company_id)
    leads = load_leads_with_company_filters(filters, _selected_company_id)
    
    case current_view do
      "integrated" ->
        # Vista integrada - workflows específicos de la empresa
        create_integrated_view(workflows, activities, tickets, production_orders, leads, _selected_company_id)
      "individual" ->
        # Vista individual - mostrar workflows según la compañía
        create_individual_workflow_view(workflows, activities, tickets, production_orders, leads, filters)
      _ ->
        create_integrated_view(workflows, activities, tickets, production_orders, leads, _selected_company_id)
    end
  end

  defp get_selected_company_id(filters) do
    case filters[:compania] do
      "1" -> 1  # Furcar
      "2" -> 2  # Blidomca
      "3" -> 3  # Polimat
      _ -> 1    # Default a Furcar
    end
  end

  defp load_activities_with_company_filters(filters, company_id) do
    from(a in Activity, order_by: a.due_date)
    |> apply_company_specific_filters(company_id, filters)
    |> Repo.all()
  end

  defp load_tickets_with_company_filters(filters, company_id) do
    from(m in MaintenanceTicket, order_by: m.inserted_at)
    |> apply_company_specific_filters(company_id, filters)
    |> Repo.all()
  end

  defp load_production_orders_with_company_filters(filters, company_id) do
    from(po in ProductionOrder, order_by: po.inserted_at)
    |> apply_company_specific_filters(company_id, filters)
    |> Repo.all()
  end

  defp load_leads_with_company_filters(filters, company_id) do
    leads = from(l in Lead, order_by: l.inserted_at)
    |> apply_company_specific_filters(company_id, filters)
    |> Repo.all()
    
    IO.puts("[DEBUG] Leads cargados: #{length(leads)}")
    Enum.each(leads, fn lead ->
      IO.puts("[DEBUG] Lead #{lead.id}: status=#{lead.status}, name=#{lead.name}")
    end)
    
    leads
  end

  defp create_integrated_view(workflows, activities, tickets, production_orders, leads, selected_company_id) do
    # Crear estructura horizontal por workflow
    workflows
    |> Enum.map(fn workflow ->
      workflow_states = workflow.workflow_states
      
      # Procesar items para este workflow específico
      workflow_items = case workflow.workflow_type do
        "events" -> 
          activities
          |> Enum.filter(fn activity -> is_nil(activity.maintenance_ticket_id) end)
          |> Enum.map(fn activity -> 
            %{
              id: activity.id,
              title: activity.title,
              description: activity.description,
              status: get_activity_status(activity),
              workflow_type: "events",
              business_id: activity.business_id,
              specialist_id: activity.specialist_id,
              due_date: activity.due_date,
              priority: activity.priority,
              company_name: get_company_name(activity.business_id),
              truck_name: nil,
              created_at: activity.inserted_at
            }
          end)
        
        "maintenance" -> 
          tickets
          |> Enum.map(fn ticket -> 
            %{
              id: ticket.id,
              title: ticket.title,
              description: ticket.description,
              status: get_ticket_status(ticket),
              workflow_type: "maintenance",
              business_id: ticket.business_id,
              specialist_id: ticket.specialist_id,
              due_date: ticket.entry_date,
              priority: ticket.priority,
              company_name: get_company_name(ticket.business_id),
              truck_name: get_truck_name(ticket.truck_id),
              created_at: ticket.inserted_at
            }
          end)
        
        "production" -> 
          production_orders
          |> Enum.map(fn po -> 
            %{
              id: po.id,
              title: "#{po.client_name} - #{po.truck_brand} #{po.truck_model} (#{EvaaCrmGaepell.ProductionOrder.box_type_label(po.box_type)})",
              description: po.specifications || "Orden de producción",
              status: get_production_status(po),
              workflow_type: "production",
              business_id: po.business_id,
              specialist_id: po.specialist_id,
              due_date: po.estimated_delivery,
              priority: "medium",
              company_name: get_company_name(po.business_id),
              truck_name: "#{po.truck_brand} #{po.truck_model} (#{po.license_plate})",
              created_at: po.inserted_at
            }
          end)
        
        "leads" -> 
          # Usar los leads ya cargados
          leads
          |> Enum.map(fn lead -> 
            %{
              id: lead.id,
              title: lead.name || "Lead #{lead.id}",
              description: lead.notes || "Lead",
              status: lead.status || "new",
              workflow_id: nil,
              workflow_type: "leads",
              color: "#10B981",
              company_name: get_company_name(lead.business_id),
              truck_name: nil,
              due_date: lead.next_follow_up,
              priority: "medium",
              specialist_name: get_specialist_name(lead.assigned_to),
              created_at: lead.inserted_at
            }
          end)
        
        _ -> []
      end
      
              # Agrupar items por estado del workflow
        items_by_state = workflow_states
        |> Enum.map(fn state ->
          state_items = workflow_items
          |> Enum.filter(fn item -> 
            # Usar directamente los estados del workflow
            item.status == state.name
          end)
        
        %{
          workflow_id: workflow.id,
          workflow_name: workflow.name,
          workflow_type: workflow.workflow_type,
          state: state,
          items: state_items,
          count: length(state_items)
        }
      end)
      
      %{
        workflow: workflow,
        states: items_by_state,
        total_items: length(workflow_items)
      }
    end)
  end



  defp create_individual_workflow_view(workflows, activities, tickets, production_orders, leads, filters) do
    # Obtener compañía seleccionada
    company_id = case filters[:compania] do
      "1" -> 1  # Furcar
      "2" -> 2  # Blidomca
      "3" -> 3  # Polimat
      _ -> 1    # Default a Furcar
    end

    # Usar la vista integrada para todas las empresas (unificación)
    create_integrated_view(workflows, activities, tickets, production_orders, leads, company_id)
  end

  defp process_all_items(workflows, activities, tickets) do
    # Procesar actividades
    activities_items = activities
    |> Enum.map(fn activity ->
      current_state = if activity.status == "completed" do
        "completed"
      else
        "pending"
      end
      
      %{
        id: "a-#{activity.id}",
        title: activity.title,
        description: activity.description,
        status: current_state,
        workflow_id: nil,
        workflow_type: nil,
        color: activity.color || "#3B82F6",
        company_name: get_company_name(activity.business_id),
        truck_name: get_truck_name(activity.truck_id),
        due_date: activity.due_date,
        priority: activity.priority,
        specialist_name: get_specialist_name(activity.specialist_id),
        created_at: activity.inserted_at
      }
    end)
    
    # Procesar tickets
    tickets_items = tickets
    |> Enum.map(fn ticket ->
      current_state = if ticket.status == "completed" do
        "completed"
      else
        "pending"
      end
      
      %{
        id: "t-#{ticket.id}",
        title: ticket.title,
        description: ticket.description,
        status: current_state,
        workflow_id: nil,
        workflow_type: nil,
        color: ticket.color || "#F59E0B",
        company_name: get_company_name(ticket.business_id),
        truck_name: get_truck_name(ticket.truck_id),
        due_date: ticket.entry_date,
        priority: ticket.priority,
        specialist_name: get_specialist_name(ticket.specialist_id),
        created_at: ticket.inserted_at
      }
    end)
    
    activities_items ++ tickets_items
  end

  defp normalize_status(status) do
    case status do
      "pending" -> "pending"
      "open" -> "pending"
      "in_progress" -> "in_progress"
      "in_review" -> "review"
      "review" -> "review"
      "completed" -> "completed"
      "done" -> "completed"
      "closed" -> "completed"
      _ -> "pending"
    end
  end

  defp item_label(%{tipo: "ticket"}), do: "Ticket"
  defp item_label(%{tipo: "evento"}), do: "Evento"
  defp item_label(_), do: "Item"

  defp kanban_path(filters) do
    query =
      filters
      |> Enum.filter(fn {k, v} -> v != @default_filters[k] end)
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("&")
    if query == "", do: "/", else: "/?" <> query
  end

  defp gaepell_companies, do: @gaepell_companies

  defp filter_workflows_by_company(workflows, company_id) do
    allowed_types = get_workflow_types_for_company(company_id)
    
    workflows
    |> Enum.filter(fn workflow -> 
      workflow.workflow_type in allowed_types and workflow.business_id == company_id
    end)
  end

  defp apply_company_specific_filters(query, company_id, filters) do
    query
    |> apply_business_filter(company_id)
    |> apply_compania_filter(filters[:compania])
    |> apply_truck_filter_for_company(company_id, filters[:truck])
    |> apply_date_filter(filters[:fecha], query)
  end

  defp apply_truck_filter_for_company(query, company_id, truck_id) do
    case company_id do
      1 -> # Furcar - mostrar filtro de camiones
        if truck_id && truck_id != "all" do
          from(a in query, where: a.truck_id == ^truck_id)
        else
          query
        end
      _ -> # Otras empresas - no mostrar filtro de camiones
        query
    end
  end

  defp apply_business_filter(query, business_id) do
    from(a in query, where: a.business_id == ^business_id)
  end

  defp apply_compania_filter(query, compania) when is_binary(compania) and compania != "todas" do
    case Integer.parse(compania) do
      {company_id, _} -> from(a in query, where: a.business_id == ^company_id)
      :error -> query
    end
  end
  defp apply_compania_filter(query, _), do: query

  defp apply_date_filter(query, fecha, original_query) when is_binary(fecha) and fecha != "" and fecha != "todos" do
    today = Date.utc_today()
    field =
      case original_query do
        %Ecto.Query{from: {_, EvaaCrmGaepell.Activity}} -> :due_date
        %Ecto.Query{from: {_, EvaaCrmGaepell.MaintenanceTicket}} -> :entry_date
        %Ecto.Query{from: {_, EvaaCrmGaepell.ProductionOrder}} -> :estimated_delivery
        %Ecto.Query{from: {_, EvaaCrmGaepell.Lead}} -> :next_follow_up
        _ -> :due_date
      end
    days = case fecha do
      "semana" -> 7
      "15_dias" -> 15
      "30_dias" -> 30
      "60_dias" -> 60
      "120_dias" -> 120
      _ -> nil
    end
    if days do
      from(a in query, where: fragment("DATE(?)", field(a, ^field)) >= ^Date.add(today, -days))
    else
      query
    end
  end
  defp apply_date_filter(query, _, _), do: query

  defp get_workflow_types_for_company(company_id) do
    case company_id do
      1 -> # Furcar
        ["maintenance", "production", "leads"]
      2 -> # Blidomca  
        ["production", "leads"]
      3 -> # Polimat
        ["events", "leads"]
      _ -> # Default
        ["events", "maintenance", "leads"]
    end
  end

  defp get_workflow_labels_for_company(company_id) do
    case company_id do
      1 -> # Furcar
        %{
          "maintenance" => "Mantenimiento",
          "production" => "Producción/Manufactura de Cajas", 
          "leads" => "Leads"
        }
      2 -> # Blidomca
        %{
          "production" => "Producción de Blindaje",
          "leads" => "Leads"
        }
      3 -> # Polimat
        %{
          "events" => "Eventos de Polimat",
          "leads" => "Leads"
        }
      _ -> # Default
        %{
          "events" => "Eventos",
          "maintenance" => "Mantenimiento",
          "leads" => "Leads"
        }
    end
  end

  defp get_company_name(nil), do: nil
  defp get_company_name(business_id) do
    case business_id do
      1 -> "Furcar"
      2 -> "Blidomca" 
      3 -> "Polimat"
      _ -> "Empresa #{business_id}"
    end
  end

  defp get_truck_name(nil), do: nil
  defp get_truck_name(truck_id) do
    case Repo.get(Truck, truck_id) do
      nil -> nil
      truck -> "#{truck.brand} #{truck.model} (#{truck.license_plate})"
    end
  end

  defp get_specialist_name(nil), do: nil
  defp get_specialist_name(specialist_id) do
    # Implementar cuando tengas el modelo Specialist
    nil
  end

  defp get_activity_status(activity) do
    # Usar directamente el estado del workflow
    activity.status
  end

  defp get_ticket_status(ticket) do
    # Usar directamente el estado del workflow
    ticket.status
  end

  defp get_lead_status(lead) do
    case lead.status do
      "new" -> "new"
      "contacted" -> "contacted"
      "qualified" -> "qualified"
      "converted" -> "converted"
      "lost" -> "lost"
      _ -> "new"
    end
  end

  defp get_production_status(po) do
    # Mapear el estado de la orden de producción al estado del workflow
    case po.status do
      "new_order" -> "new_order"
      "reception" -> "reception"
      "assembly" -> "assembly"
      "mounting" -> "mounting"
      "final_check" -> "final_check"
      "check_out" -> "check_out"
      _ -> "new_order"
    end
  end

  # Funciones para mostrar filtros condicionales
  def should_show_company_filter(view) do
    case view do
      "individual" -> true  # Solo mostrar en vista individual
      _ -> false
    end
  end

  def should_show_truck_filter(view, company_id) do
    case {view, company_id} do
      {_, 1} -> # Furcar - siempre mostrar filtro de camiones
        true
      _ -> false
    end
  end

  def should_show_date_filter(_view), do: true

  defp get_available_types_for_view(view, company_id, workflow_type) do
    case view do
      "integrated" -> 
        get_workflow_types_for_company(company_id)
      "individual" -> 
        # En vista individual, solo mostrar tipos del workflow específico
        case workflow_type do
          "maintenance" -> ["maintenance"]
          "production" -> ["production"] 
          "events" -> ["events"]
          "leads" -> ["leads"]
          _ -> []
        end
      _ -> []
    end
  end

  defp get_type_labels_for_view(view, company_id) do
    case view do
      "integrated" -> get_workflow_labels_for_company(company_id)
      "individual" -> get_workflow_labels_for_company(company_id)
      _ -> %{}
    end
  end

  defp load_trucks_for_company(company_id) do
    case company_id do
      "1" -> 
        # Solo camiones de Furcar
        Repo.all(from t in Truck, 
          where: t.business_id == 1,
          select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
      "2" -> 
        # Solo camiones de Blidomca
        Repo.all(from t in Truck, 
          where: t.business_id == 2,
          select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
      "3" -> 
        # Solo camiones de Polimat
        Repo.all(from t in Truck, 
          where: t.business_id == 3,
          select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
      "todas" -> 
        # Todos los camiones
        Repo.all(from t in Truck, 
          select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
      _ -> 
        # Por defecto, camiones de Furcar
        Repo.all(from t in Truck, 
          where: t.business_id == 1,
          select: %{id: t.id, nombre: fragment("? || ' ' || ? || ' (' || ? || ')'", t.brand, t.model, t.license_plate)})
    end
  end

  defp get_item_id_with_prefix(item) do
    case item.workflow_type do
      "maintenance" -> "t-#{item.id}"
      "events" -> "a-#{item.id}"
      "production" -> "p-#{item.id}"
      "leads" -> "l-#{item.id}"
      _ -> "a-#{item.id}"
    end
  end

  defp create_new_production_order_from_completed(completed_order) do
    IO.puts("=== INICIANDO CREACIÓN DE NUEVA ORDEN DE PRODUCCIÓN ===")
    IO.puts("Orden completada ID: #{completed_order.id}")
    IO.puts("Cliente: #{completed_order.client_name}")
    
    # Obtener el workflow de producción para la empresa correspondiente
    workflow = Repo.get_by(EvaaCrmGaepell.Workflow, workflow_type: "production", business_id: completed_order.business_id)
    
    case workflow do
      nil ->
        IO.puts("❌ No se encontró workflow de producción para business_id: #{completed_order.business_id}")
        {:error, "Workflow no encontrado"}
      
      workflow ->
        IO.puts("✅ Workflow encontrado: #{workflow.id}")
        
        # Obtener el estado inicial "new_order"
        initial_state = Repo.get_by(EvaaCrmGaepell.WorkflowState, name: "new_order", workflow_id: workflow.id)
        
        case initial_state do
          nil ->
            IO.puts("❌ No se encontró estado inicial 'new_order'")
            {:error, "Estado inicial no encontrado"}
          
          initial_state ->
            IO.puts("✅ Estado inicial encontrado: #{initial_state.id}")
            
            # Crear la nueva orden de producción con datos similares pero con nueva fecha de entrega
            new_order_attrs = %{
              "client_name" => completed_order.client_name,
              "truck_brand" => completed_order.truck_brand,
              "truck_model" => completed_order.truck_model,
              "license_plate" => completed_order.license_plate,
              "box_type" => completed_order.box_type,
              "specifications" => "Nueva orden creada automáticamente desde orden completada: #{completed_order.client_name}",
              "estimated_delivery" => Date.add(Date.utc_today(), 30),
              "status" => "new_order",
              "notes" => "Orden creada automáticamente cuando la orden #{completed_order.id} llegó a check_out",
              "business_id" => completed_order.business_id,
              "workflow_id" => workflow.id,
              "workflow_state_id" => initial_state.id,
              "contact_id" => completed_order.contact_id,
              "specialist_id" => completed_order.specialist_id
            }
            
            IO.puts("Creando nueva orden de producción con: #{inspect(new_order_attrs)}")
            
            case %EvaaCrmGaepell.ProductionOrder{}
                 |> EvaaCrmGaepell.ProductionOrder.changeset(new_order_attrs)
                 |> Repo.insert() do
              {:ok, new_order} ->
                IO.puts("✅ Nueva orden de producción creada exitosamente: #{new_order.id}")
                IO.puts("=== NUEVA ORDEN CREADA ===")
                {:ok, new_order}
              {:error, changeset} ->
                IO.puts("❌ Error al crear nueva orden de producción: #{inspect(changeset.errors)}")
                {:error, changeset}
            end
        end
    end
  end

  defp convert_lead_to_contact_and_production_order(lead) do
    # Log para depuración
    IO.puts("=== INICIANDO CONVERSIÓN DE LEAD DESDE KANBAN ===")
    IO.puts("Lead ID: #{lead.id}")
    IO.puts("Lead Name: #{lead.name}")
    IO.puts("Lead Status: #{lead.status}")
    
    # Obtener el workflow de producción para la empresa del lead
    workflow = Repo.get_by(EvaaCrmGaepell.Workflow, workflow_type: "production", business_id: lead.business_id)
    
    case workflow do
      nil ->
        IO.puts("❌ No se encontró workflow de producción para business_id: #{lead.business_id}")
        {:error, "Workflow no encontrado"}
      
      workflow ->
        IO.puts("✅ Workflow encontrado: #{workflow.id}")
        
        # Obtener el estado inicial "new_order"
        initial_state = Repo.get_by(EvaaCrmGaepell.WorkflowState, name: "new_order", workflow_id: workflow.id)
        
        case initial_state do
          nil ->
            IO.puts("❌ No se encontró estado inicial")
            {:error, "Estado inicial no encontrado"}
          
          initial_state ->
            IO.puts("✅ Estado inicial encontrado: #{initial_state.id}")
            
            # Crear el contacto desde el lead
            contact_attrs = %{
              "first_name" => lead.name,
              "last_name" => "Cliente",
              "email" => lead.email,
              "phone" => lead.phone,
              "job_title" => "Cliente",
              "department" => "",
              "address" => "",
              "city" => "",
              "state" => "",
              "country" => "",
              "status" => "active",
              "source" => "other",
              "notes" => "Cliente convertido desde lead: #{lead.name}",
              "business_id" => lead.business_id,
              "company_id" => lead.company_id
            }
            
            IO.puts("Creando contacto con: #{inspect(contact_attrs)}")
            
            case %EvaaCrmGaepell.Contact{}
                 |> EvaaCrmGaepell.Contact.changeset(contact_attrs)
                 |> Repo.insert() do
              {:ok, contact} ->
                IO.puts("✅ Contacto creado exitosamente: #{contact.id}")
                
                # Crear la orden de producción
                production_order_attrs = %{
                  "client_name" => lead.name,
                  "truck_brand" => "Por definir",
                  "truck_model" => "Por definir", 
                  "license_plate" => "Por definir",
                  "box_type" => "dry_box",
                  "specifications" => "Orden creada automáticamente desde lead convertido: #{lead.name}",
                  "estimated_delivery" => Date.add(Date.utc_today(), 30),
                  "status" => "new_order",
                  "notes" => "Orden creada automáticamente desde lead convertido en Kanban",
                  "business_id" => lead.business_id,
                  "workflow_id" => workflow.id,
                  "workflow_state_id" => initial_state.id,
                  "contact_id" => contact.id
                }
                
                IO.puts("Creando orden de producción con: #{inspect(production_order_attrs)}")
                
                case %EvaaCrmGaepell.ProductionOrder{}
                     |> EvaaCrmGaepell.ProductionOrder.changeset(production_order_attrs)
                     |> Repo.insert() do
                  {:ok, production_order} ->
                    IO.puts("✅ Orden de producción creada exitosamente: #{production_order.id}")
                    IO.puts("=== CONVERSIÓN COMPLETADA DESDE KANBAN ===")
                    {:ok, contact}
                  {:error, changeset} ->
                    IO.puts("❌ Error al crear orden de producción: #{inspect(changeset.errors)}")
                    # Si falla la creación de la orden, eliminar el contacto creado
                    Repo.delete(contact)
                    {:error, changeset}
                end
              
              {:error, changeset} ->
                IO.puts("❌ Error al crear contacto: #{inspect(changeset.errors)}")
                {:error, changeset}
            end
        end
    end
  end

  defp revert_lead_conversion(lead) do
    # Log para depuración
    IO.puts("=== INICIANDO REVERSIÓN DE CONVERSIÓN DE LEAD ===")
    IO.puts("Lead ID: #{lead.id}")
    IO.puts("Lead Name: #{lead.name}")
    IO.puts("Lead Status: #{lead.status}")
    
    # Buscar el contacto asociado a este lead (puede ser desde leads o desde kanban)
    contact = Repo.get_by(EvaaCrmGaepell.Contact, 
      first_name: lead.name, 
      business_id: lead.business_id,
      notes: "Cliente convertido desde lead: #{lead.name}")
    
    # Si no se encuentra, buscar el contacto creado desde Kanban
    contact = if is_nil(contact) do
      Repo.get_by(EvaaCrmGaepell.Contact, 
        first_name: lead.name, 
        business_id: lead.business_id,
        notes: "Cliente convertido desde lead en Kanban: #{lead.name}")
    else
      contact
    end
    
    case contact do
      nil ->
        IO.puts("❌ No se encontró contacto asociado al lead")
        {:error, "Contacto no encontrado"}
      
      contact ->
        IO.puts("✅ Contacto encontrado: #{contact.id} - #{contact.first_name} #{contact.last_name}")
        
        # Buscar órdenes de producción asociadas a este contacto (pueden ser desde leads o desde kanban)
        production_orders = Repo.all(from po in EvaaCrmGaepell.ProductionOrder, 
          where: po.contact_id == ^contact.id and 
                 (po.notes == "Orden creada automáticamente desde lead convertido en Kanban" or
                  po.notes == "Orden creada automáticamente desde lead convertido"))
        
        IO.puts("Encontradas #{length(production_orders)} órdenes de producción asociadas")
        
        # Eliminar las órdenes de producción
        Enum.each(production_orders, fn order ->
          case Repo.delete(order) do
            {:ok, _deleted_order} ->
              IO.puts("✅ Orden de producción eliminada: #{order.id}")
            {:error, error} ->
              IO.puts("❌ Error al eliminar orden de producción #{order.id}: #{inspect(error)}")
          end
        end)
        
        # Eliminar el contacto
        case Repo.delete(contact) do
          {:ok, _deleted_contact} ->
            IO.puts("✅ Contacto eliminado: #{contact.id}")
            IO.puts("=== REVERSIÓN COMPLETADA ===")
            {:ok, "Conversión revertida exitosamente"}
          {:error, error} ->
            IO.puts("❌ Error al eliminar contacto: #{inspect(error)}")
            {:error, error}
        end
    end
  end

  # Helpers para stats y actividades recientes
  defp get_dashboard_stats do
    total_trucks = Repo.aggregate(from(t in Truck, where: t.status == "active"), :count, :id)
    
    # Tickets (total de mantenimiento + producción)
    maintenance_tickets = Repo.aggregate(from(m in MaintenanceTicket, where: m.status in ["check_in", "in_workshop", "final_review", "car_wash", "new_ticket", "reception", "diagnosis", "repair", "final_check", "cancelled"]), :count, :id)
    production_tickets = Repo.aggregate(from(p in ProductionOrder, where: p.status != "completed"), :count, :id)
    total_tickets = maintenance_tickets + production_tickets
    
    # Evaluaciones
    evaluations = Repo.aggregate(from(e in EvaaCrmGaepell.Evaluation), :count, :id)
    
    # Completados (mantenimiento + producción completados)
    completed_maintenance = Repo.aggregate(from(m in MaintenanceTicket, where: m.status in ["check_out", "car_wash", "final_review", "completed"]), :count, :id)
    completed_production = Repo.aggregate(from(p in ProductionOrder, where: p.status == "completed"), :count, :id)
    total_completed = completed_maintenance + completed_production
    
    # Camiones recientes
    recent_trucks = Repo.all(from t in Truck, 
      where: t.status == "active",
      order_by: [desc: t.updated_at],
      limit: 3,
      select: %{
        id: t.id,
        license_plate: t.license_plate,
        brand: t.brand,
        model: t.model,
        status: t.status,
        updated_at: t.updated_at
      })
      |> Enum.map(fn truck ->
        Map.merge(truck, %{
          status_classes: if(truck.status == "active", do: "gradient-success text-white border-0 px-2 py-1 rounded-full text-xs", else: "bg-orange-100 dark:bg-orange-900/50 text-orange-700 dark:text-orange-300 border-orange-200 dark:border-orange-800 px-2 py-1 rounded-full text-xs"),
          status_label: if(truck.status == "active", do: "Activo", else: "Mantenimiento"),
          last_maintenance: truck.updated_at
        })
      end)
    
    # Tickets recientes
    recent_tickets = Repo.all(from m in MaintenanceTicket,
      order_by: [desc: m.inserted_at],
      limit: 3,
      select: %{
        id: m.id,
        title: m.title,
        status: m.status,
        truck_license_plate: fragment("(SELECT license_plate FROM trucks WHERE id = ?)", m.truck_id),
        inserted_at: m.inserted_at
      })
      |> Enum.map(fn ticket ->
        Map.merge(ticket, %{
          status_classes: case ticket.status do
            "pending" -> "bg-yellow-100 dark:bg-yellow-900/50 text-yellow-700 dark:text-yellow-300 border-yellow-200 dark:border-yellow-800"
            "in_progress" -> "bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300 border-blue-200 dark:border-blue-800"
            "completed" -> "gradient-success text-white border-0"
            _ -> "bg-gray-100 dark:bg-gray-900/50 text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-800"
          end,
          status_label: case ticket.status do
            "pending" -> "Pendiente"
            "in_progress" -> "En Progreso"
            "completed" -> "Completado"
            _ -> "Desconocido"
          end
        })
      end)
    
    %{
      total_trucks: total_trucks,
      pending_tickets: total_tickets,
      completed_maintenance: evaluations,
      critical_alerts: total_completed,
      recent_trucks: recent_trucks,
      recent_tickets: recent_tickets
    }
  end

  defp get_recent_activities do
    # Mezclar las 5 más recientes entre tickets, leads, órdenes, actividades, feedbacks, comentarios y cambios de estado de feedback
    tickets = Repo.all(from m in MaintenanceTicket, order_by: [desc: m.inserted_at], limit: 5)
    leads = Repo.all(from l in Lead, order_by: [desc: l.inserted_at], limit: 5)
    orders = Repo.all(from p in ProductionOrder, order_by: [desc: p.inserted_at], limit: 5)
    activities = Repo.all(from a in Activity, order_by: [desc: a.inserted_at], limit: 5)
    feedbacks = Repo.all(from f in EvaaCrmGaepell.FeedbackReport, order_by: [desc: f.inserted_at], limit: 5)
    feedback_comments = Repo.all(from c in EvaaCrmGaepell.FeedbackComment, order_by: [desc: c.inserted_at], limit: 5)
    feedback_status_changes = Repo.all(from f in EvaaCrmGaepell.FeedbackReport, order_by: [desc: f.updated_at], limit: 5)
    all =
      Enum.map(tickets, &%{type: :ticket, id: &1.id, title: &1.title, subtitle: get_truck_name(&1.truck_id), inserted_at: &1.inserted_at}) ++
      Enum.map(leads, &%{type: :lead, id: &1.id, title: &1.name, subtitle: &1.company_name, inserted_at: &1.inserted_at}) ++
      Enum.map(orders, &%{type: :order, id: &1.id, title: &1.client_name, subtitle: &1.truck_brand <> " " <> &1.truck_model, inserted_at: &1.inserted_at}) ++
      Enum.map(activities, &%{type: :activity, id: &1.id, title: &1.title, subtitle: &1.description, inserted_at: &1.inserted_at}) ++
      Enum.map(feedbacks, &%{type: :feedback, id: &1.id, title: "Bug: " <> String.slice(&1.description, 0, 40), subtitle: &1.status, inserted_at: &1.inserted_at, status: &1.status}) ++
      Enum.map(feedback_comments, fn c ->
        feedback = Repo.get(EvaaCrmGaepell.FeedbackReport, c.feedback_report_id)
        %{type: :feedback_comment, id: c.id, title: "Comentario en bug: " <> (feedback && String.slice(feedback.description, 0, 30) || ""), subtitle: c.body, inserted_at: c.inserted_at, feedback_id: c.feedback_report_id, author: c.author}
      end) ++
      Enum.map(feedback_status_changes, fn f ->
        %{type: :feedback_status_change, id: f.id, title: "Cambio de estado en bug: " <> String.slice(f.description, 0, 30), subtitle: f.status, inserted_at: f.updated_at, status: f.status}
      end)
    all
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> Enum.take(5)
  end

  # Gráfico de actividad reciente (últimos 7 días, todas las actividades y tickets)
  defp get_activity_chart_data do
    today = Date.utc_today()
    days = Enum.map(0..6, fn i -> Date.add(today, -i) end) |> Enum.reverse()
    # Contar actividades y tickets por día
    activities = Repo.all(from a in Activity, where: not is_nil(a.inserted_at), select: a.inserted_at)
    tickets = Repo.all(from t in MaintenanceTicket, where: not is_nil(t.inserted_at), select: t.inserted_at)
    all = activities ++ tickets
    Enum.map(days, fn day ->
      count = Enum.count(all, fn dt ->
        NaiveDateTime.to_date(dt) == day
      end)
      {day, count}
    end)
  end

  # Gráfico de distribución por estado (todas las actividades y tickets)
  defp get_status_distribution_data do
    # Estados posibles
    statuses = ["pending", "in_progress", "completed", "cancelled", "check_in", "in_workshop", "final_review", "car_wash", "check_out", "new_order", "reception", "assembly", "mounting", "final_check"]
    # Contar actividades
    activity_counts = Repo.all(from a in Activity, group_by: a.status, select: {a.status, count(a.id)})
    ticket_counts = Repo.all(from t in MaintenanceTicket, group_by: t.status, select: {t.status, count(t.id)})
    # Sumar por estado
    all_counts = Enum.concat(activity_counts, ticket_counts)
    grouped = Enum.group_by(all_counts, fn {status, _} -> status end, fn {_, count} -> count end)
    Enum.map(statuses, fn status ->
      {status, Enum.sum(Map.get(grouped, status, []))}
    end)
    |> Enum.filter(fn {_status, count} -> count > 0 end)
  end

  defp status_label("pending"), do: "Pendiente"
  defp status_label("in_progress"), do: "En Proceso"
  defp status_label("completed"), do: "Completado"
  defp status_label("cancelled"), do: "Cancelado"
  defp status_label("check_in"), do: "Check-in"
  defp status_label("in_workshop"), do: "En Taller"
  defp status_label("final_review"), do: "Revisión Final"
  defp status_label("car_wash"), do: "Lavado"
  defp status_label("check_out"), do: "Check-out"
  defp status_label("new_order"), do: "Nueva Orden"
  defp status_label("reception"), do: "Recepción"
  defp status_label("assembly"), do: "Ensamblaje"
  defp status_label("mounting"), do: "Montaje"
  defp status_label("final_check"), do: "Final Check"
  defp status_label(status), do: status

  defp human_relative_time(nil), do: "-"
  defp human_relative_time(naive_dt) do
    dt = NaiveDateTime.to_erl(naive_dt)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.to_erl()
    seconds = :calendar.datetime_to_gregorian_seconds(now) - :calendar.datetime_to_gregorian_seconds(dt)
    cond do
      seconds < 60 -> "hace #{seconds} segundos"
      seconds < 3600 -> "hace #{div(seconds, 60)} minutos"
      seconds < 86400 -> "hace #{div(seconds, 3600)} horas"
      true -> "hace #{div(seconds, 86400)} días"
    end
  end



  @impl true
  def handle_info({:feedback_status_changed, feedback_id, status, description}, socket) do
    recent_activities = get_recent_activities()
    msg = "Cambio de estado en bug: " <> String.slice(description, 0, 30) <> " (" <> status <> ")"
    socket =
      socket
      |> assign(:dashboard_recent_activities, recent_activities)
      |> push_event("actividad_reciente", %{message: msg})
    {:noreply, socket}
  end
end
