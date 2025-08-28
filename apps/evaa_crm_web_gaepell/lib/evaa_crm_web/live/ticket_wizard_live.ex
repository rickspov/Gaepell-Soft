defmodule EvaaCrmWebGaepell.TicketWizardLive do
  use EvaaCrmWebGaepell, :live_view
  import Phoenix.Component
  import Phoenix.LiveView.Helpers

  alias EvaaCrmGaepell.TruckPhoto

  @required_photos [
    %{key: :front, label: "Foto de parte delantera"},
    %{key: :left, label: "Foto de lateral izquierdo"},
    %{key: :right, label: "Foto de lateral derecho"},
    %{key: :odometer, label: "Foto de odómetro"},
    %{key: :accessories, label: "Foto de accesorios (goma de repuesto, gato hidráulico, cables de batería, etc)"}
  ]

  @uploads_dir Path.expand("priv/static/uploads")

  defp ensure_uploads_allowed(socket) do
    Enum.reduce(@required_photos, socket, fn %{key: key}, acc ->
      if Map.has_key?(acc.assigns.uploads, to_string(key)) do
        acc
      else
        allow_upload(acc, to_string(key), accept: ~w(.jpg .jpeg .png), max_entries: 1)
      end
    end)
  end

  defp parse_datetime_local(nil), do: nil
  defp parse_datetime_local(""), do: nil
  defp parse_datetime_local(str) do
    # str: "2025-07-17T16:40"
    case NaiveDateTime.from_iso8601(str <> ":00") do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> nil
    end
  end

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    
    # Obtener marcas, modelos y propietarios existentes para autocompletado
    existing_brands = get_existing_brands()
    existing_models = get_existing_models()
    existing_owners = get_existing_owners()
    socket =
      socket
      |> assign(step: :select_scenario, scenario: nil, current_user: current_user)
      |> assign(photo_uploads: %{})
      |> assign(photo_entries: %{})
      |> assign(photo_errors: %{})
      |> assign(furcar_id: 1)
      |> assign(:required_photos, @required_photos)
      |> assign(signature_data: nil)
      |> assign(show_new_checkin_modal: false)
      |> assign(show_new_truck_form: false)
      |> assign(new_truck: nil)
      |> assign(search_plate: nil)
      |> assign(show_search_modal: false)
      |> assign(show_production_order_modal: false)
      |> assign(show_existing_trucks_modal: false)
      |> assign(selected_truck_id: nil)
      |> assign(:existing_brands, existing_brands)
      |> assign(:existing_models, existing_models)
      |> assign(:existing_owners, existing_owners)
      |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
    
    IO.puts("[DEBUG] Upload inicializado en mount")
    IO.inspect(socket.assigns.uploads.evaluation_photos, label: "[DEBUG] upload en mount")
    if is_nil(current_user) do
      {:ok, socket |> put_flash(:error, "Debes iniciar sesión para crear tickets y subir fotos.") |> push_navigate(to: "/login")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("select_scenario", %{"scenario" => scenario}, socket) do
    {new_step, entry_type} =
      case scenario do
        "search_unified" -> {:search_unified, nil}
        "evaluation_quotation" -> {:evaluation_quotation_type, :quotation}
        "maintenance_checkin" -> {:new_checkin_type, :maintenance}
        "production_order" -> {:new_checkin_type, :production}
        _ -> {:select_scenario, nil}
      end

    assigns = [step: new_step, scenario: scenario, entry_type: entry_type]

    # Si es search_unified, cargar todos los camiones inicialmente
    socket = if new_step == :search_unified do
      import Ecto.Query
      trucks = from t in EvaaCrmGaepell.Truck,
              where: t.business_id == ^socket.assigns.current_user.business_id,
              order_by: [asc: t.brand, asc: t.model]
      trucks = EvaaCrmGaepell.Repo.all(trucks)
      assign(socket, :filtered_trucks, trucks)
    else
      socket
    end

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("back_to_select", _params, socket) do
    {:noreply, assign(socket, step: :select_scenario, scenario: nil, truck_changeset: nil)}
  end



  @impl true
  def handle_event("filter_trucks", %{"search_term" => search_term}, socket) do
    filter_trucks_by_term(search_term, socket)
  end

  @impl true
  def handle_event("filter_trucks", %{"value" => search_term}, socket) do
    filter_trucks_by_term(search_term, socket)
  end

  @impl true
  def handle_event("filter_trucks", params, socket) do
    # Intentar extraer el valor de diferentes formas
    search_term = params["search_term"] || params["value"] || ""
    filter_trucks_by_term(search_term, socket)
  end

  defp filter_trucks_by_term(search_term, socket) do
    import Ecto.Query
    
    # Si el término de búsqueda está vacío, mostrar todos los camiones
    trucks = if String.trim(search_term) == "" do
      query = from t in EvaaCrmGaepell.Truck,
              where: t.business_id == ^socket.assigns.current_user.business_id,
              order_by: [asc: t.brand, asc: t.model]
      EvaaCrmGaepell.Repo.all(query)
    else
      # Filtrar camiones que coincidan con marca, modelo o placa
      query = from t in EvaaCrmGaepell.Truck,
              where: ilike(t.brand, ^"%#{search_term}%") or 
                     ilike(t.model, ^"%#{search_term}%") or 
                     ilike(t.license_plate, ^"%#{search_term}%"),
              where: t.business_id == ^socket.assigns.current_user.business_id,
              order_by: [asc: t.brand, asc: t.model]
      EvaaCrmGaepell.Repo.all(query)
    end
    
    {:noreply, assign(socket, :filtered_trucks, trucks)}
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
  def handle_event("continue_to_damages", _params, socket) do
    {:noreply, assign(socket, step: :capture_damages)}
  end

  @impl true
  def handle_event("continue_to_ticket_details", _params, socket) do
    found_truck = socket.assigns.found_truck
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    default_ticket = %{
      title: "Check-in de camión #{found_truck.license_plate}",
      entry_date: DateTime.to_iso8601(now),
      mileage: 0,
      fuel_level: "full",
      status: "check_in",
      color: "#2563eb",
      exit_notes: "",
      visible_damage: "",
      company_name: found_truck.owner || "No especificado"
    }
    {:noreply, assign(socket, step: :ticket_details, ticket_form: default_ticket)}
  end

  @impl true
  def handle_event("save_ticket_details", %{"ticket" => ticket_params}, socket) do
    # Validar campos obligatorios de protección legal
    required_fields = ["deliverer_name", "document_type", "document_number", "deliverer_phone"]
    missing_fields = Enum.filter(required_fields, fn field -> 
      !ticket_params[field] || String.trim(ticket_params[field]) == ""
    end)
    
    if length(missing_fields) > 0 do
      missing_field_names = Enum.map(missing_fields, fn field ->
        case field do
          "deliverer_name" -> "Nombre completo"
          "document_type" -> "Tipo de documento"
          "document_number" -> "Número de documento"
          "deliverer_phone" -> "Teléfono de contacto"
          _ -> field
        end
      end)
      {:noreply, put_flash(socket, :error, "Campos obligatorios faltantes: #{Enum.join(missing_field_names, ", ")}")}
    else
      {:noreply, assign(socket, step: :capture_damages, ticket_form: ticket_params)}
    end
  end

  @impl true
  def handle_event("save_damages", %{"damages" => damages}, socket) do
    current_user = socket.assigns.current_user
    found_truck = socket.assigns.found_truck
    ticket_form = socket.assigns.ticket_form || %{}
    entry_type = socket.assigns.entry_type || :maintenance
    
    params = %{
      truck_id: found_truck.id,
      user_id: current_user && current_user.id,
      status: ticket_form["status"] || "check_in",
      visible_damage: damages,
      title: ticket_form["title"] || "Check-in de camión #{found_truck.license_plate}",
      business_id: found_truck.business_id,
      entry_date: parse_datetime_local(ticket_form["entry_date"]) || DateTime.utc_now(),
      priority: "medium",
      fuel_level: ticket_form["fuel_level"] || "full",
      color: ticket_form["color"] || "#2563eb",
      mileage: (if ticket_form["mileage"] && ticket_form["mileage"] != "", do: String.to_integer(ticket_form["mileage"]), else: 0),
      description: build_deliverer_description(ticket_form),
      exit_notes: ticket_form["exit_notes"] || "",
      # Campos de protección legal
      deliverer_name: ticket_form["deliverer_name"],
      document_type: ticket_form["document_type"],
      document_number: ticket_form["document_number"],
      deliverer_phone: ticket_form["deliverer_phone"],
      company_name: ticket_form["company_name"],
      position: ticket_form["position"],
      employee_number: ticket_form["employee_number"],
      authorization_type: ticket_form["authorization_type"],
      special_conditions: ticket_form["special_conditions"],
      # Campos específicos del tipo de entrada
      entry_type: Atom.to_string(entry_type),
      production_status: if(entry_type == :production, do: "pending_quote", else: nil)
    }
    
    case EvaaCrmGaepell.Fleet.create_maintenance_ticket(params) do
      {:ok, ticket} ->
        socket = 
          socket
          |> assign(:created_ticket, ticket)
          |> assign(:step, :success)
          |> assign(:show_photo_modal, true)
          |> allow_upload(:damage_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
        
        # Si es una orden de producción, mostrar el modal
        socket = if entry_type == :production do
          assign(socket, :show_production_order_modal, true)
        else
          socket
        end
        
        IO.inspect(socket.assigns.uploads, label: "DEBUG: Uploads after allow_upload")
        {:noreply, socket}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al crear el ticket. Por favor revisa los datos e inténtalo de nuevo.")}
    end
  end

  @impl true
  def handle_event("close_photo_modal", _params, socket) do
    {:noreply, assign(socket, show_photo_modal: false)}
  end

  @impl true
  def handle_event("skip_evaluation_photos", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_photo_modal, false)
     |> put_flash(:success, "✅ Ticket de evaluación creado exitosamente")
     |> push_navigate(to: ~p"/quotations")}
  end





  @impl true
  def handle_event("select_truck_from_results", %{"truck_id" => truck_id}, socket) do
    truck = EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.Truck, truck_id)
    if truck do
      {:noreply, assign(socket, step: :show_truck, found_truck: truck, plate: truck.license_plate, truck_changeset: nil)}
    else
      {:noreply, put_flash(socket, :error, "Camión no encontrado")}
    end
  end

  @impl true
  def handle_event("save_new_truck", %{"license_plate" => plate, "brand" => brand, "model" => model, "vin" => vin}, socket) do
    params = %{
      license_plate: plate,
      brand: brand,
      model: model,
      vin: vin,
      business_id: socket.assigns.current_user.business_id
    }
    
    case EvaaCrmGaepell.Truck.create_truck(params, socket.assigns.current_user.id) do
      {:ok, truck} ->
        {:noreply, assign(socket, step: :show_truck, found_truck: truck, plate: plate, truck_changeset: nil)}
      {:error, changeset} ->
        {:noreply, assign(socket, step: :new_checkin_camion, found_truck: nil, plate: plate, truck_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("new_checkin_camion", _params, socket) do
    companies = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.Company)
    {:noreply, assign(socket, step: :new_checkin_camion, truck_changeset: nil, companies: companies)}
  end

  @impl true
  def handle_event("new_checkin_pieza", _params, socket) do
    # Ir directamente al formulario de ticket enriquecido para artículos
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    default_ticket = %{
      title: "Check-in de artículo/pieza",
      entry_date: DateTime.to_iso8601(now),
      status: "check_in",
      color: "#8b5cf6", # Color púrpura para artículos
      exit_notes: "",
      visible_damage: "",
      article_type: "",
      article_brand: "",
      article_model: "",
      serial_number: "",
      article_condition: "new",
      location: "",
      supplier: "",
      special_conditions: ""
    }
    {:noreply, assign(socket, step: :article_ticket_details, ticket_form: default_ticket)}
  end

  @impl true
  def handle_event("ignore", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("cancel_photo", %{"key" => key, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, key, ref)}
  end

  @impl true
  def handle_event("photos_selected", _params, socket) do
    IO.inspect("DEBUG: Photos selected event received")
    {:noreply, socket}
  end

  @impl true
  def handle_event("signature_updated", %{"signature" => signature_data}, socket) do
    IO.inspect("DEBUG: Signature updated received")
    IO.inspect(String.length(signature_data), label: "DEBUG: Signature data length")
    # Only update if signature is not empty
    if String.length(signature_data) > 100 do
      {:noreply, assign(socket, signature_data: signature_data)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_photos_and_signature", %{"signature" => signature_data} = _params, socket) do
    IO.inspect("DEBUG: Save photos and signature received")
    IO.inspect(signature_data, label: "DEBUG: Signature data")
    
    # Validate signature
    if signature_data == "" or signature_data == nil do
      {:noreply, put_flash(socket, :error, "Debes agregar una firma digital.")}
    else
      # Process photos first
      if Map.has_key?(socket.assigns.uploads, :damage_photos) do
        upload = socket.assigns.uploads.damage_photos
        entries = upload.entries
        all_present = length(entries) > 0
        uploading_files = Enum.any?(entries, fn entry -> !entry.done? end)
        
        IO.inspect(entries, label: "DEBUG: Upload entries")
        IO.inspect(all_present, label: "DEBUG: All present")
        IO.inspect(uploading_files, label: "DEBUG: Uploading files")
        
        cond do
          !all_present ->
            {:noreply, put_flash(socket, :error, "Debes subir al menos una foto.")}
          uploading_files ->
            {:noreply, put_flash(socket, :error, "Espera a que se completen todas las subidas antes de guardar.")}
          true ->
            # Asegurar que el directorio existe
            uploads_dir = Path.expand("priv/static/uploads")
            File.mkdir_p!(uploads_dir)
            
            photo_urls = consume_uploaded_entries(socket, :damage_photos, fn %{path: path}, _entry ->
              filename = "ticket_#{socket.assigns.created_ticket.id}_#{System.system_time()}.jpg"
              dest = Path.join(uploads_dir, filename)
              File.mkdir_p!(Path.dirname(dest))
              File.cp!(path, dest)
              {:ok, "/uploads/#{filename}"}
            end)
            
            # Save signature as image file
            signature_filename = "signature_#{socket.assigns.created_ticket.id}_#{System.system_time()}.png"
            signature_path = Path.join(uploads_dir, signature_filename)
            
            # Convert base64 to image file
            signature_data_clean = String.replace(signature_data, "data:image/png;base64,", "")
            case Base.decode64(signature_data_clean) do
              {:ok, signature_binary} ->
                File.write!(signature_path, signature_binary)
                signature_url = "/uploads/#{signature_filename}"
                
                # Merge with existing photos and add signature
                new_photos = (socket.assigns.created_ticket.damage_photos || []) ++ photo_urls
                changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(socket.assigns.created_ticket, %{
                  damage_photos: new_photos,
                  signature_url: signature_url
                })
                
                case EvaaCrmGaepell.Repo.update(changeset) do
                  {:ok, _ticket} ->
                    {:noreply,
                      socket
                      |> assign(:show_photo_modal, false)
                      |> put_flash(:info, "Fotos y firma guardadas correctamente para el ticket ##{socket.assigns.created_ticket.id}.")
                    }
                  {:error, _changeset} ->
                    {:noreply, put_flash(socket, :error, "Error al guardar las fotos y firma.")}
                end
              _ ->
                {:noreply, put_flash(socket, :error, "Error al procesar la firma digital.")}
            end
        end
      else
        IO.inspect("DEBUG: No damage_photos upload found")
        {:noreply, put_flash(socket, :error, "Error: No se encontró la configuración de subida de fotos.")}
      end
    end
  end

  @impl true
  def handle_event("save_photos", _params, socket) do
    IO.inspect(socket.assigns.uploads, label: "DEBUG: All uploads in save_photos")
    
    if Map.has_key?(socket.assigns.uploads, :damage_photos) do
      upload = socket.assigns.uploads.damage_photos
      entries = upload.entries
      all_present = length(entries) > 0
      uploading_files = Enum.any?(entries, fn entry -> !entry.done? end)
      
      IO.inspect(entries, label: "DEBUG: Upload entries")
      IO.inspect(all_present, label: "DEBUG: All present")
      IO.inspect(uploading_files, label: "DEBUG: Uploading files")
      
      cond do
        !all_present ->
          {:noreply, put_flash(socket, :error, "Debes subir al menos una foto.")}
        uploading_files ->
          {:noreply, put_flash(socket, :error, "Espera a que se completen todas las subidas antes de guardar.")}
        true ->
          # Asegurar que el directorio existe
          uploads_dir = Path.expand("priv/static/uploads")
          File.mkdir_p!(uploads_dir)
          
          photo_urls = consume_uploaded_entries(socket, :damage_photos, fn %{path: path}, _entry ->
            filename = "ticket_#{socket.assigns.created_ticket.id}_#{System.system_time()}.jpg"
            dest = Path.join(uploads_dir, filename)
            File.mkdir_p!(Path.dirname(dest))
            File.cp!(path, dest)
            {:ok, "/uploads/#{filename}"}
          end)
          # Merge with existing photos
          new_photos = (socket.assigns.created_ticket.damage_photos || []) ++ photo_urls
          changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(socket.assigns.created_ticket, %{damage_photos: new_photos})
          case EvaaCrmGaepell.Repo.update(changeset) do
            {:ok, _ticket} ->
              {:noreply,
                socket
                |> assign(:show_photo_modal, false)
                |> put_flash(:info, "Fotos guardadas correctamente para el ticket ##{socket.assigns.created_ticket.id}.")
              }
            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "Error al guardar las fotos.")}
          end
      end
    else
      IO.inspect("DEBUG: No damage_photos upload found")
      {:noreply, put_flash(socket, :error, "Error: No se encontró la configuración de subida de fotos.")}
    end
  end

  @impl true
  def handle_info({:photos_uploaded, ticket_id}, socket) do
    {:noreply,
      socket
      |> assign(:show_photo_modal, false)
      |> put_flash(:info, "Fotos guardadas correctamente para el ticket ##{ticket_id}.")
    }
  end

  @impl true
  def handle_event("show_photo_upload_modal", _params, socket) do
    socket = allow_upload(socket, :damage_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
    {:noreply, assign(socket, show_photo_modal: true)}
  end

  @impl true
  def handle_event("save_evaluation_photos", _params, socket) do
    # Check if there are any files selected and if they're all uploaded
    entries = socket.assigns.uploads.damage_photos.entries
    all_present = length(entries) > 0
    uploading_files = Enum.any?(entries, fn entry -> !entry.done? end)
    
    cond do
      !all_present ->
        {:noreply, 
         socket
         |> put_flash(:error, "Por favor selecciona al menos una foto")
         |> assign(:show_photo_modal, true)}
      
      uploading_files ->
        {:noreply, 
         socket
         |> put_flash(:error, "Espera a que se completen todas las subidas antes de guardar")
         |> assign(:show_photo_modal, true)}
      
      true ->
        # Asegurar que el directorio existe
        uploads_dir = Path.expand("priv/static/uploads")
        File.mkdir_p!(uploads_dir)
        
        photo_urls = consume_uploaded_entries(socket, :damage_photos, fn %{path: path}, _entry ->
          filename = "evaluation_#{socket.assigns.created_ticket.id}_#{System.system_time()}.jpg"
          dest = Path.join(uploads_dir, filename)
          File.mkdir_p!(Path.dirname(dest))
          File.cp!(path, dest)
          {:ok, "/uploads/#{filename}"}
        end)
        
        # Add photos to the evaluation ticket
        current_photos = socket.assigns.created_ticket.damage_photos || []
        new_photos = current_photos ++ photo_urls
        
        case socket.assigns.created_ticket 
             |> EvaaCrmGaepell.MaintenanceTicket.changeset(%{damage_photos: new_photos})
             |> EvaaCrmGaepell.Repo.update() do
          {:ok, _ticket} ->
            {:noreply,
             socket
             |> assign(:show_photo_modal, false)
             |> put_flash(:success, "✅ Ticket de evaluación creado exitosamente con #{length(photo_urls)} foto(s)")
             |> push_navigate(to: ~p"/quotations")}
          
          {:error, _changeset} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al guardar las fotos de evaluación")
             |> assign(:show_photo_modal, false)}
        end
    end
  end

  @impl true
  def handle_event("save_photos_and_signature", _params, socket) do
    # Save photos and signature logic here
    IO.inspect("DEBUG: Save photos and signature")
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_new_checkin_modal", _params, socket) do
    {:noreply, assign(socket, show_new_checkin_modal: true)}
  end

  @impl true
  def handle_event("hide_new_checkin_modal", _params, socket) do
    {:noreply, assign(socket, show_new_checkin_modal: false)}
  end

  @impl true
  def handle_event("show_new_truck_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(show_new_checkin_modal: false)
     |> assign(show_new_truck_form: true)
     |> assign(new_truck: %EvaaCrmGaepell.Truck{})}
  end

  @impl true
  def handle_event("hide_new_truck_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(show_new_truck_form: false)
     |> assign(new_truck: nil)}
  end



  @impl true
  def handle_event("save_evaluation_ticket", %{"evaluation" => evaluation_params}, socket) do
    found_truck = socket.assigns.found_truck
    upload = socket.assigns.uploads.evaluation_photos
    
    # Debug: Verificar si hay archivos en el upload
    IO.inspect(upload.entries, label: "[DEBUG] upload.entries")
    IO.inspect(upload.errors, label: "[DEBUG] upload.errors")
    
    # Verificar que todos los archivos estén completados antes de consumirlos
    incomplete_entries = Enum.filter(upload.entries, fn entry -> !entry.done? end)
    
    if length(incomplete_entries) > 0 do
      IO.puts("[DEBUG] Hay archivos aún en progreso, esperando...")
      {:noreply, put_flash(socket, :error, "Por favor espera a que todos los archivos se suban completamente antes de guardar")}
    else
      uploaded_files = consume_uploaded_entries(socket, :evaluation_photos, fn %{path: path} = meta, entry ->
        IO.inspect(meta, label: "[DEBUG] meta")
        IO.inspect(entry, label: "[DEBUG] entry")
        filename = "evaluation_#{found_truck.id}_#{System.system_time()}_#{entry.client_name}"
        uploads_dir = Path.expand("priv/static/uploads")
        dest = Path.join([uploads_dir, filename])
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
        
      # Create evaluation ticket
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      
      # Preparar descripción basada en el tipo de evaluación
      description = case evaluation_params["evaluation_type"] do
        "warranty" -> 
          warranty_details = evaluation_params["warranty_details"] || ""
          "Garantía: #{warranty_details}"
        _ -> 
          evaluation_params["damage_description"] || ""
      end
      
      # Get evaluation type label
      evaluation_type = evaluation_params["evaluation_type"] || "collision"
      type_label = get_evaluation_type_label(evaluation_type)
      
      ticket_attrs = %{
        title: "#{type_label} - #{found_truck.license_plate}",
        description: description,
        entry_date: now,
        mileage: found_truck.kilometraje || 0,
        fuel_level: "full",
        status: "check_in",
        color: "#8b5cf6", # Purple color for evaluations
        visible_damage: description,
        evaluation_type: evaluation_params["evaluation_type"] || "collision",
        evaluation_notes: evaluation_params["evaluation_notes"] || "",
        warranty_details: evaluation_params["warranty_details"] || "",
        truck_id: found_truck.id,
        business_id: socket.assigns.current_user.business_id,
        specialist_id: nil, # Will be assigned later
        damage_photos: photo_urls
      }
        
      case %EvaaCrmGaepell.MaintenanceTicket{} |> EvaaCrmGaepell.MaintenanceTicket.changeset(ticket_attrs) |> EvaaCrmGaepell.Repo.insert() do
        {:ok, ticket} ->
          # Crear registros de TruckPhoto para cada foto con tag de evaluación
          Enum.each(photo_urls, fn photo_url ->
            photo_attrs = %{
              truck_id: found_truck.id,
              photo_url: photo_url,
              photo_type: "evaluation",
              description: "Foto de evaluación - #{evaluation_params["damage_description"] || "Sin descripción"}",
              maintenance_ticket_id: ticket.id,
              business_id: socket.assigns.current_user.business_id
            }
            
            %EvaaCrmGaepell.TruckPhoto{} 
            |> EvaaCrmGaepell.TruckPhoto.changeset(photo_attrs)
            |> EvaaCrmGaepell.Repo.insert()
          end)
          
            {:noreply, 
             socket
           |> put_flash(:success, "Ticket de evaluación creado exitosamente con #{length(photo_urls)} fotos")
             |> push_navigate(to: ~p"/quotations")}
          
        {:error, changeset} ->
            {:noreply, 
             socket
           |> put_flash(:error, "Error al crear el ticket de evaluación: #{inspect(changeset.errors)}")}
        end
    end
  end





  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :evaluation_photos, ref)}
  end

  @impl true
  def handle_event("save_new_truck", %{"truck" => truck_params}, socket) do
    # Add business_id to truck params
    truck_params = Map.put(truck_params, "business_id", socket.assigns.current_user.business_id)
    
    case EvaaCrmGaepell.Truck.create_truck(truck_params, socket.assigns.current_user.id) do
      {:ok, truck} ->
        # Check if we're in evaluation flow
        if socket.assigns.entry_type == :quotation do
          # For evaluation flow, continue to evaluation details
          {:noreply, 
           socket
           |> put_flash(:info, "Camión registrado exitosamente")
           |> assign(show_new_truck_form: false)
           |> assign(new_truck: nil)
           |> assign(found_truck: truck)
           |> assign(step: :quotation_details)
           |> assign(:evaluation_form_data, %{}) # Inicializar datos del formulario
           |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)}
        else
          # For other flows, redirect to search by plate
        {:noreply, 
         socket
         |> put_flash(:info, "Camión registrado exitosamente")
         |> assign(show_new_truck_form: false)
         |> assign(new_truck: nil)
         |> assign(search_plate: truck.license_plate)
         |> assign(show_search_modal: true)}
        end
      
      {:error, changeset} ->
        {:noreply, assign(socket, new_truck: changeset)}
    end
  end

  @impl true
  def handle_event("hide_search_modal", _params, socket) do
    {:noreply, assign(socket, show_search_modal: false, search_plate: nil)}
  end

  @impl true
  def handle_event("continue_to_checkin", _params, socket) do
    # Buscar el camión por placa y continuar al flujo normal
    truck = EvaaCrmGaepell.Repo.get_by(EvaaCrmGaepell.Truck, license_plate: socket.assigns.search_plate)
    companies = EvaaCrmGaepell.Repo.all(EvaaCrmGaepell.Company)
    
    if truck do
      {:noreply, 
       socket
       |> assign(show_search_modal: false)
       |> assign(step: :show_truck)
       |> assign(found_truck: truck)
       |> assign(plate: socket.assigns.search_plate)
       |> assign(companies: companies)}
    else
      {:noreply, 
       socket
       |> put_flash(:error, "No se encontró el camión registrado")
       |> assign(show_search_modal: false)}
    end
  end

  @impl true
  def handle_event("search_another_plate", _params, socket) do
    {:noreply, 
     socket
     |> assign(show_search_modal: false)
     |> assign(step: :search_plate)
     |> assign(search_plate: nil)}
  end

  @impl true
  def handle_event("back_to_wizard", _params, socket) do
    {:noreply, 
     socket
     |> assign(show_search_modal: false)
     |> assign(step: :select_scenario)
     |> assign(scenario: nil)
     |> assign(search_plate: nil)}
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    current_step = socket.assigns.step
    
    case current_step do
      :ticket_details ->
        # Volver a la selección de camión
        {:noreply, assign(socket, step: :show_truck)}
      
      :quotation_details ->
        # Volver a la selección de camión para evaluación
        {:noreply, assign(socket, step: :evaluation_quotation_type)}
      
      :capture_damages ->
        # Volver a los detalles del ticket
        {:noreply, assign(socket, step: :ticket_details)}
      
      :article_ticket_details ->
        # Volver a la selección de escenario
        {:noreply, assign(socket, step: :select_scenario)}
      
      :new_checkin_camion ->
        # Volver a la búsqueda
        {:noreply, assign(socket, step: :search_unified)}
      
      :search_unified ->
        # Volver a la selección de escenario
        {:noreply, assign(socket, step: :select_scenario)}
      
      :show_truck ->
        # Volver a la búsqueda
        {:noreply, assign(socket, step: :search_unified)}
      
      _ ->
        # Por defecto, volver a la selección de escenario
        {:noreply, assign(socket, step: :select_scenario)}
    end
  end

  @impl true
  def handle_event("save_article_ticket_details", %{"ticket" => ticket_params}, socket) do
    current_user = socket.assigns.current_user
    
    # Crear ticket de artículo sin truck_id
    params = %{
      user_id: current_user && current_user.id,
      status: ticket_params["status"] || "check_in",
      visible_damage: ticket_params["special_conditions"] || "",
      title: ticket_params["title"] || "Check-in de artículo",
      business_id: current_user.business_id,
      entry_date: parse_datetime_local(ticket_params["entry_date"]) || DateTime.utc_now(),
      priority: "medium",
      color: ticket_params["color"] || "#8b5cf6",
      description: build_article_description(ticket_params),
      exit_notes: ticket_params["exit_notes"] || ""
    }
    
    case EvaaCrmGaepell.Fleet.create_maintenance_ticket(params) do
      {:ok, ticket} ->
        socket = 
          socket
          |> assign(:created_ticket, ticket)
          |> assign(:step, :success)
          |> assign(:show_photo_modal, true)
          |> allow_upload(:damage_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
        IO.inspect(socket.assigns.uploads, label: "DEBUG: Uploads after allow_upload")
        {:noreply, socket}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al crear el ticket. Por favor revisa los datos e inténtalo de nuevo.")}
    end
  end

  # Función auxiliar para construir descripción del entregador
  defp build_deliverer_description(ticket_params) do
    parts = []
    
    # Información personal del entregador
    parts = if ticket_params["deliverer_name"] && ticket_params["deliverer_name"] != "" do
      parts ++ ["Entregador: #{ticket_params["deliverer_name"]}"]
    else
      parts
    end
    
    parts = if ticket_params["document_type"] && ticket_params["document_type"] != "" do
      doc_type = case ticket_params["document_type"] do
        "cedula" -> "Cédula"
        "pasaporte" -> "Pasaporte"
        "otro" -> "Otro"
        _ -> ticket_params["document_type"]
      end
      parts ++ ["Doc: #{doc_type} #{ticket_params["document_number"]}"]
    else
      parts
    end
    
    parts = if ticket_params["deliverer_phone"] && ticket_params["deliverer_phone"] != "" do
      parts ++ ["Tel: #{ticket_params["deliverer_phone"]}"]
    else
      parts
    end
    
    # Información laboral/institucional
    parts = if ticket_params["company_name"] && ticket_params["company_name"] != "" do
      parts ++ ["Empresa: #{ticket_params["company_name"]}"]
    else
      parts
    end
    
    parts = if ticket_params["position"] && ticket_params["position"] != "" do
      parts ++ ["Cargo: #{ticket_params["position"]}"]
    else
      parts
    end
    
    parts = if ticket_params["employee_number"] && ticket_params["employee_number"] != "" do
      parts ++ ["Empleado: #{ticket_params["employee_number"]}"]
    else
      parts
    end
    
    parts = if ticket_params["authorization_type"] && ticket_params["authorization_type"] != "" do
      auth_type = case ticket_params["authorization_type"] do
        "propietario" -> "Propietario"
        "representante" -> "Representante autorizado"
        "empleado" -> "Empleado"
        "conductor" -> "Conductor asignado"
        _ -> ticket_params["authorization_type"]
      end
      parts ++ ["Autorización: #{auth_type}"]
    else
      parts
    end
    
    # Información del vehículo
    parts = if ticket_params["mileage"] && ticket_params["mileage"] != "" do
      parts ++ ["KM: #{ticket_params["mileage"]}"]
    else
      parts
    end
    
    parts = if ticket_params["fuel_level"] && ticket_params["fuel_level"] != "" do
      fuel_level = case ticket_params["fuel_level"] do
        "empty" -> "Vacío"
        "quarter" -> "1/4"
        "half" -> "1/2"
        "three_quarters" -> "3/4"
        "full" -> "Lleno"
        _ -> ticket_params["fuel_level"]
      end
      parts ++ ["Combustible: #{fuel_level}"]
    else
      parts
    end
    
    Enum.join(parts, " | ")
  end

  # Función auxiliar para construir descripción del artículo
  defp build_article_description(ticket_params) do
    parts = []
    
    parts = if ticket_params["article_type"] && ticket_params["article_type"] != "" do
      parts ++ ["Tipo: #{ticket_params["article_type"]}"]
    else
      parts
    end
    
    parts = if ticket_params["article_brand"] && ticket_params["article_brand"] != "" do
      parts ++ ["Marca: #{ticket_params["article_brand"]}"]
    else
      parts
    end
    
    parts = if ticket_params["article_model"] && ticket_params["article_model"] != "" do
      parts ++ ["Modelo: #{ticket_params["article_model"]}"]
    else
      parts
    end
    
    parts = if ticket_params["serial_number"] && ticket_params["serial_number"] != "" do
      parts ++ ["S/N: #{ticket_params["serial_number"]}"]
    else
      parts
    end
    
    parts = if ticket_params["article_condition"] && ticket_params["article_condition"] != "" do
      parts ++ ["Estado: #{ticket_params["article_condition"]}"]
    else
      parts
    end
    
    parts = if ticket_params["location"] && ticket_params["location"] != "" do
      parts ++ ["Ubicación: #{ticket_params["location"]}"]
    else
      parts
    end
    
    parts = if ticket_params["supplier"] && ticket_params["supplier"] != "" do
      parts ++ ["Proveedor: #{ticket_params["supplier"]}"]
    else
      parts
    end
    
    parts = if ticket_params["invoice_number"] && ticket_params["invoice_number"] != "" do
      parts ++ ["Factura: #{ticket_params["invoice_number"]}"]
    else
      parts
    end
    
    Enum.join(parts, " | ")
  end

  @impl true
  def render(assigns) do
    assigns =
      if assigns[:step] == :upload_photos and not Map.has_key?(assigns, :uploads) and Map.has_key?(assigns, :socket) do
        ensure_uploads_allowed(assigns.socket).assigns
      else
        assigns
      end

    ~H"""
    <div class="max-w-xl mx-auto py-8">
      <%= if @step == :select_scenario do %>
        <h1 class="text-2xl font-bold mb-6 text-center">Check-in de Entrada</h1>
        <div class="grid grid-cols-1 gap-6">
          <button phx-click="select_scenario" phx-value-scenario="evaluation_quotation" class="w-full py-8 rounded-lg bg-purple-600 text-white text-xl font-semibold shadow hover:bg-purple-700 transition flex items-center justify-center gap-3">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <span>Evaluación & Cotización</span>
          </button>
          <button phx-click="select_scenario" phx-value-scenario="maintenance_checkin" class="w-full py-8 rounded-lg bg-red-500 text-white text-xl font-semibold shadow hover:bg-red-600 transition">
            <div class="flex items-center justify-center gap-3">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
              </svg>
              <span>🛠️ Check-in de Mantenimiento (camión con caja)</span>
            </div>
          </button>
          <button phx-click="select_scenario" phx-value-scenario="production_order" class="w-full py-8 rounded-lg bg-green-500 text-white text-xl font-semibold shadow hover:bg-green-600 transition">
            <div class="flex items-center justify-center gap-3">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
              </svg>
              <span>📦 Orden de Producción (camión sin caja)</span>
            </div>
          </button>
        </div>
      <% end %>



      <%= if @step == :show_truck and @found_truck do %>
        <h2 class="text-xl font-bold mb-4 text-center">Camión encontrado</h2>
        <div class="bg-gray-100 dark:bg-gray-800 rounded p-4 mb-4">
          <p><b>Placa:</b> <%= @found_truck.license_plate %></p>
          <p><b>Marca:</b> <%= @found_truck.brand %></p>
          <p><b>Modelo:</b> <%= @found_truck.model %></p>
          <p><b>VIN:</b> <%= @found_truck.vin %></p>
          <p><b>Año:</b> <%= @found_truck.year %></p>
          <p><b>Kilometraje:</b> <%= if @found_truck.kilometraje, do: "#{@found_truck.kilometraje} km", else: "No registrado" %></p>
        </div>
        <button phx-click="continue_to_ticket_details" class="w-full py-3 rounded bg-green-600 text-white font-semibold mb-2">Continuar check-in</button>
        <button phx-click="back_to_select" class="w-full py-3 rounded bg-gray-300 text-gray-800 font-semibold">Buscar otro camión</button>
      <% end %>

      <%= if @step == :ticket_details and @ticket_form do %>
        <h2 class="text-xl font-bold mb-4 text-center">Detalles del Ticket</h2>
        <form phx-submit="save_ticket_details" class="space-y-4">
          
          <!-- Información del Entregador - PROTECCIÓN LEGAL -->
          <div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-4 mb-4 border-l-4 border-red-500">
            <h3 class="text-lg font-semibold mb-3 text-red-900 dark:text-red-100 flex items-center">
              <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
              </svg>
              Información del Entregador (OBLIGATORIO)
            </h3>
            <p class="text-sm text-red-700 dark:text-red-300 mb-4">Esta información es requerida para protección legal de la compañía.</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Nombre Completo *</label>
                <input name="ticket[deliverer_name]" value={@ticket_form["deliverer_name"]} required 
                       placeholder="Nombre y apellidos completos"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Tipo de Documento *</label>
                <select name="ticket[document_type]" required 
                        class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700">
                  <option value="">Seleccionar tipo</option>
                  <option value="cedula" selected={@ticket_form["document_type"] == "cedula"}>Cédula</option>
                  <option value="pasaporte" selected={@ticket_form["document_type"] == "pasaporte"}>Pasaporte</option>
                  <option value="otro" selected={@ticket_form["document_type"] == "otro"}>Otro</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Número de Documento *</label>
                <input name="ticket[document_number]" value={@ticket_form["document_number"]} required 
                       placeholder="Número completo del documento"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Teléfono de Contacto *</label>
                <input name="ticket[deliverer_phone]" value={@ticket_form["deliverer_phone"]} required 
                       placeholder="Número de teléfono"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>

            </div>
          </div>

          <!-- Información Laboral/Institucional -->
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-blue-900 dark:text-blue-100">Información Laboral/Institucional</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Empresa/Institución</label>
                <input name="ticket[company_name]" value={@ticket_form["company_name"]} 
                       placeholder="Nombre de la empresa o institución"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Cargo/Puesto</label>
                <input name="ticket[position]" value={@ticket_form["position"]} 
                       placeholder="Cargo o puesto en la empresa"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Número de Empleado</label>
                <input name="ticket[employee_number]" value={@ticket_form["employee_number"]} 
                       placeholder="Número de empleado (si aplica)"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Autorización para Entrega</label>
                <select name="ticket[authorization_type]" 
                        class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700">
                  <option value="">Seleccionar tipo</option>
                  <option value="propietario" selected={@ticket_form["authorization_type"] == "propietario"}>Propietario del vehículo/artículo</option>
                  <option value="representante" selected={@ticket_form["authorization_type"] == "representante"}>Representante autorizado</option>
                  <option value="empleado" selected={@ticket_form["authorization_type"] == "empleado"}>Empleado de la empresa</option>
                  <option value="conductor" selected={@ticket_form["authorization_type"] == "conductor"}>Conductor asignado</option>
                  <option value="otros" selected={@ticket_form["authorization_type"] == "otros"}>Otros</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Información del Vehículo/Artículo -->
          <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-green-900 dark:text-green-100">Información del Vehículo/Artículo</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Fecha de Entrada</label>
                <input name="ticket[entry_date]" type="datetime-local" 
                       value={@ticket_form["entry_date"] && String.slice(@ticket_form["entry_date"], 0, 16)} required 
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Kilometraje</label>
                <input name="ticket[mileage]" type="number" value={@ticket_form["mileage"]} 
                       placeholder="Kilometraje actual"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Nivel de Combustible</label>
                <select name="ticket[fuel_level]" 
                        class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700">
                  <option value="empty" selected={@ticket_form["fuel_level"] == "empty"}>Vacío</option>
                  <option value="quarter" selected={@ticket_form["fuel_level"] == "quarter"}>1/4</option>
                  <option value="half" selected={@ticket_form["fuel_level"] == "half"}>1/2</option>
                  <option value="three_quarters" selected={@ticket_form["fuel_level"] == "three_quarters"}>3/4</option>
                  <option value="full" selected={@ticket_form["fuel_level"] == "full"}>Lleno</option>
                </select>
              </div>
            </div>
          </div>
          
          <!-- Observaciones y Condiciones -->
          <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-yellow-900 dark:text-yellow-100">Observaciones y Condiciones</h3>
            <div class="space-y-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Observaciones del Estado</label>
                <textarea name="ticket[exit_notes]" rows="3"
                          placeholder="Observaciones sobre el estado del vehículo/artículo al momento de la entrega"
                          class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @ticket_form["exit_notes"] %></textarea>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Condiciones Especiales</label>
                <textarea name="ticket[special_conditions]" rows="2"
                          placeholder="Condiciones especiales de almacenamiento, manejo, o requisitos específicos"
                          class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @ticket_form["special_conditions"] %></textarea>
              </div>
            </div>
          </div>
          
          <!-- Configuración del Evento -->
          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
            <h3 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">Configuración del Evento</h3>
            <div>
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Color del Evento</label>
              <input name="ticket[color]" type="color" value={@ticket_form["color"] || "#3b82f6"} 
                     class="w-16 h-8 p-0 border-0 bg-transparent cursor-pointer align-middle rounded-full shadow" />
            </div>
          </div>
          
          <div class="flex space-x-3">
            <button type="button" phx-click="go_back" class="flex-1 py-3 rounded bg-gray-300 text-gray-800 font-semibold hover:bg-gray-400">
              <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
              Volver
            </button>
            <button type="submit" class="flex-1 py-3 rounded bg-blue-600 text-white font-semibold hover:bg-blue-700">
              Continuar a Fotos y Firma
            </button>
          </div>
        </form>
      <% end %>

      <%= if @step == :quotation_details and @found_truck do %>
        <h2 class="text-xl font-bold mb-4 text-center">Detalles de Evaluación</h2>
        <div class="bg-gray-100 dark:bg-gray-800 rounded p-4 mb-4">
          <h3 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">Camión Seleccionado</h3>
          <p><b>Placa:</b> <%= @found_truck.license_plate %></p>
          <p><b>Marca:</b> <%= @found_truck.brand %></p>
          <p><b>Modelo:</b> <%= @found_truck.model %></p>
          <p><b>VIN:</b> <%= @found_truck.vin %></p>
          <p><b>Año:</b> <%= @found_truck.year %></p>
          <p><b>Kilometraje:</b> <%= if @found_truck.kilometraje, do: "#{@found_truck.kilometraje} km", else: "No registrado" %></p>
        </div>
        
        <form phx-submit="save_evaluation_ticket" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Descripción del Daño/Problema *</label>
            <textarea name="evaluation[damage_description]" rows="4" required
                      placeholder="Describe detalladamente el daño o problema que requiere evaluación..."
                      class="w-full p-3 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @evaluation_form_data && @evaluation_form_data["damage_description"] %></textarea>
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Tipo de Evaluación</label>
            <select name="evaluation[evaluation_type]" onchange="toggleWarrantyField(this.value)" class="w-full p-3 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700">
              <option value="collision">Evaluación de Choque</option>
              <option value="maintenance">Evaluación de Mantenimiento</option>
              <option value="warranty">Garantía</option>
              <option value="other">Otro</option>
            </select>
          </div>
          
          <div id="warranty-field" style="display: none;">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Detalles de Garantía *</label>
            <textarea name="evaluation[warranty_details]" rows="4" required
                      placeholder="Describe detalladamente los detalles de la garantía a trabajar..."
                      class="w-full p-3 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @evaluation_form_data && @evaluation_form_data["warranty_details"] %></textarea>
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Observaciones Adicionales</label>
                          <textarea name="evaluation[evaluation_notes]" rows="3"
                        placeholder="Observaciones adicionales sobre la evaluación..."
                        class="w-full p-3 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @evaluation_form_data && @evaluation_form_data["evaluation_notes"] %></textarea>
          </div>
          
          <!-- Sección de Fotos de Evaluación -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Fotos de Evaluación</label>
            <div class="border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg p-6 text-center">
              <svg class="mx-auto h-8 w-8 text-gray-400 mb-2" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              <label class="relative cursor-pointer bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md font-medium transition-colors">
                <span>Subir fotos</span>
                <.live_file_input upload={@uploads.evaluation_photos} class="hidden" />
              </label>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-2">PNG, JPG, GIF hasta 10MB (máximo 10 fotos)</p>
              <div class="upload-preview-container mt-2">
                <%= if Enum.empty?(@uploads.evaluation_photos.entries) do %>
                  <div class="text-xs text-gray-400 mt-2">No hay archivos seleccionados.</div>
                <% else %>
                  <div class="text-xs text-gray-700 dark:text-gray-300 mt-2 font-semibold">Archivos listos para subir:</div>
                  <%= for entry <- @uploads.evaluation_photos.entries do %>
                    <div class="mt-2 flex items-center gap-2">
                      <img
                        phx-upload-preview={entry.ref}
                        class="w-16 h-16 object-cover rounded border border-gray-300 dark:border-gray-700"
                        alt="Preview"
                      />
                      <div class="flex-1">
                        <span class="text-xs text-gray-700 dark:text-gray-300"><%= entry.client_name %></span>
                        <%= if entry.progress < 100 do %>
                          <div class="w-full bg-gray-200 rounded-full h-1 mt-1">
                            <div class="bg-purple-600 h-1 rounded-full" style={"width: #{entry.progress}%"}>
                            </div>
                          </div>
                          <span class="text-xs text-gray-500">Subiendo... <%= entry.progress %>%</span>
                        <% else %>
                          <span class="text-xs text-green-600">✓ Completado</span>
                        <% end %>
                      </div>
                      <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-red-500 text-xs ml-2">Eliminar</button>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
          
          <div class="flex space-x-3">
            <button type="button" phx-click="go_back" class="flex-1 py-3 rounded bg-gray-300 text-gray-800 font-semibold hover:bg-gray-400">
              <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
              Volver
            </button>
            <button type="submit" class="flex-1 py-3 rounded bg-purple-600 text-white font-semibold hover:bg-purple-700">
              Crear Ticket de Evaluación
            </button>
          </div>
        </form>
      <% end %>

      <%= if @step == :new_checkin_camion and !@found_truck do %>
        <h2 class="text-xl font-bold mb-4 text-center">Registrar nuevo camión</h2>
        <form phx-submit="save_new_truck" class="mb-4">
          <input name="license_plate" placeholder="Placa" class="w-full p-4 rounded border mb-4 text-lg text-gray-900 dark:text-white bg-white dark:bg-gray-700" value={@plate || ""} />
          <input name="brand" placeholder="Marca" class="w-full p-4 rounded border mb-4 text-lg text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
          <input name="model" placeholder="Modelo" class="w-full p-4 rounded border mb-4 text-lg text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
          <input name="vin" placeholder="VIN" class="w-full p-4 rounded border mb-4 text-lg text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
          <div class="flex space-x-3">
            <button type="button" phx-click="go_back" class="flex-1 py-3 rounded bg-gray-300 text-gray-800 font-semibold hover:bg-gray-400">
              <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
              Volver
            </button>
            <button type="submit" class="flex-1 py-3 rounded bg-blue-600 text-white font-semibold hover:bg-blue-700">
              Registrar y continuar
            </button>
          </div>
        </form>
        <%= if @truck_changeset && @truck_changeset.errors != [] do %>
          <div class="bg-red-100 text-red-700 rounded p-2 mb-2">
            <ul>
              <%= for {field, {msg, _}} <- @truck_changeset.errors do %>
                <li><%= Phoenix.Naming.humanize(field) %>: <%= msg %></li>
              <% end %>
            </ul>
          </div>
        <% end %>
      <% end %>

      <%= if @step == :search_unified do %>
        <h2 class="text-xl font-bold mb-4 text-center">Buscar por Marca, Modelo o Placa</h2>
        <div class="mb-4">
          <div class="relative">
            <input phx-keyup="filter_trucks" phx-debounce="300" name="search_term" 
                   placeholder="Escriba marca, modelo o placa (ej: Mercedes, Actros, ABC-123)" 
                   class="w-full p-4 pr-12 rounded border mb-4 text-lg text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
            <div class="absolute right-4 top-1/2 transform -translate-y-1/2">
              <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
            </div>
          </div>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            <%= if @filtered_trucks do %>
              <%= length(@filtered_trucks) %> camión(es) encontrado(s)
            <% else %>
              Cargando camiones...
            <% end %>
          </p>
        </div>
        
        <%= if @filtered_trucks && length(@filtered_trucks) > 0 do %>
          <div class="space-y-3 mb-4 max-h-96 overflow-y-auto">
            <%= for truck <- @filtered_trucks do %>
              <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <div class="flex items-center gap-2 mb-2">
                      <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
                      </svg>
                      <p class="font-semibold text-lg text-gray-900 dark:text-white"><%= truck.brand %> <%= truck.model %></p>
                    </div>
                    <div class="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <p class="text-gray-500 dark:text-gray-400">Placa</p>
                        <p class="font-medium text-gray-900 dark:text-white"><%= truck.license_plate %></p>
                      </div>
                      <div>
                        <p class="text-gray-500 dark:text-gray-400">Año</p>
                        <p class="font-medium text-gray-900 dark:text-white"><%= truck.year || "N/A" %></p>
                      </div>
                      <div>
                        <p class="text-gray-500 dark:text-gray-400">Kilometraje</p>
                        <p class="font-medium text-gray-900 dark:text-white">
                          <%= if truck.kilometraje, do: "#{truck.kilometraje} km", else: "No registrado" %>
                        </p>
                      </div>
                      <div>
                        <p class="text-gray-500 dark:text-gray-400">Estado</p>
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          <%= truck.status || "Activo" %>
                        </span>
                      </div>
                    </div>
                  </div>
                  <button phx-click="select_truck_from_results" phx-value-truck_id={truck.id} 
                          class="ml-4 px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium">
                    Seleccionar
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-center py-12 text-gray-500 dark:text-gray-400">
            <svg class="w-16 h-16 mx-auto mb-4 text-gray-300 dark:text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6-4h6m2 5.291A7.962 7.962 0 0112 15c-2.34 0-4.47-.881-6.08-2.33"></path>
            </svg>
            <p class="text-lg font-medium mb-2">No se encontraron camiones</p>
            <p class="text-sm">Intente con otro término de búsqueda o verifique la ortografía</p>
          </div>
        <% end %>
        
        <button phx-click="go_back" class="w-full py-3 rounded bg-gray-300 text-gray-800 font-semibold hover:bg-gray-400">
          <svg class="w-5 h-5 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
          </svg>
          Volver
        </button>
      <% end %>



      <%= if @step == :new_checkin_type and @entry_type == :maintenance do %>
        <h2 class="text-xl font-bold mb-4 text-center">Nuevo check-in de mantenimiento</h2>
        <div class="grid grid-cols-1 gap-4 mb-4">
          <button phx-click="show_existing_trucks_modal" class="w-full py-6 rounded-lg bg-green-500 text-white text-lg font-semibold shadow hover:bg-green-600 transition flex items-center justify-center gap-3">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
            </svg>
            Seleccionar camión existente
          </button>
          <button phx-click="show_new_truck_form" class="w-full py-6 rounded-lg bg-blue-500 text-white text-lg font-semibold shadow hover:bg-blue-600 transition">Registrar nuevo camión</button>
          <button phx-click="new_checkin_pieza" class="w-full py-6 rounded-lg bg-purple-500 text-white text-lg font-semibold shadow hover:bg-purple-600 transition">Pieza o artículo</button>
        </div>
        <button phx-click="back_to_select" class="mt-2 text-yellow-600 underline">Volver</button>
      <% end %>

      <%= if @step == :new_checkin_type and @entry_type == :production do %>
        <h2 class="text-xl font-bold mb-4 text-center">Orden de Producción</h2>
        <p class="text-center text-gray-600 dark:text-gray-400 mb-6">Selecciona el camión para el cual se producirá la caja</p>
        <div class="grid grid-cols-1 gap-4 mb-4">
          <button phx-click="show_existing_trucks_modal" class="w-full py-6 rounded-lg bg-green-500 text-white text-lg font-semibold shadow hover:bg-green-600 transition flex items-center justify-center gap-3">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
            </svg>
            Seleccionar camión existente
          </button>
          <button phx-click="show_new_truck_form" class="w-full py-6 rounded-lg bg-blue-500 text-white text-lg font-semibold shadow hover:bg-blue-600 transition flex items-center justify-center gap-3">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
            </svg>
            Registrar nuevo camión
          </button>
        </div>
        <button phx-click="back_to_select" class="mt-2 text-yellow-600 underline">Volver</button>
      <% end %>

      <%= if @step == :evaluation_quotation_type and @entry_type == :quotation do %>
        <h2 class="text-xl font-bold mb-4 text-center">Ticket de Evaluación</h2>
        <p class="text-center text-gray-600 dark:text-gray-400 mb-6">Selecciona el camión para crear un ticket de evaluación que luego se vinculará con la cotización</p>
        <div class="grid grid-cols-1 gap-4 mb-4">
          <button phx-click="show_existing_trucks_modal" class="w-full py-6 rounded-lg bg-green-500 text-white text-lg font-semibold shadow hover:bg-green-600 transition flex items-center justify-center gap-3">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
            </svg>
            Seleccionar camión existente
          </button>
          <button phx-click="show_new_truck_form" class="w-full py-6 rounded-lg bg-blue-500 text-white text-lg font-semibold shadow hover:bg-blue-600 transition flex items-center justify-center gap-3">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
            </svg>
            Registrar nuevo camión
          </button>
        </div>
        <button phx-click="back_to_select" class="mt-2 text-yellow-600 underline">Volver</button>
      <% end %>

      <!-- Modal de Nuevo Check-in -->
      <%= if @show_new_checkin_modal do %>
        <div class="fixed inset-0 bg-black/70 flex items-center justify-center z-50" phx-click="hide_new_checkin_modal" phx-window-keydown="hide_new_checkin_modal" phx-key="escape">
          <div class="bg-white dark:bg-[#23272f] rounded-2xl shadow-2xl w-full max-w-md flex flex-col border border-gray-200 dark:border-[#2d323c] relative" phx-click="ignore">
            <div class="flex items-center gap-3 p-5 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-blue-100/60 via-white/80 to-purple-100/60 dark:from-blue-900/20 dark:via-[#23272f] dark:to-purple-900/20 rounded-t-2xl">
              <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-500/90 text-white shadow-lg">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                </svg>
              </span>
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">Nuevo Check-in</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400">Selecciona el tipo de registro</p>
              </div>
              <button type="button" phx-click="hide_new_checkin_modal" class="ml-auto text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
            </div>
            
            <div class="p-6 space-y-4">
              <div class="grid grid-cols-1 gap-4">
                <button phx-click="show_new_truck_form" class="w-full py-6 rounded-lg bg-blue-500 text-white text-lg font-semibold shadow hover:bg-blue-600 transition flex items-center justify-center gap-3">
                  <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
                  </svg>
                  Camión nuevo
                </button>
                <button phx-click="new_checkin_pieza" class="w-full py-6 rounded-lg bg-purple-500 text-white text-lg font-semibold shadow hover:bg-purple-600 transition flex items-center justify-center gap-3">
                  <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
                  </svg>
                  Pieza o artículo
                </button>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Modal de Selección de Camiones Existentes -->
      <%= if @show_existing_trucks_modal do %>
        <div class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4" phx-click="hide_existing_trucks_modal" phx-window-keydown="hide_existing_trucks_modal" phx-key="escape">
          <div class="bg-white dark:bg-[#23272f] rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] flex flex-col border border-gray-200 dark:border-[#2d323c] relative overflow-y-auto" phx-click="ignore">
            <div class="flex items-center gap-3 p-5 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-green-100/60 via-white/80 to-blue-100/60 dark:from-green-900/20 dark:via-[#23272f] dark:to-blue-900/20 rounded-t-2xl">
              <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-green-500/90 text-white shadow-lg">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
              </span>
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">Seleccionar Camión Existente</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400">Busca y selecciona el camión para el check-in</p>
              </div>
              <button type="button" phx-click="hide_existing_trucks_modal" class="ml-auto text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
            </div>
            
            <div class="p-6">
              <!-- Barra de búsqueda -->
              <div class="mb-6">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Buscar camión por marca, modelo o placa</label>
                <input type="text" 
                       phx-keyup="filter_trucks" 
                       phx-debounce="300"
                       placeholder="Escribe para buscar..."
                       class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white text-lg">
              </div>

              <!-- Lista de camiones -->
              <div class="max-h-96 overflow-y-auto space-y-3">
                <%= if @filtered_trucks && length(@filtered_trucks) > 0 do %>
                  <%= for truck <- @filtered_trucks do %>
                    <button phx-click="select_truck_for_production" phx-value-truck-id={truck.id} 
                            class="w-full p-4 border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-left">
                      <div class="flex items-center justify-between">
                        <div>
                          <h4 class="font-semibold text-gray-900 dark:text-gray-100">
                            <%= truck.brand %> <%= truck.model %>
                          </h4>
                          <p class="text-sm text-gray-600 dark:text-gray-400">
                            Placa: <%= truck.license_plate %> | Año: <%= truck.year %>
                          </p>
                          <%= if truck.kilometraje && truck.kilometraje > 0 do %>
                            <p class="text-xs text-gray-500 dark:text-gray-500">
                              Kilometraje: <%= truck.kilometraje %> km
                            </p>
                          <% end %>
                        </div>
                        <svg class="w-5 h-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                        </svg>
                      </div>
                    </button>
                  <% end %>
                <% else %>
                  <div class="text-center py-8 text-gray-500 dark:text-gray-400">
                    <svg class="w-12 h-12 mx-auto mb-4 text-gray-300 dark:text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"></path>
                    </svg>
                    <p class="text-lg font-medium">No se encontraron camiones</p>
                    <p class="text-sm">Intenta con otros términos de búsqueda</p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Modal de Formulario de Nuevo Camión -->
      <%= if @show_new_truck_form do %>
        <div class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4" phx-click="hide_new_truck_form" phx-window-keydown="hide_new_truck_form" phx-key="escape">
          <div class="bg-white dark:bg-[#23272f] rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] flex flex-col border border-gray-200 dark:border-[#2d323c] relative overflow-y-auto" phx-click="ignore">
            <div class="flex items-center gap-3 p-5 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-blue-100/60 via-white/80 to-green-100/60 dark:from-blue-900/20 dark:via-[#23272f] dark:to-green-900/20 rounded-t-2xl">
              <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-500/90 text-white shadow-lg">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
                </svg>
              </span>
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">Registrar Nuevo Camión</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400">Completa la información del camión</p>
              </div>
              <button type="button" phx-click="hide_new_truck_form" class="ml-auto text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
            </div>
            
            <form phx-submit="save_new_truck" class="p-6 space-y-4">
              <div class="relative">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Marca *</label>
                <input type="text" name="truck[brand]" id="wizard-brand-input" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: Mercedes-Benz, Volvo, Scania" phx-keyup="filter_brands" phx-debounce="300" autocomplete="off">
                <div id="wizard-brand-suggestions" class="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden">
                </div>
              </div>
              
              <div class="relative">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Modelo *</label>
                <input type="text" name="truck[model]" id="wizard-model-input" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: Actros, FH16, R500" phx-keyup="filter_models" phx-debounce="300" autocomplete="off">
                <div id="wizard-model-suggestions" class="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden">
                </div>
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Placa *</label>
                <input type="text" name="truck[license_plate]" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: ABC-123">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Número de Chasis/VIN *</label>
                <input type="text" name="truck[chassis_number]" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ingrese el número de chasis o VIN">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Año</label>
                <input type="number" name="truck[year]" min="1900" max="2030"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: 2020">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Kilometraje</label>
                <input type="number" name="truck[kilometraje]" min="0" step="1"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: 150000">
              </div>
              
              <div class="relative">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Propietario</label>
                <input type="text" name="truck[owner]" id="wizard-owner-input"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: Empresa ABC" phx-keyup="filter_owners" phx-debounce="300" autocomplete="off">
                <div id="wizard-owner-suggestions" class="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden">
                </div>
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Ficha</label>
                <input type="text" name="truck[ficha]"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Número de ficha">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Notas Generales</label>
                <textarea name="truck[general_notes]" rows="3"
                          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                          placeholder="Información adicional sobre el camión..."></textarea>
              </div>
              
              <div class="flex justify-end space-x-3 pt-4">
                <button type="button" phx-click="hide_new_truck_form" 
                        class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                  Cancelar
                </button>
                <button type="submit" 
                        class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700">
                  Registrar Camión
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

      <!-- Modal de Formulario de Nuevo Camión -->
      <%= if @show_new_truck_form do %>
        <div class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4" phx-click="hide_new_truck_form" phx-window-keydown="hide_new_truck_form" phx-key="escape">
          <div class="bg-white dark:bg-[#23272f] rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] flex flex-col border border-gray-200 dark:border-[#2d323c] relative overflow-y-auto" phx-click="ignore">
            <div class="flex items-center gap-3 p-5 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-purple-100/60 via-white/80 to-blue-100/60 dark:from-purple-900/20 dark:via-[#23272f] dark:to-blue-900/20 rounded-t-2xl">
              <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-purple-500/90 text-white shadow-lg">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
              </span>
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">Registrar Nuevo Camión</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400">Completa la información básica del camión</p>
              </div>
              <button type="button" phx-click="hide_new_truck_form" class="ml-auto text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
            </div>
            
            <form phx-submit="save_new_truck" class="p-6 space-y-4">
              <div class="relative">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Marca *</label>
                <input type="text" name="truck[brand]" id="wizard-quotation-brand-input" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: Mercedes-Benz, Volvo, Scania" phx-keyup="filter_brands" phx-debounce="300" autocomplete="off">
                <div id="wizard-quotation-brand-suggestions" class="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden">
                </div>
              </div>
              
              <div class="relative">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Modelo *</label>
                <input type="text" name="truck[model]" id="wizard-quotation-model-input" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: Actros, FH16, R500" phx-keyup="filter_models" phx-debounce="300" autocomplete="off">
                <div id="wizard-quotation-model-suggestions" class="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden">
                </div>
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Placa *</label>
                <input type="text" name="truck[license_plate]" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: ABC-123">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Número de Chasis/VIN *</label>
                <input type="text" name="truck[chassis_number]" required
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ingrese el número de chasis o VIN">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Año</label>
                <input type="number" name="truck[year]" min="1900" max="2030"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: 2020">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Kilometraje</label>
                <input type="number" name="truck[kilometraje]" min="0" step="1"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: 150000">
              </div>
              
              <div class="relative">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Propietario</label>
                <input type="text" name="truck[owner]" id="wizard-quotation-owner-input"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Ej: Empresa ABC" phx-keyup="filter_owners" phx-debounce="300" autocomplete="off">
                <div id="wizard-quotation-owner-suggestions" class="absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden">
                </div>
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Ficha</label>
                <input type="text" name="truck[ficha]"
                       class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500 dark:bg-gray-700 dark:text-white"
                       placeholder="Número de ficha">
              </div>
              
              <div class="flex justify-end space-x-3 pt-4">
                <button type="button" phx-click="hide_new_truck_form" 
                        class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                  Cancelar
                </button>
                <button type="submit" 
                        class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-700">
                  Registrar Camión
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

      <%= if @step == :capture_damages do %>
        <h2 class="text-xl font-bold mb-4 text-center">Daños y observaciones</h2>
        <form phx-submit="save_damages">
          <textarea name="damages" placeholder="Describe daños u observaciones" class="w-full p-4 rounded border mb-4 text-lg text-gray-900 dark:text-white bg-white dark:bg-gray-700"></textarea>
          <button type="submit" class="w-full py-3 rounded bg-green-600 text-white font-semibold">Crear ticket y continuar a fotos</button>
        </form>
      <% end %>
      <%= if @step == :success and @created_ticket do %>
        <div class="bg-green-100 text-green-800 rounded p-4 text-center mt-8">
          <h2 class="text-2xl font-bold mb-2">¡Ticket creado exitosamente!</h2>
          <p class="text-lg">Número de ticket: <b><%= @created_ticket.id %></b></p>
        </div>
        
        <!-- Modal de subida de fotos y firma integrado -->
        <%= if @show_photo_modal do %>
          <div class="fixed inset-0 bg-black/70 flex items-center justify-center z-50" phx-click="close_photo_modal" phx-window-keydown="close_photo_modal" phx-key="escape">
            <div class="bg-white dark:bg-[#23272f] rounded-2xl shadow-2xl w-full max-w-2xl flex flex-col border border-gray-200 dark:border-[#2d323c] relative overflow-y-auto" phx-click="ignore" id="photo-upload-modal" phx-hook="FileUploadPreview">
              <div class="flex items-center gap-3 p-5 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-orange-100/60 via-white/80 to-blue-100/60 dark:from-orange-900/20 dark:via-[#23272f] dark:to-blue-900/20 rounded-t-2xl">
                <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-orange-500/90 text-white shadow-lg">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 13h3l6 6M3 21l6-6m0 0V9a3 3 0 013-3h3m-6 6l-6 6"/></svg>
                </span>
                <div>
                  <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">
                    <%= if @created_ticket && @created_ticket.evaluation_type do %>
                      Completar evaluación #<%= @created_ticket.id %>
                    <% else %>
                      Completar ticket #<%= @created_ticket.id %>
                    <% end %>
                  </h3>
                  <p class="text-xs text-gray-500 dark:text-gray-400">
                    <%= if @created_ticket && @created_ticket.evaluation_type do %>
                      Sube fotos de la evaluación
                    <% else %>
                      Sube fotos y firma digital
                    <% end %>
                  </p>
                </div>
                <button type="button" phx-click="close_photo_modal" class="ml-auto text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
              </div>
              
              <!-- Tabs -->
              <%= if @created_ticket && @created_ticket.evaluation_type do %>
                <!-- Solo fotos para evaluaciones -->
                <div class="px-6 py-3 text-sm font-medium text-purple-600 border-b-2 border-purple-600 bg-purple-50 dark:bg-purple-900/20">
                  📸 Fotos de Evaluación
                </div>
              <% else %>
                <!-- Tabs completos para otros tickets -->
              <div class="flex border-b border-gray-200 dark:border-gray-700" id="tabs-container" phx-hook="TabManager" phx-click="ignore">
                <button type="button" class="tab-button active px-6 py-3 text-sm font-medium text-blue-600 border-b-2 border-blue-600" data-tab="photos" phx-click="ignore">
                  📸 Fotos
                </button>
                <button type="button" class="tab-button px-6 py-3 text-sm font-medium text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300" data-tab="signature" phx-click="ignore">
                  ✍️ Firma Digital
                </button>
              </div>
              <% end %>
              
              <form phx-submit={if @created_ticket && @created_ticket.evaluation_type, do: "save_evaluation_photos", else: "save_photos_and_signature"} class="flex-1 flex flex-col min-h-0 px-6 py-4 gap-4">
                <!-- Photos Tab -->
                <div id="photos-tab" class="tab-content active">
                  <div class="space-y-6">
                    <div class="flex flex-col items-center gap-4 bg-gray-50 dark:bg-gray-800 rounded p-4">
                      <label class="w-full font-semibold mb-2">
                        <%= if @created_ticket && @created_ticket.evaluation_type do %>
                          Fotos de la evaluación (puedes subir varias)
                        <% else %>
                          Fotos del camión (puedes subir varias)
                        <% end %>
                      </label>
                      <label class="relative cursor-pointer bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium transition-colors">
                        <span>Subir fotos</span>
                        <.live_file_input upload={@uploads.damage_photos} class="hidden" accept="image/*" capture="environment" phx-change="photos_selected" />
                      </label>
                      <p class="text-xs text-gray-500 dark:text-gray-400 mt-2">PNG, JPG, GIF hasta 10MB (máximo 10 fotos)</p>
                      <div class="upload-preview-container mt-2 w-full">
                        <%= if Enum.empty?(@uploads.damage_photos.entries) do %>
                          <div class="text-xs text-gray-400 mt-2">No hay archivos seleccionados.</div>
                        <% else %>
                          <div class="text-xs text-gray-700 dark:text-gray-300 mt-2 font-semibold">Archivos listos para subir:</div>
                          <%= for entry <- @uploads.damage_photos.entries do %>
                            <div class="mt-2 flex items-center gap-2">
                              <img phx-upload-preview={entry.ref} class="w-16 h-16 object-cover rounded border border-gray-300 dark:border-gray-700" alt="Preview" />
                              <div class="flex-1">
                                <span class="text-xs text-gray-700 dark:text-gray-300"><%= entry.client_name %></span>
                                <%= if entry.progress < 100 do %>
                                  <div class="w-full bg-gray-200 rounded-full h-1 mt-1">
                                    <div class="bg-blue-600 h-1 rounded-full" style={"width: #{entry.progress}%"}></div>
                                  </div>
                                  <span class="text-xs text-gray-500">Subiendo... <%= entry.progress %>%</span>
                                <% else %>
                                  <span class="text-xs text-green-600">✓ Completado</span>
                                <% end %>
                              </div>
                              <button type="button" phx-click="cancel_photo" phx-value-key="damage_photos" phx-value-ref={entry.ref} class="text-red-500 text-xs ml-2">Eliminar</button>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Signature Tab - Solo para tickets que no son evaluaciones -->
                <%= if !@created_ticket || !@created_ticket.evaluation_type do %>
                <div id="signature-tab" class="tab-content hidden">
                  <div class="space-y-6">
                    <div class="flex flex-col items-center gap-4 bg-gray-50 dark:bg-gray-800 rounded p-4">
                      <label class="w-full font-semibold mb-2">Firma Digital</label>
                      <p class="text-xs text-gray-500 dark:text-gray-400 mb-4">Usa el mouse o tu dedo para firmar</p>
                      
                      <div class="signature-container w-full max-w-md" id="signature-container" phx-hook="DigitalSignature" phx-click="ignore">
                        <canvas class="signature-canvas w-full h-64 border-2 border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 cursor-crosshair"></canvas>
                        <input type="hidden" class="signature-data" name="signature" value={@signature_data || ""} />
                        
                        <div class="flex justify-between items-center mt-4">
                          <button type="button" class="clear-signature px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-md text-sm font-medium transition-colors" phx-click="ignore">
                            🗑️ Limpiar Firma
                          </button>
                          <div class="text-xs text-gray-500 dark:text-gray-400">
                            Firma requerida para completar el ticket
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <% end %>
                
                <div class="mt-8 flex justify-end gap-2">
                  <button type="button" phx-click="close_photo_modal" class="px-4 py-2 rounded bg-gray-300 text-gray-800 font-semibold">Cerrar</button>
                  <%= if @created_ticket && @created_ticket.evaluation_type do %>
                    <button type="button" phx-click="skip_evaluation_photos" class="px-4 py-2 rounded bg-gray-500 text-white font-semibold">Saltar Fotos</button>
                    <button type="submit" class="px-4 py-2 rounded bg-purple-600 text-white font-semibold">Guardar Fotos</button>
                  <% else %>
                  <button type="submit" class="px-4 py-2 rounded bg-blue-600 text-white font-semibold">Guardar Fotos y Firma</button>
                  <% end %>
                </div>
              </form>
            </div>
          </div>
        <% end %>
      <% end %>

      <%= if @step == :article_ticket_details and @ticket_form do %>
        <h2 class="text-xl font-bold mb-4 text-center">Check-in de Artículo/Pieza</h2>
        <form phx-submit="save_article_ticket_details" class="space-y-4">
          <!-- Información básica del ticket -->
          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">Información del Ticket</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Título del Ticket</label>
                <input name="ticket[title]" value={@ticket_form["title"]} required 
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Fecha de Recepción</label>
                <input name="ticket[entry_date]" type="datetime-local" 
                       value={@ticket_form["entry_date"] && String.slice(@ticket_form["entry_date"], 0, 16)} required 
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
            </div>
          </div>

          <!-- Información específica del artículo -->
          <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-purple-900 dark:text-purple-100">Información del Artículo</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Tipo de Artículo *</label>
                <select name="ticket[article_type]" required 
                        class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700">
                  <option value="">Seleccionar tipo</option>
                  <option value="motor" selected={@ticket_form["article_type"] == "motor"}>Motor</option>
                  <option value="transmision" selected={@ticket_form["article_type"] == "transmision"}>Transmisión</option>
                  <option value="frenos" selected={@ticket_form["article_type"] == "frenos"}>Sistema de Frenos</option>
                  <option value="neumaticos" selected={@ticket_form["article_type"] == "neumaticos"}>Neumáticos</option>
                  <option value="suspension" selected={@ticket_form["article_type"] == "suspension"}>Suspensión</option>
                  <option value="electrica" selected={@ticket_form["article_type"] == "electrica"}>Sistema Eléctrico</option>
                  <option value="refrigeracion" selected={@ticket_form["article_type"] == "refrigeracion"}>Sistema de Refrigeración</option>
                  <option value="combustible" selected={@ticket_form["article_type"] == "combustible"}>Sistema de Combustible</option>
                  <option value="otros" selected={@ticket_form["article_type"] == "otros"}>Otros</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Marca del Artículo</label>
                <input name="ticket[article_brand]" value={@ticket_form["article_brand"]} 
                       placeholder="Ej: Cummins, Eaton, Bendix"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Modelo del Artículo</label>
                <input name="ticket[article_model]" value={@ticket_form["article_model"]} 
                       placeholder="Ej: ISX15, RTLO-18918B"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Número de Serie</label>
                <input name="ticket[serial_number]" value={@ticket_form["serial_number"]} 
                       placeholder="Número de serie o part number"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Estado del Artículo</label>
                <select name="ticket[article_condition]" 
                        class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700">
                  <option value="new" selected={@ticket_form["article_condition"] == "new"}>Nuevo</option>
                  <option value="used" selected={@ticket_form["article_condition"] == "used"}>Usado</option>
                  <option value="reconditioned" selected={@ticket_form["article_condition"] == "reconditioned"}>Reacondicionado</option>
                  <option value="refurbished" selected={@ticket_form["article_condition"] == "refurbished"}>Refurbished</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Ubicación</label>
                <input name="ticket[location]" value={@ticket_form["location"]} 
                       placeholder="Ej: Almacén A, Estante 3, Bodega Norte"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
            </div>
          </div>

          <!-- Información del proveedor -->
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-blue-900 dark:text-blue-100">Información del Proveedor</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Proveedor</label>
                <input name="ticket[supplier]" value={@ticket_form["supplier"]} 
                       placeholder="Nombre del proveedor"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Número de Factura/Orden</label>
                <input name="ticket[invoice_number]" value={@ticket_form["invoice_number"]} 
                       placeholder="Número de factura o orden de compra"
                       class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700" />
              </div>
            </div>
          </div>

          <!-- Condiciones especiales -->
          <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4 mb-4">
            <h3 class="text-lg font-semibold mb-3 text-yellow-900 dark:text-yellow-100">Condiciones Especiales</h3>
            <div class="space-y-4">
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Condiciones de Almacenamiento</label>
                <textarea name="ticket[special_conditions]" rows="3"
                          placeholder="Requisitos especiales de almacenamiento, temperatura, humedad, etc."
                          class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @ticket_form["special_conditions"] %></textarea>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Observaciones Generales</label>
                <textarea name="ticket[exit_notes]" rows="3"
                          placeholder="Observaciones adicionales sobre el artículo"
                          class="w-full p-2 rounded border text-gray-900 dark:text-white bg-white dark:bg-gray-700"><%= @ticket_form["exit_notes"] %></textarea>
              </div>
            </div>
          </div>

          <!-- Color del evento -->
          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
            <h3 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">Configuración del Evento</h3>
            <div>
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Color del Evento</label>
              <input name="ticket[color]" type="color" value={@ticket_form["color"] || "#8b5cf6"} 
                     class="w-16 h-8 p-0 border-0 bg-transparent cursor-pointer align-middle rounded-full shadow" />
            </div>
          </div>

          <button type="submit" class="w-full py-3 rounded bg-purple-600 text-white font-semibold">Continuar a Fotos y Firma</button>
        </form>
      <% end %>

      <!-- Modal de Búsqueda por Placa (después de registrar camión) -->
      <%= if @show_search_modal and @search_plate do %>
        <div class="fixed inset-0 bg-black/70 flex items-center justify-center z-50" phx-click="hide_search_modal" phx-window-keydown="hide_search_modal" phx-key="escape">
          <div class="bg-white dark:bg-[#23272f] rounded-2xl shadow-2xl w-full max-w-md flex flex-col border border-gray-200 dark:border-[#2d323c] relative" phx-click="ignore">
            <div class="flex items-center gap-3 p-5 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-green-100/60 via-white/80 to-blue-100/60 dark:from-green-900/20 dark:via-[#23272f] dark:to-blue-900/20 rounded-t-2xl">
              <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-green-500/90 text-white shadow-lg">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </span>
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-tight">¡Camión Registrado!</h3>
                <p class="text-xs text-gray-500 dark:text-gray-400">Ahora puedes crear el ticket de check-in</p>
              </div>
              <button type="button" phx-click="hide_search_modal" class="ml-auto text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
            </div>
            
            <div class="p-6 space-y-4">
              <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
                <div class="flex items-center gap-3">
                  <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
                  </svg>
                  <div>
                    <p class="text-sm font-medium text-green-800 dark:text-green-200">Placa: <span class="font-bold"><%= @search_plate %></span></p>
                    <p class="text-xs text-green-600 dark:text-green-400">Camión registrado exitosamente</p>
                  </div>
                </div>
              </div>
              
              <div class="space-y-3">
                <p class="text-sm text-gray-600 dark:text-gray-400">¿Qué deseas hacer ahora?</p>
                
                <button phx-click="continue_to_checkin" class="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors flex items-center justify-center gap-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  Crear Ticket de Check-in
                </button>
                
                <button phx-click="search_another_plate" class="w-full py-3 px-4 bg-gray-500 hover:bg-gray-600 text-white font-semibold rounded-lg transition-colors flex items-center justify-center gap-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                  </svg>
                  Buscar Otra Placa
                </button>
                
                <button phx-click="back_to_wizard" class="w-full py-3 px-4 bg-gray-300 hover:bg-gray-400 text-gray-800 font-semibold rounded-lg transition-colors">
                  Volver al Wizard
                </button>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Modal de Orden de Producción -->
      <%= if @show_production_order_modal do %>
        <.live_component
          module={EvaaCrmWebGaepell.ProductionOrderModal}
          id="production_order_modal"
          truck_id={@selected_truck_id}
          business_id={@current_user.business_id}
          current_user={@current_user}
          return_to={~p"/maintenance"}
        />
      <% end %>
    </div>

<script>
  // Autocompletado para marcas, modelos y propietarios en ticket wizard
  window.addEventListener("phx:update", (e) => {
    setupWizardAutocomplete();
  });

  document.addEventListener("DOMContentLoaded", (e) => {
    setupWizardAutocomplete();
  });

  function setupWizardAutocomplete() {
    // Primer modal de creación de camiones
    const brandInput = document.getElementById('wizard-brand-input');
    const modelInput = document.getElementById('wizard-model-input');
    const ownerInput = document.getElementById('wizard-owner-input');
    const brandSuggestions = document.getElementById('wizard-brand-suggestions');
    const modelSuggestions = document.getElementById('wizard-model-suggestions');
    const ownerSuggestions = document.getElementById('wizard-owner-suggestions');

    // Segundo modal de creación de camiones para cotización
    const quotationBrandInput = document.getElementById('wizard-quotation-brand-input');
    const quotationModelInput = document.getElementById('wizard-quotation-model-input');
    const quotationOwnerInput = document.getElementById('wizard-quotation-owner-input');
    const quotationBrandSuggestions = document.getElementById('wizard-quotation-brand-suggestions');
    const quotationModelSuggestions = document.getElementById('wizard-quotation-model-suggestions');
    const quotationOwnerSuggestions = document.getElementById('wizard-quotation-owner-suggestions');

    // Configurar primer modal
    if (brandInput && brandSuggestions) {
      setupInputAutocomplete(brandInput, brandSuggestions);
    }
    if (modelInput && modelSuggestions) {
      setupInputAutocomplete(modelInput, modelSuggestions);
    }
    if (ownerInput && ownerSuggestions) {
      setupInputAutocomplete(ownerInput, ownerSuggestions);
    }

    // Configurar segundo modal
    if (quotationBrandInput && quotationBrandSuggestions) {
      setupInputAutocomplete(quotationBrandInput, quotationBrandSuggestions);
    }
    if (quotationModelInput && quotationModelSuggestions) {
      setupInputAutocomplete(quotationModelInput, quotationModelSuggestions);
    }
    if (quotationOwnerInput && quotationOwnerSuggestions) {
      setupInputAutocomplete(quotationOwnerInput, quotationOwnerSuggestions);
    }
  }

  function setupInputAutocomplete(input, suggestionsDiv) {
    // Evento para ocultar sugerencias al perder focus
    input.addEventListener('blur', function(e) {
      // Pequeño delay para permitir que se ejecute el click en las sugerencias
      setTimeout(() => {
        suggestionsDiv.classList.add('hidden');
      }, 200);
    });
  }

  // Eventos para actualizar sugerencias desde el servidor
  window.addEventListener("phx:update_brand_suggestions", (e) => {
    const brandInput = document.getElementById('wizard-brand-input');
    const brandSuggestions = document.getElementById('wizard-brand-suggestions');
    const quotationBrandInput = document.getElementById('wizard-quotation-brand-input');
    const quotationBrandSuggestions = document.getElementById('wizard-quotation-brand-suggestions');
    
    if (brandInput && brandSuggestions) {
      updateSuggestions(brandSuggestions, brandInput, e.detail.suggestions);
    }
    if (quotationBrandInput && quotationBrandSuggestions) {
      updateSuggestions(quotationBrandSuggestions, quotationBrandInput, e.detail.suggestions);
    }
  });

  window.addEventListener("phx:update_model_suggestions", (e) => {
    const modelInput = document.getElementById('wizard-model-input');
    const modelSuggestions = document.getElementById('wizard-model-suggestions');
    const quotationModelInput = document.getElementById('wizard-quotation-model-input');
    const quotationModelSuggestions = document.getElementById('wizard-quotation-model-suggestions');
    
    if (modelInput && modelSuggestions) {
      updateSuggestions(modelSuggestions, modelInput, e.detail.suggestions);
    }
    if (quotationModelInput && quotationModelSuggestions) {
      updateSuggestions(quotationModelSuggestions, quotationModelInput, e.detail.suggestions);
    }
  });

  window.addEventListener("phx:update_owner_suggestions", (e) => {
    const ownerInput = document.getElementById('wizard-owner-input');
    const ownerSuggestions = document.getElementById('wizard-owner-suggestions');
    const quotationOwnerInput = document.getElementById('wizard-quotation-owner-input');
    const quotationOwnerSuggestions = document.getElementById('wizard-quotation-owner-suggestions');
    
    if (ownerInput && ownerSuggestions) {
      updateSuggestions(ownerSuggestions, ownerInput, e.detail.suggestions);
    }
    if (quotationOwnerInput && quotationOwnerSuggestions) {
      updateSuggestions(quotationOwnerSuggestions, quotationOwnerInput, e.detail.suggestions);
    }
  });

  function updateSuggestions(suggestionsDiv, input, suggestions) {
    if (!suggestionsDiv || !input) return;

    if (suggestions.length === 0) {
      suggestionsDiv.classList.add('hidden');
      return;
    }

    // Crear lista de sugerencias
    const suggestionsList = suggestions.map(suggestion => 
      `<div class="suggestion-item px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 cursor-pointer text-gray-700 dark:text-gray-300" data-value="${suggestion}">${suggestion}</div>`
    ).join('');

    suggestionsDiv.innerHTML = suggestionsList;
    suggestionsDiv.classList.remove('hidden');

    // Agregar eventos de click a las sugerencias
    const suggestionItems = suggestionsDiv.querySelectorAll('.suggestion-item');
    suggestionItems.forEach(item => {
      item.addEventListener('click', function() {
        input.value = this.getAttribute('data-value');
        suggestionsDiv.classList.add('hidden');
        input.focus();
      });
    });
  }

  // Función para manejar el toggle del campo de garantía
  function toggleWarrantyField(evaluationType) {
    console.log('[DEBUG] toggleWarrantyField called with:', evaluationType);
    const warrantyField = document.getElementById('warranty-field');
    console.log('[DEBUG] warrantyField found:', warrantyField);
    if (warrantyField) {
      if (evaluationType === 'warranty') {
        warrantyField.style.display = 'block';
        console.log('[DEBUG] warranty field shown');
      } else {
        warrantyField.style.display = 'none';
        console.log('[DEBUG] warranty field hidden');
      }
    }
  }

  // Inicializar el estado del campo de garantía al cargar la página
  document.addEventListener("DOMContentLoaded", function() {
    const evaluationTypeSelect = document.querySelector('select[name="evaluation[evaluation_type]"]');
    if (evaluationTypeSelect) {
      toggleWarrantyField(evaluationTypeSelect.value);
    }
  });

  // También inicializar cuando Phoenix actualice el DOM
  window.addEventListener("phx:update", function() {
    const evaluationTypeSelect = document.querySelector('select[name="evaluation[evaluation_type]"]');
    if (evaluationTypeSelect) {
      toggleWarrantyField(evaluationTypeSelect.value);
    }
  });
</script>
    """
  end

  @impl true
  def handle_info(:close_production_order_modal, socket) do
    {:noreply, assign(socket, :show_production_order_modal, false)}
  end

  @impl true
  def handle_info({:production_order_created, ticket}, socket) do
    {:noreply, 
     socket
     |> assign(:show_production_order_modal, false)
     |> put_flash(:success, "Orden de producción creada exitosamente")
     |> push_navigate(to: ~p"/maintenance")}
  end

  # Handlers para el modal de camiones existentes
  @impl true
  def handle_event("show_existing_trucks_modal", _params, socket) do
    # Cargar todos los camiones inicialmente
    import Ecto.Query
    trucks = from t in EvaaCrmGaepell.Truck,
            where: t.business_id == ^socket.assigns.current_user.business_id,
            order_by: [asc: t.brand, asc: t.model]
    trucks = EvaaCrmGaepell.Repo.all(trucks)
    
    {:noreply, 
     socket
     |> assign(:show_existing_trucks_modal, true)
     |> assign(:filtered_trucks, trucks)}
  end

  @impl true
  def handle_event("hide_existing_trucks_modal", _params, socket) do
    {:noreply, assign(socket, :show_existing_trucks_modal, false)}
  end

  @impl true
  def handle_event("select_truck_for_production", %{"truck-id" => truck_id}, socket) do
    truck = EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.Truck, truck_id)
    
    case socket.assigns.entry_type do
      :production ->
        {:noreply, 
         socket
         |> assign(:show_existing_trucks_modal, false)
         |> assign(:selected_truck_id, truck_id)
         |> assign(:found_truck, truck)
         |> assign(:show_production_order_modal, true)}
      
      :maintenance ->
        # Crear ticket_form por defecto para mantenimiento
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        default_ticket = %{
          title: "Check-in de camión #{truck.license_plate}",
          entry_date: DateTime.to_iso8601(now),
          mileage: truck.kilometraje || 0,
          fuel_level: "full",
          status: "check_in",
          color: "#2563eb",
          exit_notes: "",
          visible_damage: "",
          company_name: truck.owner || "No especificado"
        }
        
        {:noreply, 
         socket
         |> assign(:show_existing_trucks_modal, false)
         |> assign(:found_truck, truck)
         |> assign(:ticket_form, default_ticket)
         |> assign(:step, :ticket_details)}
      
      :quotation ->
        IO.puts("[DEBUG] Inicializando upload para evaluación en wizard")
        IO.puts("[DEBUG] entry_type: #{inspect(socket.assigns.entry_type)}")
        IO.puts("[DEBUG] truck_id: #{truck_id}")
        IO.puts("[DEBUG] truck: #{inspect(truck)}")
        
        socket = socket
         |> assign(:show_existing_trucks_modal, false)
         |> assign(:found_truck, truck)
         |> assign(:step, :quotation_details)
         |> assign(:evaluation_type, "collision") # Inicializar con valor por defecto
         |> assign(:evaluation_form_data, %{}) # Inicializar datos del formulario
         |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
        
        IO.puts("[DEBUG] Paso asignado: #{inspect(socket.assigns.step)}")
        IO.puts("[DEBUG] found_truck asignado: #{inspect(socket.assigns.found_truck)}")
        IO.puts("[DEBUG] found_truck.id: #{inspect(socket.assigns.found_truck.id)}")
        IO.puts("[DEBUG] found_truck.license_plate: #{inspect(socket.assigns.found_truck.license_plate)}")
        IO.inspect(socket.assigns.uploads.evaluation_photos, label: "[DEBUG] upload configurado en wizard")
        {:noreply, socket}
    end
  end

  # Funciones para autocompletado de marcas, modelos y propietarios
  defp get_existing_brands do
    import Ecto.Query
    EvaaCrmGaepell.Truck
    |> select([t], t.brand)
    |> where([t], not is_nil(t.brand) and t.brand != "")
    |> distinct([t], t.brand)
    |> order_by([t], t.brand)
    |> EvaaCrmGaepell.Repo.all()
  end

  defp get_existing_models do
    import Ecto.Query
    EvaaCrmGaepell.Truck
    |> select([t], t.model)
    |> where([t], not is_nil(t.model) and t.model != "")
    |> distinct([t], t.model)
    |> order_by([t], t.model)
    |> EvaaCrmGaepell.Repo.all()
  end

  defp get_existing_owners do
    import Ecto.Query
    EvaaCrmGaepell.Truck
    |> select([t], t.owner)
    |> where([t], not is_nil(t.owner) and t.owner != "")
    |> distinct([t], t.owner)
    |> order_by([t], t.owner)
    |> EvaaCrmGaepell.Repo.all()
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

  defp get_evaluation_type_label(type) do
    case type do
      "garantia" -> "Garantía"
      "colision" -> "Colisión"
      "desgaste" -> "Desgaste"
      "otro" -> "Otro"
      _ -> "Desconocido"
    end
  end

end 