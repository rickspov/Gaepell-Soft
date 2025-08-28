defmodule EvaaCrmWebGaepell.TruckProfileLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Truck, MaintenanceTicket, TruckPhoto, TruckNote, TruckDocument, Repo, Evaluation, ProductionOrder}
  import Ecto.Query
  import Phoenix.HTML
  
  @uploads_dir Path.expand("priv/static/uploads")

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    truck = Repo.get(Truck, id)
    if truck do
      {:ok,
        socket
        |> assign(:current_user, current_user)
        |> assign(:truck, truck)
        |> assign(:show_edit_form, false)
        |> assign(:editing_truck, nil)
        |> assign(:show_photo_gallery, false)
        |> assign(:selected_ticket_for_photo, nil)
        |> assign(:show_fullscreen_photo, false)
        |> assign(:fullscreen_photo, nil)
        |> assign(:show_fullscreen_pdf, false)
        |> assign(:fullscreen_pdf, nil)
        |> assign(:show_edit_description_modal, false)
        |> assign(:editing_photo_id, nil)
        |> assign(:editing_photo_description, "")
        |> assign(:show_add_note_modal, false)
        |> assign(:note_changeset, nil)
        |> assign(:selected_ticket_for_note, nil)
        |> assign(:show_edit_note_modal, false)
        |> assign(:editing_note_id, nil)
        |> assign(:editing_note_type, "general")
        |> assign(:editing_note_content, "")
        |> assign(:editing_note_ticket_id, nil)
        |> assign(:editing_note_changeset, nil)
        |> assign(:show_maintenance_photo_fullscreen, false)
        |> assign(:maintenance_fullscreen_photo, nil)
        |> assign(:show_maintenance_photo_comment_modal, false)
        |> assign(:maintenance_comment_ticket_id, nil)
        |> assign(:maintenance_comment_photo_url, nil)
        |> assign(:show_quotation_preview_modal, false)
        |> assign(:selected_quotation_data, nil)
        |> assign(:show_document_upload_modal, false)
        |> assign(:show_document_photo_upload_modal, false)
        |> assign(:selected_ticket_for_document, nil)
        |> assign(:expanded_tickets, %{})
        |> assign(:show_edit_document_description_modal, false)
        |> assign(:editing_document_id, nil)
        |> assign(:editing_document_description, "")
        |> assign(:editing_document_title, "")
        |> assign(:editing_document_ticket_id, nil)
        |> assign(:show_technical_info_modal, false)
        |> assign(:show_edit_box_type_modal, false)
        |> assign(:show_edit_tire_width_modal, false)
        |> assign(:show_edit_useful_length_modal, false)
        |> assign(:show_edit_chassis_width_modal, false)
        |> assign(:active_tab, "overview")
        |> allow_upload(:truck_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 5, max_file_size: 8_000_000, auto_upload: true)
        |> allow_upload(:document_files, accept: ~w(.pdf), max_entries: 1, max_file_size: 10_000_000, auto_upload: false)
        |> allow_upload(:document_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 5, max_file_size: 8_000_000, auto_upload: false)
        |> load_truck_tickets()
        |> load_truck_photos()
        |> load_truck_notes()
        |> load_truck_quotations()
        |> load_truck_documents()}
    else
      {:ok, socket |> put_flash(:error, "Camión no encontrado") |> push_navigate(to: "/trucks")}
    end
  end

  defp load_truck_tickets(socket) do
    # Cargar tickets de mantenimiento
    maintenance_tickets = Repo.all(from t in MaintenanceTicket, where: t.truck_id == ^socket.assigns.truck.id, order_by: [desc: t.entry_date])
    
    # Cargar evaluaciones
    evaluations = Repo.all(from e in EvaaCrmGaepell.Evaluation, where: e.truck_id == ^socket.assigns.truck.id, order_by: [desc: e.inserted_at])
    
    # Cargar órdenes de producción (filtrar por placa del camión)
    production_orders = Repo.all(from po in EvaaCrmGaepell.ProductionOrder, where: po.license_plate == ^socket.assigns.truck.license_plate, order_by: [desc: po.inserted_at])
    
    # Combinar todos los tickets y ordenarlos por fecha
    all_tickets = (maintenance_tickets ++ evaluations ++ production_orders)
    |> Enum.sort_by(&get_ticket_date/1, {:desc, Date})
    
    assign(socket, :tickets, maintenance_tickets)
    |> assign(:all_tickets, all_tickets)
  end

  # Función auxiliar para obtener la fecha de un ticket
  def get_ticket_date(%MaintenanceTicket{} = ticket), do: ticket.entry_date
  def get_ticket_date(%Evaluation{} = ticket), do: ticket.inserted_at
  def get_ticket_date(%ProductionOrder{} = ticket), do: ticket.inserted_at

  defp load_truck_photos(socket) do
    photos = Repo.all(
      from p in TruckPhoto,
      where: p.truck_id == ^socket.assigns.truck.id,
      order_by: [desc: p.uploaded_at],
      preload: [:user, :maintenance_ticket]
    )
    assign(socket, :truck_photos, photos)
  end

  defp load_truck_notes(socket) do
    notes = Repo.all(
      from n in TruckNote,
      where: n.truck_id == ^socket.assigns.truck.id,
      order_by: [desc: n.inserted_at],
      preload: [:user, :maintenance_ticket, :production_order]
    )
    assign(socket, :truck_notes, notes)
  end

  defp load_truck_quotations(socket) do
    quotations = Repo.all(
      from s in EvaaCrmGaepell.SymasoftImport,
      where: s.truck_id == ^socket.assigns.truck.id,
      order_by: [desc: s.inserted_at],
      preload: [:user, :maintenance_ticket, :production_order]
    )
    assign(socket, :truck_quotations, quotations)
  end

  # Helper functions for complex class attributes
  defp truck_status_classes(truck) do
    if truck.status == "active" do
      "bg-green-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
    else
      "bg-orange-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
    end
  end

  defp truck_status_label(truck) do
    if truck.status == "active", do: "Activo", else: "Mantenimiento"
  end

  # Helper functions for tab navigation classes
  defp tab_classes(active_tab, current_tab) do
    if active_tab == current_tab do
      "bg-white dark:bg-slate-700 shadow-md text-slate-900 dark:text-slate-100"
    else
      "text-slate-700 dark:text-slate-300"
    end
  end

  # Helper functions for ticket display
  def evaluation_type_label(%MaintenanceTicket{} = ticket) do
    case ticket.evaluation_type do
      "maintenance" -> "Mantenimiento"
      "warranty" -> "Garantía"
      "inspection" -> "Inspección"
      "repair" -> "Reparación"
      _ -> "General"
    end
  end
  
  def evaluation_type_label(%Evaluation{} = ticket) do
    case ticket.evaluation_type do
      "garantia" -> "Evaluación de Garantía"
      "colision" -> "Evaluación de Colisión"
      "desgaste" -> "Evaluación de Desgaste"
      "otro" -> "Evaluación General"
      _ -> "Evaluación"
    end
  end
  
  def evaluation_type_label(%ProductionOrder{} = _ticket) do
    "Orden de Producción"
  end

  def status_label(%MaintenanceTicket{} = ticket) do
    case ticket.status do
      "check_in" -> "Check-in"
      "in_progress" -> "En Progreso"
      "completed" -> "Completado"
      "cancelled" -> "Cancelado"
      _ -> "Pendiente"
    end
  end
  
  def status_label(%Evaluation{} = ticket) do
    case ticket.status do
      "pending" -> "Pendiente"
      "in_progress" -> "En Progreso"
      "completed" -> "Completado"
      "cancelled" -> "Cancelado"
      _ -> "Pendiente"
    end
  end
  
  def status_label(%ProductionOrder{} = ticket) do
    case ticket.status do
      "new_order" -> "Nueva Orden"
      "reception" -> "Recepción"
      "assembly" -> "Ensamblaje"
      "mounting" -> "Montaje"
      "final_check" -> "Final Check"
      "completed" -> "Completado"
      "cancelled" -> "Cancelado"
      _ -> "Pendiente"
    end
  end

  def status_classes(%MaintenanceTicket{} = ticket) do
    case ticket.status do
      "check_in" -> "bg-blue-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "in_progress" -> "bg-yellow-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "completed" -> "bg-green-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "cancelled" -> "bg-red-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      _ -> "bg-gray-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
    end
  end
  
  def status_classes(%Evaluation{} = ticket) do
    case ticket.status do
      "pending" -> "bg-gray-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "in_progress" -> "bg-yellow-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "completed" -> "bg-green-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "cancelled" -> "bg-red-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      _ -> "bg-gray-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
    end
  end
  
  def status_classes(%ProductionOrder{} = ticket) do
    case ticket.status do
      "new_order" -> "bg-blue-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "reception" -> "bg-purple-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "assembly" -> "bg-yellow-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "mounting" -> "bg-orange-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "final_check" -> "bg-indigo-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "completed" -> "bg-green-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      "cancelled" -> "bg-red-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
      _ -> "bg-gray-500 text-white border-0 shadow-lg px-3 py-1 rounded-full text-sm"
    end
  end

  def specialist_name(%MaintenanceTicket{} = ticket) do
    if ticket.specialist_id do
      "Especialista"
    else
      "Sin asignar"
    end
  end
  
  def specialist_name(%Evaluation{} = _ticket) do
    "Evaluador"
  end
  
  def specialist_name(%ProductionOrder{} = _ticket) do
    "Producción"
  end

  def total_cost(%MaintenanceTicket{} = ticket) do
    ticket.estimated_repair_cost
  end
  
  def total_cost(%Evaluation{} = ticket) do
    ticket.estimated_cost
  end
  
  def total_cost(%ProductionOrder{} = ticket) do
    ticket.total_cost
  end

  # Función para obtener el icono según el tipo de ticket
  def get_ticket_icon(%MaintenanceTicket{} = _ticket) do
    Phoenix.HTML.raw(~s(<svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
    </svg>))
  end
  
  def get_ticket_icon(%Evaluation{} = _ticket) do
    Phoenix.HTML.raw(~s(<svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    </svg>))
  end
  
  def get_ticket_icon(%ProductionOrder{} = _ticket) do
    Phoenix.HTML.raw(~s(<svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
    </svg>))
  end

  defp load_truck_documents(socket) do
    documents = Repo.all(
      from d in EvaaCrmGaepell.TruckDocument,
      where: d.truck_id == ^socket.assigns.truck.id,
      order_by: [desc: d.uploaded_at],
      preload: [:user, :maintenance_ticket]
    )
    assign(socket, :truck_documents, documents)
  end



  @impl true
  def handle_event("set_active_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("show_document_upload_modal", _params, socket) do
    {:noreply, socket
     |> assign(:show_document_upload_modal, true)}
  end

  @impl true
  def handle_event("hide_document_upload_modal", _params, socket) do
    {:noreply, assign(socket, :show_document_upload_modal, false)}
  end

  @impl true
  def handle_event("show_document_photo_upload_modal", _params, socket) do
    IO.puts("=== SHOW DOCUMENT PHOTO UPLOAD MODAL ===")
    {:noreply, socket
     |> assign(:show_document_photo_upload_modal, true)}
  end

  @impl true
  def handle_event("hide_document_photo_upload_modal", _params, socket) do
    IO.puts("=== HIDE DOCUMENT PHOTO UPLOAD MODAL ===")
    {:noreply, assign(socket, :show_document_photo_upload_modal, false)}
  end

  @impl true
  def handle_event("select_ticket_for_document", %{"ticket_id" => ticket_id}, socket) do
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    {:noreply, assign(socket, :selected_ticket_for_document, ticket_id)}
  end

  @impl true
  def handle_event("toggle_ticket_details", %{"ticket-id" => ticket_id}, socket) do
    ticket_id = String.to_integer(ticket_id)
    expanded_tickets = socket.assigns.expanded_tickets
    
    # Toggle el estado del ticket
    new_expanded_tickets = if Map.get(expanded_tickets, ticket_id, false) do
      Map.delete(expanded_tickets, ticket_id)
    else
      Map.put(expanded_tickets, ticket_id, true)
    end
    
    {:noreply, assign(socket, :expanded_tickets, new_expanded_tickets)}
  end

  @impl true
  def handle_event("upload_document", params, socket) do
    IO.puts("=== UPLOAD DOCUMENT DEBUG ===")
    IO.puts("Params: #{inspect(params)}")
    
    title = params["title"] || ""
    description = params["description"] || ""
    ticket_id = params["ticket_id"] || ""
    
    IO.puts("Title: #{title}")
    IO.puts("Description: #{description}")
    IO.puts("Ticket ID: #{ticket_id}")
    
    # Convertir ticket_id vacío a nil
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    
    # Check if there are any files selected
    entries = socket.assigns.uploads.document_files.entries
    IO.puts("Upload entries: #{inspect(entries)}")
    IO.puts("Number of entries: #{length(entries)}")
    
    all_present = length(entries) > 0
    
    IO.puts("All present: #{all_present}")
    
    cond do
      !all_present ->
        {:noreply, 
         socket
         |> put_flash(:error, "Por favor selecciona un archivo PDF")
         |> assign(:show_document_upload_modal, true)}
      
      true ->
        case save_document(socket, "pdf", title, description, ticket_id) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:success, "Documento PDF subido exitosamente")
             |> assign(:show_document_upload_modal, false)
             |> load_truck_documents()}
          
          {:error, :no_files} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Por favor selecciona un archivo PDF")
             |> assign(:show_document_upload_modal, true)}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al subir el documento")
             |> assign(:show_document_upload_modal, false)}
        end
    end
  end

  @impl true
  def handle_event("upload_document_photo", params, socket) do
    IO.puts("=== UPLOAD DOCUMENT PHOTO DEBUG ===")
    IO.puts("Params: #{inspect(params)}")
    
    title = params["title"] || ""
    description = params["description"] || ""
    ticket_id = params["ticket_id"] || ""
    
    IO.puts("Title: #{title}")
    IO.puts("Description: #{description}")
    IO.puts("Ticket ID: #{ticket_id}")
    
    # Convertir ticket_id vacío a nil
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    
    # Check if there are any files selected
    entries = socket.assigns.uploads.document_photos.entries
    IO.puts("Upload entries: #{inspect(entries)}")
    IO.puts("Number of entries: #{length(entries)}")
    
    all_present = length(entries) > 0
    
    IO.puts("All present: #{all_present}")
    
    cond do
      !all_present ->
        {:noreply, 
         socket
         |> put_flash(:error, "Por favor selecciona al menos una foto")
         |> assign(:show_document_photo_upload_modal, true)}
      
      true ->
        case save_document(socket, "photo", title, description, ticket_id) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:success, "Fotos de documento subidas exitosamente")
             |> assign(:show_document_photo_upload_modal, false)
             |> load_truck_documents()}
          
          {:error, :no_files} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Por favor selecciona al menos una foto")
             |> assign(:show_document_photo_upload_modal, true)}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al subir las fotos de documento")
             |> assign(:show_document_photo_upload_modal, false)}
        end
    end
  end



  @impl true
  def handle_event("validate_document_upload", %{"document" => _params}, socket) do
    # Validación del formulario de documento
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_document_photo_upload", %{"document_photo" => _params}, socket) do
    # Validación del formulario de foto de documento
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_quotation_preview", %{"quotation-id" => quotation_id}, socket) do
    quotation_id = String.to_integer(quotation_id)
    quotation = Repo.get(EvaaCrmGaepell.SymasoftImport, quotation_id)

    if quotation && quotation.truck_id == socket.assigns.truck.id && File.exists?(quotation.file_path) do
      case parse_symasoft_pdf(quotation.file_path) do
        {:ok, parsed_data} ->
          {:noreply, 
           socket
           |> assign(:show_quotation_preview_modal, true)
           |> assign(:selected_quotation_data, parsed_data)}
        
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Error al procesar PDF")}
      end
    else
      {:noreply, put_flash(socket, :error, "PDF no encontrado")}
    end
  end

  @impl true
  def handle_event("hide_quotation_preview", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_quotation_preview_modal, false)
     |> assign(:selected_quotation_data, nil)}
  end

  # Función para parsear PDF (copiada de symasoft_integration_live.ex)
  defp parse_symasoft_pdf(pdf_path) do
    case extract_text_from_pdf(pdf_path) do
      {:ok, text} ->
        case determine_document_type(text) do
          "FACTURA" -> parse_factura(text)
          "RECIBO_DE_INGRESO" -> parse_recibo_ingreso_original(text)
          _ -> {:error, "Tipo de documento no reconocido"}
        end
      
      {:error, reason} ->
        {:error, "Error al extraer texto del PDF: #{reason}"}
    end
  end

  defp extract_text_from_pdf(pdf_path) do
    try do
      # Intentar con pdftotext primero
      case System.cmd("pdftotext", [pdf_path, "-"]) do
        {text, 0} when byte_size(text) > 0 ->
          {:ok, text}
        
        _ ->
          # Fallback a Python
          extract_with_python(pdf_path)
      end
    rescue
      e ->
        IO.puts("🔍 DEBUG: Error en pdftotext, usando Python fallback: #{inspect(e)}")
        extract_with_python(pdf_path)
    end
  end

  defp extract_with_python(pdf_path) do
    IO.puts("🔍 DEBUG: Iniciando extracción con Python para: #{pdf_path}")
    
    python_script = """
    import PyPDF2
    import sys
    
    try:
        with open(sys.argv[1], 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            text = ""
            for page in reader.pages:
                text += page.extract_text()
            print(text)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    """
    
    temp_script_path = Path.join(System.tmp_dir!(), "extract_pdf.py")
    File.write!(temp_script_path, python_script)
    IO.puts("🔍 DEBUG: Script guardado en: #{temp_script_path}")
    
    case System.cmd("python3", [temp_script_path, pdf_path]) do
      {text, 0} ->
        IO.puts("🔍 DEBUG: Extracción exitosa, texto obtenido: #{byte_size(text)} caracteres")
        IO.puts("🔍 DEBUG: ✅ Texto extraído exitosamente")
        IO.puts("🔍 DEBUG: Tamaño del texto: #{byte_size(text)} caracteres")
        IO.puts("🔍 DEBUG: Primeros 300 caracteres: #{String.slice(text, 0, 300)}")
        IO.puts("🔍 DEBUG: Número de líneas: #{length(String.split(text, "\\n"))}")
        IO.puts("🔍 DEBUG: Primeras 5 líneas: #{Enum.take(String.split(text, "\\n"), 5) |> Enum.join("\\n")}")
        {:ok, text}
      
      {error_output, _exit_code} ->
        IO.puts("🔍 DEBUG: Error en Python: #{error_output}")
        {:error, "Error en extracción con Python: #{error_output}"}
    end
  end

  defp determine_document_type(text) do
    cond do
      String.contains?(text, "FACTURA") -> "FACTURA"
      String.contains?(text, "RECIBO DE INGRESO") -> "RECIBO_DE_INGRESO"
      true -> "UNKNOWN"
    end
  end

  defp parse_factura(text) do
    lines = String.split(text, "\n") |> Enum.map(&String.trim/1) |> Enum.filter(&(&1 != ""))
    
    # Extraer información básica
    cliente = extract_cliente_factura(lines)
    numero_factura = extract_numero_factura(lines)
    fecha_factura = extract_fecha_factura(lines)
    monto_total = extract_monto_total_factura(lines)
    items = extract_items_factura(lines)
    
    parsed_data = %{
      tipo_documento: "FACTURA",
      cliente: cliente,
      numero_factura: numero_factura,
      fecha_factura: fecha_factura,
      monto_total: monto_total,
      items: items,
      facturas: [],
      forma_pago: "No especificado",
      concepto: "Venta de productos",
      balance_pendiente: "0.00",
      fecha_procesamiento: Date.utc_today()
    }
    
    IO.puts("🔍 DEBUG: ✅ Datos parseados exitosamente")
    IO.puts("🔍 DEBUG: Datos parseados: #{inspect(parsed_data)}")
    {:ok, parsed_data}
  end

  defp parse_recibo_ingreso_original(text) do
    lines = String.split(text, "\n") |> Enum.map(&String.trim/1) |> Enum.filter(&(&1 != ""))
    
    # Extraer información básica
    cliente = extract_cliente_recibo(lines)
    monto_total = extract_monto_total_recibo(lines)
    forma_pago = extract_forma_pago(lines)
    concepto = extract_concepto(lines)
    facturas = extract_facturas_recibo(lines)
    balance_pendiente = extract_balance_pendiente(lines)
    
    parsed_data = %{
      tipo_documento: "RECIBO_DE_INGRESO",
      cliente: cliente,
      numero_factura: "N/A",
      fecha_factura: "N/A",
      monto_total: monto_total,
      items: [],
      facturas: facturas,
      forma_pago: forma_pago,
      concepto: concepto,
      balance_pendiente: balance_pendiente,
      fecha_procesamiento: Date.utc_today()
    }
    
    {:ok, parsed_data}
  end

  defp extract_cliente_factura(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Cliente:") end) do
      nil -> "Cliente no encontrado"
      line -> 
        case Regex.run(~r/Cliente:\s*(.+)/, line) do
          [_, cliente] -> String.trim(cliente)
          _ -> "Cliente no encontrado"
        end
    end
  end

  defp extract_numero_factura(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Factura:") end) do
      nil -> "Número no encontrado"
      line -> 
        case Regex.run(~r/Factura:\s*(.+)/, line) do
          [_, numero] -> String.trim(numero)
          _ -> "Número no encontrado"
        end
    end
  end

  defp extract_fecha_factura(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Fecha:") end) do
      nil -> "Fecha no encontrada"
      line -> 
        case Regex.run(~r/Fecha:\s*(.+)/, line) do
          [_, fecha] -> String.trim(fecha)
          _ -> "Fecha no encontrada"
        end
    end
  end

  defp extract_monto_total_factura(lines) do
    # Buscar el total en los items
    case extract_items_factura(lines) do
      [] -> "0.00"
      items ->
        total = Enum.reduce(items, Decimal.new(0), fn item, acc ->
          case Decimal.parse(item.total) do
            {:ok, decimal} -> Decimal.add(acc, decimal)
            :error -> acc
          end
        end)
        Decimal.to_string(total)
    end
  end

  defp extract_items_factura(lines) do
    # Buscar la sección de items
    items_start = Enum.find_index(lines, fn line -> 
      String.contains?(line, "Descripción") and String.contains?(line, "Cantidad")
    end)
    
    if items_start do
      items_lines = Enum.slice(lines, items_start + 1, 10) # Tomar las siguientes 10 líneas
      
      Enum.reduce_while(items_lines, [], fn line, acc ->
        case Regex.run(~r/^(.+?)\s+(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)$/, line) do
          [_, descripcion, cantidad, precio_unit, total] ->
            item = %{
              descripcion: String.trim(descripcion),
              cantidad: cantidad,
              precio_unitario: precio_unit,
              total: total
            }
            {:cont, [item | acc]}
          
          _ ->
            {:halt, acc}
        end
      end)
      |> Enum.reverse()
    else
      []
    end
  end

  defp extract_cliente_recibo(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Recibido de:") end) do
      nil -> "Cliente no encontrado"
      line -> 
        case Regex.run(~r/Recibido de:\s*(.+)/, line) do
          [_, cliente] -> String.trim(cliente)
          _ -> "Cliente no encontrado"
        end
    end
  end

  defp extract_monto_total_recibo(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "La Suma de:") end) do
      nil -> "0.00"
      line -> 
        case Regex.run(~r/La Suma de:\s*RD\$\s*([\d,]+\.?\d*)/, line) do
          [_, monto] -> String.replace(monto, ",", "")
          _ -> "0.00"
        end
    end
  end

  defp extract_forma_pago(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Forma de Pago:") end) do
      nil -> "No especificado"
      line -> 
        case Regex.run(~r/Forma de Pago:\s*(.+)/, line) do
          [_, forma] -> String.trim(forma)
          _ -> "No especificado"
        end
    end
  end

  defp extract_concepto(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Concepto:") end) do
      nil -> "No especificado"
      line -> 
        case Regex.run(~r/Concepto:\s*(.+)/, line) do
          [_, concepto] -> String.trim(concepto)
          _ -> "No especificado"
        end
    end
  end

  defp extract_facturas_recibo(lines) do
    # Buscar la sección de facturas
    facturas_start = Enum.find_index(lines, fn line -> 
      String.contains?(line, "F A C T U R A S")
    end)
    
    if facturas_start do
      facturas_lines = Enum.slice(lines, facturas_start + 2, 10) # Tomar las siguientes 10 líneas
      
      Enum.reduce_while(facturas_lines, [], fn line, acc ->
        case Regex.run(~r/^(\d+)\s+(\d{2}\/\d{2}\/\d{4})\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)$/, line) do
          [_, numero, fecha, valor, recibido, pendiente] ->
            factura = %{
              numero: numero,
              fecha: fecha,
              valor: valor,
              recibido: recibido,
              pendiente: pendiente
            }
            {:cont, [factura | acc]}
          
          _ ->
            {:halt, acc}
        end
      end)
      |> Enum.reverse()
    else
      []
    end
  end

  defp extract_balance_pendiente(lines) do
    case Enum.find(lines, fn line -> String.contains?(line, "Balance Pendiente") end) do
      nil -> "0.00"
      line -> 
        case Regex.run(~r/Balance Pendiente RD\$\s*([\d,]+\.?\d*)/, line) do
          [_, balance] -> String.replace(balance, ",", "")
          _ -> "0.00"
        end
    end
  end

  defp generate_symasoft_view(parsed_data) do
    case parsed_data.tipo_documento do
      "FACTURA" ->
        %{
          header: %{
            title: "FACTURA",
            cliente: parsed_data.cliente,
            numero_factura: parsed_data.numero_factura,
            fecha_factura: parsed_data.fecha_factura,
            monto_total: parsed_data.monto_total
          },
          items: parsed_data.items,
          facturas: [],
          balance_pendiente: "0.00"
        }
      
      "RECIBO_DE_INGRESO" ->
        %{
          header: %{
            title: "RECIBO DE INGRESO RD$",
            cliente: parsed_data.cliente,
            monto_total: parsed_data.monto_total,
            forma_pago: parsed_data.forma_pago,
            concepto: parsed_data.concepto
          },
          items: [],
          facturas: parsed_data.facturas,
          balance_pendiente: parsed_data.balance_pendiente
        }
      
      _ ->
        %{
          header: %{
            title: "DOCUMENTO",
            cliente: "No identificado",
            monto_total: "0.00"
          },
          items: [],
          facturas: [],
          balance_pendiente: "0.00"
        }
    end
  end

  # Helper function for formatting currency
  defp format_currency(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _remainder} ->
        decimal
        |> Decimal.to_string()
        |> String.replace(".", ",")
      :error ->
        value
    end
  end

  defp format_currency(%Decimal{} = decimal) do
    decimal
    |> Decimal.to_string()
    |> String.replace(".", ",")
  end

  defp format_currency(value) do
    to_string(value)
  end

  @impl true
  def handle_event("show_edit_form", _params, socket) do
    changeset = EvaaCrmGaepell.Truck.changeset(socket.assigns.truck, %{})
    {:noreply, socket |> assign(:show_edit_form, true) |> assign(:editing_truck, changeset)}
  end

  @impl true
  def handle_event("hide_edit_form", _params, socket) do
    {:noreply, socket |> assign(:show_edit_form, false) |> assign(:editing_truck, nil)}
  end

  @impl true
  def handle_event("update_truck", %{"truck" => truck_params}, socket) do
    case Repo.update(Truck.changeset(socket.assigns.truck, truck_params)) do
      {:ok, updated_truck} ->
        # Recargar el truck desde la base de datos para asegurar que los datos estén actualizados
        reloaded_truck = Repo.get(Truck, socket.assigns.truck.id)
        {:noreply, 
          socket 
          |> assign(:truck, reloaded_truck)
          |> assign(:show_edit_form, false)
          |> assign(:editing_truck, nil)
          |> put_flash(:info, "Camión actualizado correctamente")
        }
      {:error, changeset} ->
        {:noreply, 
          socket 
          |> assign(:editing_truck, changeset)
          |> put_flash(:error, "Error al actualizar el camión")
        }
    end
  end

  # Event handlers para los modales de edición de las cards técnicas
  
  @impl true
  def handle_event("edit_box_type", _params, socket) do
    {:noreply, assign(socket, :show_edit_box_type_modal, true)}
  end

  @impl true
  def handle_event("hide_edit_box_type_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_box_type_modal, false)}
  end

  @impl true
  def handle_event("update_box_type", %{"truck" => truck_params}, socket) do
    case Repo.update(Truck.changeset(socket.assigns.truck, truck_params)) do
      {:ok, updated_truck} ->
        reloaded_truck = Repo.get(Truck, socket.assigns.truck.id)
        {:noreply, 
          socket 
          |> assign(:truck, reloaded_truck)
          |> assign(:show_edit_box_type_modal, false)
          |> put_flash(:info, "Tipo de caja actualizado correctamente")
        }
      {:error, _changeset} ->
        {:noreply, 
          socket 
          |> put_flash(:error, "Error al actualizar el tipo de caja")
        }
    end
  end

  @impl true
  def handle_event("edit_tire_width", _params, socket) do
    {:noreply, assign(socket, :show_edit_tire_width_modal, true)}
  end

  @impl true
  def handle_event("hide_edit_tire_width_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_tire_width_modal, false)}
  end

  @impl true
  def handle_event("update_tire_width", %{"truck" => truck_params}, socket) do
    case Repo.update(Truck.changeset(socket.assigns.truck, truck_params)) do
      {:ok, updated_truck} ->
        reloaded_truck = Repo.get(Truck, socket.assigns.truck.id)
        {:noreply, 
          socket 
          |> assign(:truck, reloaded_truck)
          |> assign(:show_edit_tire_width_modal, false)
          |> put_flash(:info, "Ancho de gomas traseras actualizado correctamente")
        }
      {:error, _changeset} ->
        {:noreply, 
          socket 
          |> put_flash(:error, "Error al actualizar el ancho de gomas traseras")
        }
    end
  end

  @impl true
  def handle_event("edit_useful_length", _params, socket) do
    {:noreply, assign(socket, :show_edit_useful_length_modal, true)}
  end

  @impl true
  def handle_event("hide_edit_useful_length_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_useful_length_modal, false)}
  end

  @impl true
  def handle_event("update_useful_length", %{"truck" => truck_params}, socket) do
    case Repo.update(Truck.changeset(socket.assigns.truck, truck_params)) do
      {:ok, updated_truck} ->
        reloaded_truck = Repo.get(Truck, socket.assigns.truck.id)
        {:noreply, 
          socket 
          |> assign(:truck, reloaded_truck)
          |> assign(:show_edit_useful_length_modal, false)
          |> put_flash(:info, "Largo útil actualizado correctamente")
        }
      {:error, _changeset} ->
        {:noreply, 
          socket 
          |> put_flash(:error, "Error al actualizar el largo útil")
        }
    end
  end

  @impl true
  def handle_event("edit_chassis_width", _params, socket) do
    {:noreply, assign(socket, :show_edit_chassis_width_modal, true)}
  end

  @impl true
  def handle_event("hide_edit_chassis_width_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_chassis_width_modal, false)}
  end

  @impl true
  def handle_event("update_chassis_width", %{"truck" => truck_params}, socket) do
    case Repo.update(Truck.changeset(socket.assigns.truck, truck_params)) do
      {:ok, updated_truck} ->
        reloaded_truck = Repo.get(Truck, socket.assigns.truck.id)
        {:noreply, 
          socket 
          |> assign(:truck, reloaded_truck)
          |> assign(:show_edit_chassis_width_modal, false)
          |> put_flash(:info, "Ancho de chasis actualizado correctamente")
        }
      {:error, _changeset} ->
        {:noreply, 
          socket 
          |> put_flash(:error, "Error al actualizar el ancho de chasis")
        }
    end
  end

  @impl true
  def handle_event("show_photo_gallery", _params, socket) do
    socket = allow_upload(socket, :truck_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 5, max_file_size: 8_000_000, auto_upload: true)
    {:noreply, assign(socket, :show_photo_gallery, true)}
  end

  @impl true
  def handle_event("hide_photo_gallery", _params, socket) do
    {:noreply, assign(socket, :show_photo_gallery, false)}
  end

  @impl true
  def handle_event("select_ticket_for_photo", %{"ticket_id" => ticket_id}, socket) do
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    {:noreply, assign(socket, :selected_ticket_for_photo, ticket_id)}
  end

  @impl true
  def handle_event("upload_truck_photos", params, socket) do
    photo_type = params["photo_type"] || "general"
    description = params["description"] || ""
    ticket_id = params["ticket_id"] || ""
    
    # Convertir ticket_id vacío a nil
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    
    # Check if there are any files selected and if they're all uploaded
    entries = socket.assigns.uploads.truck_photos.entries
    all_present = length(entries) > 0
    uploading_files = Enum.any?(entries, fn entry -> !entry.done? end)
    
    cond do
      !all_present ->
        {:noreply, 
         socket
         |> put_flash(:error, "Por favor selecciona al menos una foto")
         |> assign(:show_photo_gallery, true)}
      
      uploading_files ->
        {:noreply, 
         socket
         |> put_flash(:error, "Espera a que se completen todas las subidas antes de guardar")
         |> assign(:show_photo_gallery, true)}
      
      true ->
        case save_truck_photos(socket, photo_type, description, ticket_id) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:success, "Fotos subidas exitosamente")
             |> assign(:show_photo_gallery, false)
             |> load_truck_photos()}
          
          {:error, :no_files} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Por favor selecciona al menos una foto")
             |> assign(:show_photo_gallery, true)}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al subir las fotos")
             |> assign(:show_photo_gallery, false)}
        end
    end
  end



  @impl true
  def handle_event("update_truck", %{"truck" => truck_params}, socket) do
    case update_truck(socket.assigns.truck, truck_params) do
      {:ok, updated_truck} ->
        {:noreply, 
         socket 
         |> assign(:truck, updated_truck)
         |> assign(:show_edit_form, false)
         |> assign(:editing_truck, nil)
         |> put_flash(:info, "Camión actualizado correctamente")}
      
      {:error, changeset} ->
        {:noreply, socket |> assign(:editing_truck, changeset)}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    IO.puts("=== CANCEL UPLOAD ===")
    IO.puts("Ref: #{ref}")
    
    # Intentar cancelar en ambos tipos de uploads
    socket = cancel_upload(socket, :truck_photos, ref)
    socket = cancel_upload(socket, :document_photos, ref)
    socket = cancel_upload(socket, :document_files, ref)
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("ignore", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("phx-upload", %{"ref" => _ref, "entries" => _entries}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("photos_selected", _params, socket) do
    IO.puts("=== PHOTOS SELECTED ===")
    {:noreply, socket}
  end

  @impl true
  def handle_event("document_photos_selected", _params, socket) do
    IO.puts("=== DOCUMENT PHOTOS SELECTED ===")
    IO.puts("Entries: #{inspect(socket.assigns.uploads.document_photos.entries)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event("document_files_selected", _params, socket) do
    IO.puts("=== DOCUMENT FILES SELECTED ===")
    IO.puts("Entries: #{inspect(socket.assigns.uploads.document_files.entries)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_photo_fullscreen", %{"photo-id" => photo_id}, socket) do
    photo_id = String.to_integer(photo_id)
    photo = Repo.get(TruckPhoto, photo_id)
    
    if photo do
      {:noreply, 
        socket 
        |> assign(:show_fullscreen_photo, true)
        |> assign(:fullscreen_photo, photo)
      }
    else
      {:noreply, put_flash(socket, :error, "Foto no encontrada")}
    end
  end

  @impl true
  def handle_event("hide_fullscreen_photo", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_fullscreen_photo, false)
      |> assign(:fullscreen_photo, nil)
    }
  end

  @impl true
  def handle_event("hide_fullscreen_pdf", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_fullscreen_pdf, false)
      |> assign(:fullscreen_pdf, nil)
    }
  end

  @impl true
  def handle_event("edit_photo_description", %{"photo-id" => photo_id}, socket) do
    photo_id = String.to_integer(photo_id)
    photo = Repo.get(TruckPhoto, photo_id)
    
    if photo do
      {:noreply, 
        socket 
        |> assign(:show_edit_description_modal, true)
        |> assign(:editing_photo_id, photo_id)
        |> assign(:editing_photo_description, photo.description || "")
        |> assign(:editing_photo_ticket_id, photo.maintenance_ticket_id)
      }
    else
      {:noreply, put_flash(socket, :error, "Foto no encontrada")}
    end
  end

  @impl true
  def handle_event("hide_edit_description_modal", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_edit_description_modal, false)
      |> assign(:editing_photo_id, nil)
      |> assign(:editing_photo_description, "")
      |> assign(:editing_photo_ticket_id, nil)
    }
  end

  @impl true
  def handle_event("update_photo_description", %{"photo_id" => photo_id, "description" => description, "ticket_id" => ticket_id}, socket) do
    photo_id = String.to_integer(photo_id)
    photo = Repo.get(TruckPhoto, photo_id)
    
    # Convertir ticket_id vacío a nil
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    
    if photo do
      case Repo.update(TruckPhoto.changeset(photo, %{description: description, maintenance_ticket_id: ticket_id})) do
        {:ok, _updated_photo} ->
          {:noreply, 
            socket 
            |> assign(:show_edit_description_modal, false)
            |> assign(:editing_photo_id, nil)
            |> assign(:editing_photo_description, "")
            |> assign(:editing_photo_ticket_id, nil)
            |> load_truck_photos()
            |> put_flash(:info, "Foto actualizada correctamente")
          }
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al actualizar la foto")}
      end
    else
      {:noreply, put_flash(socket, :error, "Foto no encontrada")}
    end
  end

  @impl true
  def handle_event("delete_photo", %{"photo-id" => photo_id}, socket) do
    photo_id = String.to_integer(photo_id)
    photo = Repo.get(TruckPhoto, photo_id)
    
    if photo do
      # Eliminar el archivo físico
      photo_path = Path.join(File.cwd!(), "priv/static#{photo.photo_path}")
      
      case delete_photo_file(photo_path) do
        {:ok, _} ->
          # Eliminar el registro de la base de datos
          case Repo.delete(photo) do
            {:ok, _} ->
              {:noreply, 
                socket 
                |> assign(:show_fullscreen_photo, false)
                |> assign(:fullscreen_photo, nil)
                |> load_truck_photos()
                |> put_flash(:info, "Foto eliminada correctamente")
              }
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Error al eliminar la foto de la base de datos")}
          end
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Error al eliminar el archivo: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Foto no encontrada")}
    end
  end

  @impl true
  def handle_event("delete_document_photo", %{"document-id" => document_id}, socket) do
    IO.puts("=== DELETE DOCUMENT PHOTO DEBUG ===")
    IO.puts("Document ID: #{document_id}")
    
    document_id = String.to_integer(document_id)
    document = Repo.get(TruckDocument, document_id)
    
    if document && document.document_type == "photo" do
      # Eliminar el archivo físico
      file_path = Path.join(File.cwd!(), "priv/static#{document.file_path}")
      
      case delete_photo_file(file_path) do
        {:ok, _} ->
          # Eliminar el registro de la base de datos
          case Repo.delete(document) do
            {:ok, _} ->
              {:noreply, 
                socket 
                |> assign(:show_fullscreen_photo, false)
                |> assign(:fullscreen_photo, nil)
                |> load_truck_documents()
                |> put_flash(:info, "Foto de documento eliminada correctamente")
              }
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Error al eliminar la foto de documento de la base de datos")}
          end
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Error al eliminar el archivo: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Foto de documento no encontrada")}
    end
  end

  @impl true
  def handle_event("delete_document_pdf", %{"document-id" => document_id}, socket) do
    IO.puts("=== DELETE DOCUMENT PDF DEBUG ===")
    IO.puts("Document ID: #{document_id}")
    
    document_id = String.to_integer(document_id)
    document = Repo.get(TruckDocument, document_id)
    
    if document && document.document_type == "pdf" do
      # Eliminar el archivo físico
      file_path = Path.join(File.cwd!(), "priv/static#{document.file_path}")
      
      case delete_photo_file(file_path) do
        {:ok, _} ->
          # Eliminar el registro de la base de datos
          case Repo.delete(document) do
            {:ok, _} ->
              {:noreply, 
                socket 
                |> assign(:show_fullscreen_pdf, false)
                |> assign(:fullscreen_pdf, nil)
                |> load_truck_documents()
                |> put_flash(:info, "PDF de documento eliminado correctamente")
              }
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Error al eliminar el PDF de documento de la base de datos")}
          end
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Error al eliminar el archivo: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "PDF de documento no encontrado")}
    end
  end

  @impl true
  def handle_event("new_ticket_for_truck", %{"truck_id" => truck_id}, socket) do
    {:noreply, redirect(socket, to: "/checkin?truck_id=" <> truck_id)}
  end

  # Handlers para fotos de mantenimiento
  @impl true
  def handle_event("show_maintenance_photo_fullscreen", %{"photo-url" => photo_url, "ticket-id" => ticket_id, "photo-index" => photo_index}, socket) do
    ticket_id = String.to_integer(ticket_id)
    photo_index = String.to_integer(photo_index)
    
    # Buscar el ticket correspondiente
    ticket = Enum.find(socket.assigns.tickets, fn t -> t.id == ticket_id end)
    
    if ticket do
      photo_data = %{
        url: photo_url,
        ticket: ticket,
        index: photo_index
      }
      
      {:noreply, 
        socket 
        |> assign(:show_maintenance_photo_fullscreen, true)
        |> assign(:maintenance_fullscreen_photo, photo_data)
      }
    else
      {:noreply, put_flash(socket, :error, "Ticket no encontrado")}
    end
  end

  @impl true
  def handle_event("hide_maintenance_photo_fullscreen", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_maintenance_photo_fullscreen, false)
      |> assign(:maintenance_fullscreen_photo, nil)
    }
  end

  @impl true
  def handle_event("add_maintenance_photo_comment", %{"ticket-id" => ticket_id, "photo-url" => photo_url}, socket) do
    ticket_id = String.to_integer(ticket_id)
    
    {:noreply, 
      socket 
      |> assign(:show_maintenance_photo_comment_modal, true)
      |> assign(:maintenance_comment_ticket_id, ticket_id)
      |> assign(:maintenance_comment_photo_url, photo_url)
    }
  end

  @impl true
  def handle_event("hide_maintenance_photo_comment_modal", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_maintenance_photo_comment_modal, false)
      |> assign(:maintenance_comment_ticket_id, nil)
      |> assign(:maintenance_comment_photo_url, nil)
    }
  end

  @impl true
  def handle_event("save_maintenance_photo_comment", %{"ticket_id" => ticket_id, "photo_url" => photo_url, "comment" => comment}, socket) do
    ticket_id = String.to_integer(ticket_id)
    ticket = Repo.get(MaintenanceTicket, ticket_id)
    
    if ticket do
      # Actualizar el ticket con el nuevo comentario
      updated_exit_notes = if ticket.exit_notes && ticket.exit_notes != "" do
        "#{ticket.exit_notes}\n\n--- Comentario sobre foto ---\n#{comment}"
      else
        "--- Comentario sobre foto ---\n#{comment}"
      end
      
      case Repo.update(MaintenanceTicket.changeset(ticket, %{exit_notes: updated_exit_notes})) do
        {:ok, _updated_ticket} ->
          # Recargar los tickets para mostrar el comentario actualizado
          updated_tickets = Repo.all(from t in MaintenanceTicket, where: t.truck_id == ^socket.assigns.truck.id, order_by: [desc: t.entry_date])
          
          {:noreply, 
            socket 
            |> assign(:tickets, updated_tickets)
            |> assign(:show_maintenance_photo_comment_modal, false)
            |> assign(:maintenance_comment_ticket_id, nil)
            |> assign(:maintenance_comment_photo_url, nil)
            |> put_flash(:info, "Comentario agregado correctamente")
          }
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al guardar el comentario")}
      end
    else
      {:noreply, put_flash(socket, :error, "Ticket no encontrado")}
    end
  end

  defp update_truck(truck, attrs) do
    truck
    |> Truck.changeset(attrs)
    |> Repo.update()
  end



  defp save_truck_photos(socket, photo_type, description, ticket_id) do
    uploaded_files = 
      consume_uploaded_entries(socket, :truck_photos, fn %{path: path}, entry ->
        # Generate a unique filename with original extension
        ext = Path.extname(entry.client_name)
        filename = "truck_#{socket.assigns.truck.id}_photo_#{System.system_time()}_#{:rand.uniform(1000)}#{ext}"
        dest = Path.join(@uploads_dir, filename)
        
        # Ensure uploads directory exists
        File.mkdir_p!(Path.dirname(dest))
        
        # Copy the uploaded file
        File.cp!(path, dest)
        
        # Return the filename for database storage
        "/uploads/#{filename}"
              end)
    
    case uploaded_files do
      [] ->
        {:error, :no_files}
      
      files ->
        # Save each photo to the database
        results = Enum.map(files, fn filename ->
          photo_attrs = %{
            photo_path: filename,
            description: description,
            photo_type: photo_type,
            truck_id: socket.assigns.truck.id,
            maintenance_ticket_id: ticket_id,
            user_id: socket.assigns.current_user.id,
            uploaded_at: DateTime.utc_now()
          }
          
          %TruckPhoto{}
          |> TruckPhoto.changeset(photo_attrs)
          |> Repo.insert()
        end)
        
        # Check if all photos were saved successfully
        if Enum.all?(results, fn {status, _} -> status == :ok end) do
          {:ok, results}
        else
          # Log the errors for debugging
          failed_results = Enum.filter(results, fn {status, _} -> status == :error end)
          IO.inspect(failed_results, label: "Failed photo saves")
          {:error, :save_failed}
        end
    end
  end

  # Handlers para notas del camión
  @impl true
  def handle_event("show_add_note_modal", _params, socket) do
    changeset = TruckNote.changeset(%TruckNote{}, %{})
    {:noreply, 
     socket
     |> assign(:show_add_note_modal, true)
     |> assign(:note_changeset, changeset)}
  end

  @impl true
  def handle_event("hide_add_note_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_add_note_modal, false)
     |> assign(:note_changeset, nil)
     |> assign(:selected_ticket_for_note, nil)}
  end

  @impl true
  def handle_event("select_ticket_for_note", %{"ticket_id" => ticket_id}, socket) do
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    {:noreply, assign(socket, :selected_ticket_for_note, ticket_id)}
  end

  @impl true
  def handle_event("add_truck_note", %{"truck_note" => note_params}, socket) do
    note_attrs = Map.merge(note_params, %{
      "truck_id" => socket.assigns.truck.id,
      "user_id" => socket.assigns.current_user.id,
      "business_id" => socket.assigns.truck.business_id,
      "maintenance_ticket_id" => socket.assigns.selected_ticket_for_note
    })

    case %TruckNote{}
         |> TruckNote.changeset(note_attrs)
         |> Repo.insert() do
      {:ok, _note} ->
        {:noreply, 
         socket
         |> assign(:show_add_note_modal, false)
         |> assign(:note_changeset, nil)
         |> assign(:selected_ticket_for_note, nil)
         |> load_truck_notes()
         |> put_flash(:info, "Nota agregada correctamente")}
      
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(:note_changeset, changeset)
         |> put_flash(:error, "Error al agregar la nota")}
    end
  end

  @impl true
  def handle_event("delete_truck_note", %{"note_id" => note_id}, socket) do
    note_id = String.to_integer(note_id)
    note = Repo.get(TruckNote, note_id)
    
    if note && note.truck_id == socket.assigns.truck.id do
      case Repo.delete(note) do
        {:ok, _} ->
          {:noreply, 
           socket
           |> load_truck_notes()
           |> put_flash(:info, "Nota eliminada correctamente")}
        
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Error al eliminar la nota")}
      end
    else
      {:noreply, put_flash(socket, :error, "Nota no encontrada")}
    end
  end

    @impl true
  def handle_event("view_quotation_pdf", %{"quotation-id" => quotation_id}, socket) do
    quotation_id = String.to_integer(quotation_id)
    quotation = Repo.get(EvaaCrmGaepell.SymasoftImport, quotation_id)

    if quotation && quotation.truck_id == socket.assigns.truck.id && File.exists?(quotation.file_path) do
      # Redirect to the PDF file using the new /pdfs route
      {:noreply, push_navigate(socket, to: "/pdfs/#{Path.basename(quotation.file_path)}")}
    else
      {:noreply, put_flash(socket, :error, "PDF no encontrado")}
    end
  end

  @impl true
  def handle_event("view_document_photo", %{"document-id" => document_id}, socket) do
    IO.puts("=== VIEW DOCUMENT PHOTO DEBUG ===")
    IO.puts("Document ID: #{document_id}")
    
    document_id = String.to_integer(document_id)
    document = Repo.get(TruckDocument, document_id)
    
    IO.puts("Document found: #{inspect(document)}")
    IO.puts("Document type: #{document && document.document_type}")
    IO.puts("Truck ID match: #{document && document.truck_id == socket.assigns.truck.id}")

    if document && document.truck_id == socket.assigns.truck.id && document.document_type == "photo" do
      # Crear un objeto compatible con el modal de pantalla completa
      photo_object = %{
        id: document.id,
        photo_path: document.file_path,
        photo_type: "document",
        description: document.description,
        maintenance_ticket_id: document.maintenance_ticket_id,
        uploaded_at: document.uploaded_at
      }
      
      IO.puts("Photo object created: #{inspect(photo_object)}")
      IO.puts("Setting show_fullscreen_photo to true")
      IO.puts("Setting fullscreen_photo to: #{inspect(photo_object)}")
      
      socket = socket
               |> assign(:show_fullscreen_photo, true)
               |> assign(:fullscreen_photo, photo_object)
      
      IO.puts("Socket assigns after update: show_fullscreen_photo=#{socket.assigns.show_fullscreen_photo}")
      IO.puts("Socket assigns after update: fullscreen_photo=#{inspect(socket.assigns.fullscreen_photo)}")
      
      {:noreply, socket}
    else
      IO.puts("Document validation failed")
      {:noreply, put_flash(socket, :error, "Foto de documento no encontrada")}
    end
  end

  @impl true
  def handle_event("view_document_pdf", %{"document-id" => document_id}, socket) do
    IO.puts("=== VIEW DOCUMENT PDF DEBUG ===")
    IO.puts("Document ID: #{document_id}")
    
    document_id = String.to_integer(document_id)
    document = Repo.get(TruckDocument, document_id)
    
    IO.puts("Document found: #{inspect(document)}")
    IO.puts("Document type: #{document && document.document_type}")
    IO.puts("Truck ID match: #{document && document.truck_id == socket.assigns.truck.id}")

    if document && document.truck_id == socket.assigns.truck.id && document.document_type == "pdf" do
      IO.puts("PDF document validated, opening modal")
      IO.puts("Setting show_fullscreen_pdf to true")
      IO.puts("Setting fullscreen_pdf to: #{inspect(document)}")
      
      socket = socket
               |> assign(:show_fullscreen_pdf, true)
               |> assign(:fullscreen_pdf, document)
      
      IO.puts("Socket assigns after update: show_fullscreen_pdf=#{socket.assigns.show_fullscreen_pdf}")
      IO.puts("Socket assigns after update: fullscreen_pdf=#{inspect(socket.assigns.fullscreen_pdf)}")
      
      {:noreply, socket}
    else
      IO.puts("PDF document validation failed")
      {:noreply, put_flash(socket, :error, "PDF de documento no encontrado")}
    end
  end

  # Función para eliminar archivo físico de foto
  defp delete_photo_file(file_path) do
    case File.exists?(file_path) do
      true ->
        case File.rm(file_path) do
          :ok -> {:ok, :deleted}
          {:error, reason} -> {:error, "No se pudo eliminar el archivo: #{reason}"}
        end
      false ->
        # Si el archivo no existe, consideramos que ya fue eliminado
        {:ok, :already_deleted}
    end
  end

  # Función para guardar documentos
  defp save_document(socket, document_type, title, description, ticket_id) do
    IO.puts("=== SAVE DOCUMENT DEBUG ===")
    IO.puts("Document type: #{document_type}")
    IO.puts("Title: #{title}")
    IO.puts("Description: #{description}")
    IO.puts("Ticket ID: #{ticket_id}")
    
    upload_name = if document_type == "pdf", do: :document_files, else: :document_photos
    IO.puts("Upload name: #{upload_name}")
    

    
    uploaded_files = 
      consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
        # Generate a unique filename with original extension
        ext = Path.extname(entry.client_name)
        filename = "truck_#{socket.assigns.truck.id}_document_#{document_type}_#{System.system_time()}_#{:rand.uniform(1000)}#{ext}"
        dest = Path.join(@uploads_dir, filename)
        
        # Ensure uploads directory exists
        File.mkdir_p!(Path.dirname(dest))
        
        # Copy the uploaded file
        File.cp!(path, dest)
        
        # Return the filename for database storage
        "/uploads/#{filename}"
      end)
    
    IO.puts("Uploaded files: #{inspect(uploaded_files)}")
    
    case uploaded_files do
      [] ->
        IO.puts("No files uploaded")
        {:error, :no_files}
      
      files ->
        IO.puts("Files to save: #{inspect(files)}")
        IO.puts("Document type: #{document_type}")
        # Save each document to the database
        results = Enum.map(files, fn filename ->
          document_attrs = %{
            file_path: filename,
            title: title,
            description: description,
            document_type: document_type,
            truck_id: socket.assigns.truck.id,
            maintenance_ticket_id: ticket_id,
            user_id: socket.assigns.current_user.id,
            uploaded_at: DateTime.utc_now()
          }
          
          %TruckDocument{}
          |> TruckDocument.changeset(document_attrs)
          |> Repo.insert()
        end)
        
        # Check if all documents were saved successfully
        if Enum.all?(results, fn {status, _} -> status == :ok end) do
          IO.puts("All documents saved successfully")
          {:ok, results}
        else
          # Log the errors for debugging
          failed_results = Enum.filter(results, fn {status, _} -> status == :error end)
          IO.inspect(failed_results, label: "Failed document saves")
          IO.puts("Some documents failed to save")
          {:error, :save_failed}
        end
    end
  end

  @impl true
  def handle_event("edit_document_description", %{"document-id" => document_id}, socket) do
    IO.puts("=== EDIT DOCUMENT DESCRIPTION DEBUG ===")
    IO.puts("Document ID: #{document_id}")
    
    document_id = String.to_integer(document_id)
    document = Repo.get(TruckDocument, document_id)
    
    if document do
      IO.puts("Document found: #{inspect(document)}")
      {:noreply, 
        socket 
        |> assign(:show_fullscreen_pdf, false)
        |> assign(:fullscreen_pdf, nil)
        |> assign(:show_edit_document_description_modal, true)
        |> assign(:editing_document_id, document_id)
        |> assign(:editing_document_description, document.description || "")
        |> assign(:editing_document_title, document.title || "")
        |> assign(:editing_document_ticket_id, document.maintenance_ticket_id)
      }
    else
      IO.puts("Document not found")
      {:noreply, put_flash(socket, :error, "Documento no encontrado")}
    end
  end

  @impl true
  def handle_event("hide_edit_document_description_modal", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_edit_document_description_modal, false)
      |> assign(:editing_document_id, nil)
      |> assign(:editing_document_description, "")
      |> assign(:editing_document_title, "")
      |> assign(:editing_document_ticket_id, nil)
    }
  end

  @impl true
  def handle_event("update_document_description", %{"document_id" => document_id, "title" => title, "description" => description, "ticket_id" => ticket_id}, socket) do
    IO.puts("=== UPDATE DOCUMENT DESCRIPTION DEBUG ===")
    IO.puts("Document ID: #{document_id}")
    IO.puts("Title: #{title}")
    IO.puts("Description: #{description}")
    IO.puts("Ticket ID: #{ticket_id}")
    
    document_id = String.to_integer(document_id)
    document = Repo.get(TruckDocument, document_id)
    
    # Convertir ticket_id vacío a nil
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    
    if document do
      case Repo.update(TruckDocument.changeset(document, %{title: title, description: description, maintenance_ticket_id: ticket_id})) do
        {:ok, _updated_document} ->
          {:noreply, 
            socket 
            |> assign(:show_edit_document_description_modal, false)
            |> assign(:editing_document_id, nil)
            |> assign(:editing_document_description, "")
            |> assign(:editing_document_title, "")
            |> assign(:editing_document_ticket_id, nil)
            |> load_truck_documents()
            |> put_flash(:info, "Documento actualizado correctamente")
          }
        {:error, changeset} ->
          IO.puts("Error updating document: #{inspect(changeset)}")
          {:noreply, put_flash(socket, :error, "Error al actualizar el documento")}
      end
    else
      {:noreply, put_flash(socket, :error, "Documento no encontrado")}
    end
  end

  @impl true
  def handle_event("edit_truck_note", %{"note_id" => note_id}, socket) do
    IO.puts("=== EDIT TRUCK NOTE DEBUG ===")
    IO.puts("Note ID: #{note_id}")
    
    note_id = String.to_integer(note_id)
    note = Repo.get(TruckNote, note_id)
    
    if note do
      IO.puts("Note found: #{inspect(note)}")
      
      # Crear un changeset para la edición
      changeset = TruckNote.changeset(note, %{})
      
      {:noreply, 
        socket 
        |> assign(:show_edit_note_modal, true)
        |> assign(:editing_note_id, note_id)
        |> assign(:editing_note_type, note.note_type || "general")
        |> assign(:editing_note_content, note.content || "")
        |> assign(:editing_note_ticket_id, note.maintenance_ticket_id)
        |> assign(:editing_note_changeset, changeset)
      }
    else
      IO.puts("Note not found")
      {:noreply, put_flash(socket, :error, "Nota no encontrada")}
    end
  end

  @impl true
  def handle_event("hide_edit_note_modal", _params, socket) do
    {:noreply, 
      socket 
      |> assign(:show_edit_note_modal, false)
      |> assign(:editing_note_id, nil)
      |> assign(:editing_note_type, "general")
      |> assign(:editing_note_content, "")
      |> assign(:editing_note_ticket_id, nil)
      |> assign(:editing_note_changeset, nil)
    }
  end

  @impl true
  def handle_event("update_truck_note", %{"note_id" => note_id, "truck_note" => note_params, "ticket_id" => ticket_id}, socket) do
    IO.puts("=== UPDATE TRUCK NOTE DEBUG ===")
    IO.puts("Note ID: #{note_id}")
    IO.puts("Note params: #{inspect(note_params)}")
    IO.puts("Ticket ID: #{ticket_id}")
    
    note_id = String.to_integer(note_id)
    note = Repo.get(TruckNote, note_id)
    
    # Convertir ticket_id vacío a nil
    ticket_id = if ticket_id == "", do: nil, else: String.to_integer(ticket_id)
    
    if note do
      # Preparar los parámetros para la actualización - asegurar que todas las claves sean strings
      update_params = Map.merge(note_params, %{"maintenance_ticket_id" => ticket_id})
      
      case Repo.update(TruckNote.changeset(note, update_params)) do
        {:ok, _updated_note} ->
          {:noreply, 
            socket 
            |> assign(:show_edit_note_modal, false)
            |> assign(:editing_note_id, nil)
            |> assign(:editing_note_type, "general")
            |> assign(:editing_note_content, "")
            |> assign(:editing_note_ticket_id, nil)
            |> assign(:editing_note_changeset, nil)
            |> load_truck_notes()
            |> put_flash(:info, "Nota actualizada correctamente")
          }
        {:error, changeset} ->
          IO.puts("Error updating note: #{inspect(changeset)}")
          {:noreply, put_flash(socket, :error, "Error al actualizar la nota")}
      end
    else
      {:noreply, put_flash(socket, :error, "Nota no encontrada")}
    end
  end

  # Technical Info Modal Events
  @impl true
  def handle_event("show_technical_info_modal", _params, socket) do
    {:noreply, assign(socket, :show_technical_info_modal, true)}
  end

  @impl true
  def handle_event("hide_technical_info_modal", _params, socket) do
    {:noreply, assign(socket, :show_technical_info_modal, false)}
  end

  @impl true
  def handle_event("update_technical_info", %{"rear_tire_width" => rear_tire_width, "chassis_length" => chassis_length, "chassis_width" => chassis_width}, socket) do
    IO.puts("=== UPDATE TECHNICAL INFO DEBUG ===")
    IO.puts("Original values - rear_tire_width: #{rear_tire_width}, chassis_length: #{chassis_length}, chassis_width: #{chassis_width}")
    
    # Preparar los parámetros para la actualización
    update_params = %{
      "rear_tire_width" => String.to_integer(rear_tire_width),
      "chassis_length" => String.to_integer(chassis_length),
      "chassis_width" => String.to_integer(chassis_width)
    }
    
    IO.puts("Update params: #{inspect(update_params)}")
    IO.puts("Current truck values: rear_tire_width=#{socket.assigns.truck.rear_tire_width}, chassis_length=#{socket.assigns.truck.chassis_length}, chassis_width=#{socket.assigns.truck.chassis_width}")
    
    case Repo.update(Truck.changeset(socket.assigns.truck, update_params)) do
      {:ok, _updated_truck} ->
        # Recargar el truck desde la base de datos para asegurar que los datos estén actualizados
        reloaded_truck = Repo.get(Truck, socket.assigns.truck.id)
        IO.puts("Reloaded truck values: rear_tire_width=#{reloaded_truck.rear_tire_width}, chassis_length=#{reloaded_truck.chassis_length}, chassis_width=#{reloaded_truck.chassis_width}")
        {:noreply, 
          socket 
          |> assign(:truck, reloaded_truck)
          |> assign(:show_technical_info_modal, false)
          |> put_flash(:info, "Información técnica actualizada correctamente")
        }
      {:error, changeset} ->
        IO.puts("Error updating technical info: #{inspect(changeset)}")
        IO.puts("Changeset errors: #{inspect(changeset.errors)}")
        {:noreply, put_flash(socket, :error, "Error al actualizar la información técnica")}
    end
  end
end