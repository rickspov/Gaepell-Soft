defmodule EvaaCrmWebGaepell.MaintenanceTicketsLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{MaintenanceTicket, Truck, Repo}
  alias EvaaCrmGaepell.Fleet
  import Ecto.Query
  import Phoenix.HTML.Form
  import EvaaCrmWebGaepell.CoreComponents
  import Phoenix.Naming
  import Phoenix.LiveView.Helpers
  alias EvaaCrmGaepell.MaintenanceTicketCheckout

  # Ruta absoluta para los uploads
  @uploads_dir Path.expand("priv/static/uploads")

  @impl true
  def mount(params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    preselected_truck_id = params["truck_id"]
    show_form = params["show_form"] == "true"
    
    # Obtener marcas, modelos y propietarios existentes para autocompletado
    existing_brands = get_existing_brands()
    existing_models = get_existing_models()
    existing_owners = get_existing_owners()
    ticket_changeset =
      if show_form do
        base = %MaintenanceTicket{}
        base = if preselected_truck_id, do: %{base | truck_id: String.to_integer(preselected_truck_id)}, else: base
        EvaaCrmGaepell.MaintenanceTicket.changeset(base, %{})
      else
        nil
      end
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "EVA - Tickets de Mantenimiento")
     |> assign(:tickets, [])
     |> assign(:trucks, [])
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:filter_truck, "all")
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:show_form, show_form)
     |> assign(:editing_ticket, ticket_changeset)
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)
     |> assign(:preselected_truck_id, preselected_truck_id)
     |> assign(:editing_status_id, nil)
     |> assign(:show_ticket_profile, false)
     |> assign(:selected_ticket, nil)
     |> assign(:ticket_logs, [])
     |> assign(:ticket_checkouts, [])
     |> assign(:existing_brands, existing_brands)
     |> assign(:existing_models, existing_models)
     |> assign(:existing_owners, existing_owners)
     |> allow_upload(:damage_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
     |> load_tickets()
     |> load_trucks()}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    # Cuando se accede a un ticket específico
    ticket = Repo.get(MaintenanceTicket, id) |> Repo.preload(:truck)
    
    if ticket do
      {:noreply, 
       socket
       |> assign(:selected_ticket, ticket)
       |> assign(:show_ticket_profile, true)}
    else
      {:noreply, 
       socket
       |> put_flash(:error, "Ticket no encontrado")
       |> push_navigate(to: ~p"/maintenance")}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # Cuando se accede a la lista general
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, 
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> load_tickets()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_status, status)
     |> assign(:page, 1)
     |> load_tickets()}
  end

  @impl true
  def handle_event("filter_truck", %{"truck_id" => truck_id}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_truck, truck_id)
     |> assign(:page, 1)
     |> load_tickets()}
  end

  @impl true
  def handle_event("show_form", %{"ticket_id" => ticket_id}, socket) do
    ticket_changeset =
      if ticket_id == "new" do
        base = %MaintenanceTicket{}
        base = if socket.assigns.preselected_truck_id, do: %{base | truck_id: String.to_integer(socket.assigns.preselected_truck_id)}, else: base
        EvaaCrmGaepell.MaintenanceTicket.changeset(base, %{})
      else
        ticket = Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload(:truck)
        IO.inspect(ticket, label: "[DEBUG] Ticket loaded for editing")
        IO.inspect(ticket.damage_photos, label: "[DEBUG] Photos in ticket")
        # Create changeset with existing data to populate form fields
        EvaaCrmGaepell.MaintenanceTicket.changeset(ticket, %{
          truck_id: ticket.truck_id,
          entry_date: ticket.entry_date,
          mileage: ticket.mileage,
          fuel_level: ticket.fuel_level,
          status: ticket.status,
          title: ticket.title,
          visible_damage: ticket.visible_damage,
          exit_notes: ticket.exit_notes,
          color: ticket.color,
          damage_photos: ticket.damage_photos,
          # Deliverer information
          deliverer_name: ticket.deliverer_name,
          document_type: ticket.document_type,
          document_number: ticket.document_number,
          deliverer_phone: ticket.deliverer_phone,
          company_name: ticket.company_name,
          position: ticket.position,
          employee_number: ticket.employee_number,
          authorization_type: ticket.authorization_type,
          special_conditions: ticket.special_conditions
        })
      end
    changelog = if ticket_id != "new", do: load_ticket_changelog(ticket_id), else: []
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_ticket, ticket_changeset)
     |> assign(:ticket_changelog, changelog)}
  end

  # Handle the case where show_form is called with a different parameter structure
  @impl true
  def handle_event("show_form", params, socket) do
    IO.inspect(params, label: "[DEBUG] show_form called with params")
    # Try to extract ticket_id from different possible parameter structures
    ticket_id = params["ticket_id"] || params["id"] || "new"
    handle_event("show_form", %{"ticket_id" => ticket_id}, socket)
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_form, false)
     |> assign(:editing_ticket, nil)}
  end

  # Eventos para autocompletado de marcas, modelos y propietarios
  def handle_event("filter_brands", %{"value" => query}, socket) do
    filtered_brands = filter_brands(query, socket.assigns.existing_brands)
    {:noreply, push_event(socket, "update_brand_suggestions", %{suggestions: filtered_brands})}
  end

  def handle_event("filter_brands", %{"key" => _key, "value" => query}, socket) do
    filtered_brands = filter_brands(query, socket.assigns.existing_brands)
    {:noreply, push_event(socket, "update_brand_suggestions", %{suggestions: filtered_brands})}
  end

  def handle_event("filter_models", %{"value" => query}, socket) do
    filtered_models = filter_models(query, socket.assigns.existing_models)
    {:noreply, push_event(socket, "update_model_suggestions", %{suggestions: filtered_models})}
  end

  def handle_event("filter_models", %{"key" => _key, "value" => query}, socket) do
    filtered_models = filter_models(query, socket.assigns.existing_models)
    {:noreply, push_event(socket, "update_model_suggestions", %{suggestions: filtered_models})}
  end

  def handle_event("filter_owners", %{"value" => query}, socket) do
    filtered_owners = filter_owners(query, socket.assigns.existing_owners)
    {:noreply, push_event(socket, "update_owner_suggestions", %{suggestions: filtered_owners})}
  end

  def handle_event("filter_owners", %{"key" => _key, "value" => query}, socket) do
    filtered_owners = filter_owners(query, socket.assigns.existing_owners)
    {:noreply, push_event(socket, "update_owner_suggestions", %{suggestions: filtered_owners})}
  end

  @impl true
  def handle_event("save_ticket", %{"maintenance_ticket" => ticket_params}, socket) do
    editing_ticket = socket.assigns.editing_ticket && socket.assigns.editing_ticket.data
    upload = socket.assigns.uploads.damage_photos
    
    # Debug: Verificar si hay archivos en el upload
    IO.inspect(upload.entries, label: "[DEBUG] upload.entries")
    IO.inspect(upload.errors, label: "[DEBUG] upload.errors")
    
    # Verificar que todos los archivos estén completados antes de consumirlos
    incomplete_entries = Enum.filter(upload.entries, fn entry -> !entry.done? end)
    
    if length(incomplete_entries) > 0 do
      IO.puts("[DEBUG] Hay archivos aún en progreso, esperando...")
      {:noreply, put_flash(socket, :error, "Por favor espera a que todos los archivos se suban completamente antes de guardar")}
    else
      uploaded_files = consume_uploaded_entries(socket, :damage_photos, fn %{path: path} = meta, entry ->
        IO.inspect(meta, label: "[DEBUG] meta")
        IO.inspect(entry, label: "[DEBUG] entry")
        filename = "ticket_#{editing_ticket && editing_ticket.id || "new"}_#{System.system_time()}.jpg"
        dest = Path.join([@uploads_dir, filename])
        IO.puts("[DEBUG] Copiando de #{path} a #{dest}")
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)
        IO.puts("[DEBUG] Archivo copiado exitosamente")
        {:ok, "/uploads/#{filename}"}
      end)
      IO.inspect(uploaded_files, label: "[DEBUG] uploaded_files")
      # Fix: uploaded_files is already a list of URLs, not tuples
      photo_urls = if is_list(uploaded_files) do
        uploaded_files
      else
        Enum.map(uploaded_files, fn {:ok, url} -> url; _ -> nil end) |> Enum.filter(& &1)
      end
      IO.inspect(photo_urls, label: "[DEBUG] photo_urls")
      # Merge with existing photos if editing
      ticket_params = if editing_ticket && editing_ticket.damage_photos do
        Map.update(ticket_params, "damage_photos", editing_ticket.damage_photos ++ photo_urls, fn old ->
          (old || []) ++ photo_urls
        end)
      else
        Map.put(ticket_params, "damage_photos", photo_urls)
      end
      IO.inspect(ticket_params, label: "[DEBUG] ticket_params before save")
      # --- FIX: preserve truck_id if missing ---
      ticket_params = if Map.get(ticket_params, "truck_id") in [nil, ""] and editing_ticket && editing_ticket.truck_id do
        Map.put(ticket_params, "truck_id", to_string(editing_ticket.truck_id))
      else
        ticket_params
      end
      # --- END FIX ---
      result =
        if editing_ticket && editing_ticket.id do
          EvaaCrmGaepell.Fleet.update_maintenance_ticket(editing_ticket, ticket_params, socket.assigns.current_user && socket.assigns.current_user.id)
        else
          # Agregar user_id para que se registre el log de creación
          ticket_params_with_user = Map.put(ticket_params, "user_id", socket.assigns.current_user && socket.assigns.current_user.id)
          EvaaCrmGaepell.Fleet.create_maintenance_ticket(ticket_params_with_user)
        end
      case result do
        {:ok, _ticket} ->
          {:noreply, 
           socket
           |> put_flash(:info, "Ticket guardado exitosamente")
           |> assign(:show_form, false)
           |> assign(:editing_ticket, nil)
           |> load_tickets()}
        {:error, changeset} ->
          {:noreply, assign(socket, :editing_ticket, changeset)}
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Error al guardar el ticket")}
      end
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id}, socket) do
    ticket = Repo.get(MaintenanceTicket, id) |> Repo.preload(:truck)
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, true)
     |> assign(:delete_target, %{id: id, type: "ticket", name: "Ticket ##{ticket.id} - #{ticket.truck.brand} #{ticket.truck.model}"})}
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
      %{id: id, type: "ticket"} ->
        ticket = Repo.get(MaintenanceTicket, id)
        case Fleet.delete_maintenance_ticket(ticket) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Ticket eliminado exitosamente")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_tickets()}
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al eliminar el ticket")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_tickets()}
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
    {:noreply, 
     socket
     |> assign(:page, String.to_integer(page))
     |> load_tickets()}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :damage_photos, ref)}
  end

  @impl true
  def handle_event("progress", %{"entry" => entry, "progress" => progress}, socket) do
    IO.puts("[DEBUG] Upload progress for #{entry}: #{progress}%")
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_photo", %{"url" => photo_url}, socket) do
    editing_ticket = socket.assigns.editing_ticket && socket.assigns.editing_ticket.data
    
    if editing_ticket && editing_ticket.damage_photos do
      # Remove the photo from the list
      updated_photos = Enum.reject(editing_ticket.damage_photos, fn url -> url == photo_url end)
      
      # Update the changeset with the new photos list
      changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(editing_ticket, %{damage_photos: updated_photos})
      
      {:noreply, assign(socket, :editing_ticket, changeset)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("ignore", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("edit_status", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_status_id: String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel_edit_status", %{"id" => id, "value" => status}, socket) do
    # Actualizar automáticamente el estado del ticket
    ticket = Enum.find(socket.assigns.tickets, &(&1.id == String.to_integer(id)))
    if ticket && status in ["check_in", "in_workshop", "final_review", "car_wash", "check_out", "cancelled"] do
      # Usar el método Fleet que registra logs
      case EvaaCrmGaepell.Fleet.update_maintenance_ticket(ticket, %{status: status}, socket.assigns.current_user.id) do
        {:ok, _} ->
          {:noreply, socket |> assign(editing_status_id: nil) |> load_tickets()}
        {:error, _} ->
          {:noreply, assign(socket, editing_status_id: nil)}
      end
    else
      {:noreply, assign(socket, editing_status_id: nil)}
    end
  end

  @impl true
  def handle_event("cancel_edit_status", _params, socket) do
    {:noreply, assign(socket, editing_status_id: nil)}
  end

  @impl true
  def handle_event("update_status", %{"id" => id, "status" => status}, socket) do
    IO.inspect("update_status called with id: #{id}, status: #{status}", label: "[DEBUG]")
    ticket = Enum.find(socket.assigns.tickets, &(&1.id == String.to_integer(id)))
    IO.inspect("Found ticket: #{inspect(ticket)}", label: "[DEBUG]")
    
    if ticket && status in ["check_in", "in_workshop", "final_review", "car_wash", "check_out", "cancelled"] do
      # Usar el método Fleet que registra logs
      case EvaaCrmGaepell.Fleet.update_maintenance_ticket(ticket, %{status: status}, socket.assigns.current_user.id) do
        {:ok, updated_ticket} ->
          IO.inspect("Status updated successfully", label: "[DEBUG]")
          {:noreply, socket |> assign(editing_status_id: nil) |> load_tickets()}
        {:error, changeset} ->
          IO.inspect("Error updating status: #{inspect(changeset.errors)}", label: "[DEBUG]")
          {:noreply, assign(socket, editing_status_id: nil)}
      end
    else
      IO.inspect("Invalid ticket or status", label: "[DEBUG]")
      {:noreply, assign(socket, editing_status_id: nil)}
    end
  end

  @impl true
  def handle_event("validate", %{"maintenance_ticket" => params}, socket) do
    editing_ticket = socket.assigns.editing_ticket && socket.assigns.editing_ticket.data
    # If we're editing an existing ticket, preserve the existing data
    if editing_ticket && editing_ticket.id do
      # Usar el valor del changeset si params["truck_id"] es nil o vacío
      current_truck_id =
        case socket.assigns.editing_ticket do
          %Ecto.Changeset{} = ch ->
            Ecto.Changeset.get_field(ch, :truck_id) || editing_ticket.truck_id
          _ -> editing_ticket.truck_id
        end
      merged_params = Map.merge(%{
        "truck_id" => (if params["truck_id"] && params["truck_id"] != "", do: params["truck_id"], else: to_string(current_truck_id)),
        "entry_date" => (if editing_ticket.entry_date, do: Calendar.strftime(editing_ticket.entry_date, "%Y-%m-%dT%H:%M"), else: ""),
        "mileage" => (if editing_ticket.mileage, do: to_string(editing_ticket.mileage), else: ""),
        "fuel_level" => editing_ticket.fuel_level || "",
        "status" => editing_ticket.status || "",
        "title" => editing_ticket.title || "",
        "visible_damage" => editing_ticket.visible_damage || "",
        "exit_notes" => editing_ticket.exit_notes || "",
        "color" => editing_ticket.color || "#2563eb",
        "damage_photos" => editing_ticket.damage_photos || [],
        # Deliverer information
        "deliverer_name" => editing_ticket.deliverer_name || "",
        "document_type" => editing_ticket.document_type || "",
        "document_number" => editing_ticket.document_number || "",
        "deliverer_phone" => editing_ticket.deliverer_phone || "",

        "company_name" => editing_ticket.company_name || "",
        "position" => editing_ticket.position || "",
        "employee_number" => editing_ticket.employee_number || "",
        "authorization_type" => editing_ticket.authorization_type || "",
        "special_conditions" => editing_ticket.special_conditions || ""
      }, params)
      changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(editing_ticket, merged_params)
      {:noreply, assign(socket, :editing_ticket, changeset)}
    else
      # For new tickets, just validate normally
      changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(%MaintenanceTicket{}, params)
      {:noreply, assign(socket, :editing_ticket, changeset)}
    end
  end

  @impl true
  def handle_event("truck_select_change", %{"maintenance_ticket" => params}, socket) do
    changeset =
      socket.assigns.editing_ticket.data
      |> EvaaCrmGaepell.MaintenanceTicket.changeset(params)

    {:noreply, assign(socket, editing_ticket: changeset)}
  end

  defp load_tickets(socket) do
    query = from t in MaintenanceTicket,
            preload: [:truck],
            order_by: [desc: t.inserted_at]

    query = case socket.assigns.search do
      "" -> query
      search -> 
        search_term = "%#{search}%"
        from t in query,
        join: truck in assoc(t, :truck),
        where: ilike(truck.brand, ^search_term) or 
               ilike(truck.model, ^search_term) or 
               ilike(truck.license_plate, ^search_term)
    end

    query = case socket.assigns.filter_status do
      "all" -> query
      status -> from t in query, where: t.status == ^status
    end

    query = case socket.assigns.filter_truck do
      "all" -> query
      truck_id -> from t in query, where: t.truck_id == ^truck_id
    end

    # Pagination
    offset = (socket.assigns.page - 1) * socket.assigns.per_page
    tickets = Repo.all(from t in query, limit: ^socket.assigns.per_page, offset: ^offset)
    total = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total / socket.assigns.per_page)

    socket
    |> assign(:tickets, tickets)
    |> assign(:total_pages, total_pages)
    |> assign(:total, total)
  end

  defp load_trucks(socket) do
    trucks = Repo.all(from t in Truck, order_by: t.brand)
    assign(socket, :trucks, trucks)
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

  defp load_ticket_changelog(ticket_id) do
    EvaaCrmGaepell.ActivityLog.get_logs_for_entity("maintenance_ticket", ticket_id)
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
     |> assign(:ticket_checkouts, checkouts)
    }
  end

  @impl true
  def handle_event("hide_ticket_profile", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_ticket_profile, false)
     |> assign(:selected_ticket, nil)
     |> assign(:ticket_logs, [])}
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
      IO.inspect(ticket, label: "[DEBUG] Ticket loaded for editing from profile")
      IO.inspect(ticket.damage_photos, label: "[DEBUG] Photos in ticket")
      # Create changeset with existing data to populate form fields
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
      damage_photos: ticket.damage_photos,
      # Deliverer information
      deliverer_name: ticket.deliverer_name,
      document_type: ticket.document_type,
      document_number: ticket.document_number,
      deliverer_phone: ticket.deliverer_phone,
      
      company_name: ticket.company_name,
      position: ticket.position,
      employee_number: ticket.employee_number,
      authorization_type: ticket.authorization_type,
      special_conditions: ticket.special_conditions
      })
    
    changelog = load_ticket_changelog(ticket_id)
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_ticket, ticket_changeset)
     |> assign(:ticket_changelog, changelog)}
  end

  @impl true
  def handle_event("create_embedded_truck", %{"embedded_truck" => truck_params}, socket) do
    # Agregar business_id al camión
    truck_params = Map.put(truck_params, "business_id", socket.assigns.current_user.business_id)

    case EvaaCrmGaepell.Truck.create_truck(truck_params, socket.assigns.current_user.id) do
      {:ok, truck} ->
        # Actualizar la lista de camiones y seleccionar el nuevo en el changeset del ticket
        trucks = [truck | socket.assigns.trucks]
        # Actualizar el changeset del ticket con el nuevo truck_id
        ticket_params = %{"truck_id" => to_string(truck.id)}
        changeset =
          socket.assigns.editing_ticket.data
          |> EvaaCrmGaepell.MaintenanceTicket.changeset(ticket_params)
        {:noreply,
         socket
         |> assign(trucks: trucks)
         |> assign(editing_ticket: changeset)
         |> put_flash(:info, "Camión creado y seleccionado exitosamente")}
      {:error, changeset} ->
        # Puedes mostrar errores aquí si lo deseas
        {:noreply, put_flash(socket, :error, "Error al crear el camión. Verifica los datos e inténtalo de nuevo.")}
    end
  end

  # Funciones para autocompletado de marcas, modelos y propietarios
  defp get_existing_brands do
    Truck
    |> select([t], t.brand)
    |> where([t], not is_nil(t.brand) and t.brand != "")
    |> distinct([t], t.brand)
    |> order_by([t], t.brand)
    |> Repo.all()
  end

  defp get_existing_models do
    Truck
    |> select([t], t.model)
    |> where([t], not is_nil(t.model) and t.model != "")
    |> distinct([t], t.model)
    |> order_by([t], t.model)
    |> Repo.all()
  end

  defp get_existing_owners do
    Truck
    |> select([t], t.owner)
    |> where([t], not is_nil(t.owner) and t.owner != "")
    |> distinct([t], t.owner)
    |> order_by([t], t.owner)
    |> Repo.all()
  end

  defp filter_brands(query, brands) when is_binary(query) and byte_size(query) > 0 do
    query_lower = String.downcase(query)
    brands
    |> Enum.filter(fn brand -> 
      brand && String.downcase(brand) =~ query_lower
    end)
    |> Enum.take(10) # Limitar a 10 sugerencias
  end

  defp filter_brands(_query, _brands), do: []

  defp filter_models(query, models) when is_binary(query) and byte_size(query) > 0 do
    query_lower = String.downcase(query)
    models
    |> Enum.filter(fn model -> 
      model && String.downcase(model) =~ query_lower
    end)
    |> Enum.take(10) # Limitar a 10 sugerencias
  end

  defp filter_models(_query, _models), do: []

  defp filter_owners(query, owners) when is_binary(query) and byte_size(query) > 0 do
    query_lower = String.downcase(query)
    owners
    |> Enum.filter(fn owner -> 
      owner && String.downcase(owner) =~ query_lower
    end)
    |> Enum.take(10) # Limitar a 10 sugerencias
  end

  defp filter_owners(_query, _owners), do: []
end 