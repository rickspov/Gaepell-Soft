defmodule EvaaCrmWebGaepell.TruckProfileLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Truck, MaintenanceTicket, TruckPhoto, TruckNote, Repo}
  import Ecto.Query
  
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
        |> assign(:show_edit_description_modal, false)
        |> assign(:editing_photo_id, nil)
        |> assign(:editing_photo_description, "")
        |> assign(:show_add_note_modal, false)
        |> assign(:note_changeset, nil)
        |> assign(:selected_ticket_for_note, nil)
        |> assign(:show_maintenance_photo_fullscreen, false)
        |> assign(:maintenance_fullscreen_photo, nil)
        |> assign(:show_maintenance_photo_comment_modal, false)
        |> assign(:maintenance_comment_ticket_id, nil)
        |> assign(:maintenance_comment_photo_url, nil)
        |> assign(:show_quotation_preview_modal, false)
        |> assign(:selected_quotation_data, nil)
        |> allow_upload(:truck_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 5, max_file_size: 8_000_000, auto_upload: true)
        |> load_truck_tickets()
        |> load_truck_photos()
        |> load_truck_notes()
        |> load_truck_quotations()}
    else
      {:ok, socket |> put_flash(:error, "Camión no encontrado") |> push_navigate(to: "/trucks")}
    end
  end

  defp load_truck_tickets(socket) do
    tickets = Repo.all(from t in MaintenanceTicket, where: t.truck_id == ^socket.assigns.truck.id, order_by: [desc: t.entry_date])
    assign(socket, :tickets, tickets)
  end

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
    {:noreply, cancel_upload(socket, :truck_photos, ref)}
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
end 