defmodule EvaaCrmWebGaepell.SymasoftIntegrationLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Repo, User, Truck, MaintenanceTicket, ProductionOrder, SymasoftImport}

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Integración Symasoft - E.V.A")
     |> assign(:show_import_modal, false)
     |> assign(:show_association_modal, false)
     |> assign(:selected_import, nil)
     |> assign(:import_result, nil)
     |> assign(:trucks, load_trucks())
     |> assign(:maintenance_tickets, load_maintenance_tickets())
     |> assign(:production_orders, load_production_orders())
     |> assign(:upload_progress, 0)
     |> assign(:is_uploading, false)
     |> assign(:upload_status, nil)
     |> assign(:symasoft_imports, load_symasoft_imports())
     |> allow_upload(:pdf_file, accept: ~w(.pdf), max_entries: 1, max_file_size: 10_000_000)}
  end

  @impl true
  def handle_event("show_import_modal", _params, socket) do
    {:noreply, assign(socket, :show_import_modal, true)}
  end

  @impl true
  def handle_event("close_import_modal", _params, socket) do
    {:noreply, assign(socket, :show_import_modal, false)}
  end

  @impl true
  def handle_event("show_association_modal", %{"import_id" => import_id}, socket) do
    import_record = Repo.get(SymasoftImport, import_id)
    {:noreply, 
     socket
     |> assign(:show_association_modal, true)
     |> assign(:selected_import, import_record)}
  end

  @impl true
  def handle_event("close_association_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_association_modal, false)
     |> assign(:selected_import, nil)}
  end

  @impl true
  def handle_event("associate_quotation", %{"truck_id" => truck_id, "ticket_type" => ticket_type, "ticket_id" => ticket_id, "quotation_number" => quotation_number, "quotation_amount" => quotation_amount, "quotation_notes" => quotation_notes}, socket) do
    import_record = socket.assigns.selected_import
    
    # Preparar los datos de asociación
    association_data = %{
      truck_id: if(truck_id != "", do: String.to_integer(truck_id), else: nil),
      quotation_number: quotation_number,
      quotation_amount: if(quotation_amount != "", do: Decimal.new(quotation_amount), else: nil),
      quotation_notes: quotation_notes,
      quotation_status: "pending"
    }
    
    # Agregar la asociación según el tipo de ticket
    association_data = case ticket_type do
      "maintenance" -> Map.put(association_data, :maintenance_ticket_id, if(ticket_id != "", do: String.to_integer(ticket_id), else: nil))
      "production" -> Map.put(association_data, :production_order_id, if(ticket_id != "", do: String.to_integer(ticket_id), else: nil))
      _ -> association_data
    end
    
    case import_record
         |> SymasoftImport.changeset(association_data)
         |> Repo.update() do
      {:ok, _updated_import} ->
        {:noreply,
         socket
         |> assign(:show_association_modal, false)
         |> assign(:selected_import, nil)
         |> assign(:symasoft_imports, load_symasoft_imports())
         |> put_flash(:success, "✅ Cotización asociada exitosamente")}
      
      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "❌ Error al asociar cotización: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("close_preview", _params, socket) do
    {:noreply,
     socket
     |> assign(:import_result, nil)}
  end

  @impl true
  def handle_event("validate_pdf", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_import", %{"import_id" => import_id}, socket) do
    case Repo.get(SymasoftImport, import_id) do
      nil ->
        {:noreply, socket |> put_flash(:error, "❌ Registro no encontrado")}
      
      import_record ->
        # Eliminar el archivo físico si existe
        if File.exists?(import_record.file_path) do
          File.rm(import_record.file_path)
        end
        
        # Eliminar el registro de la base de datos
        case Repo.delete(import_record) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(:symasoft_imports, load_symasoft_imports())
             |> put_flash(:success, "✅ Importación eliminada exitosamente")}
          
          {:error, _} ->
            {:noreply, socket |> put_flash(:error, "❌ Error al eliminar la importación")}
        end
    end
  end

  @impl true
  def handle_event("import_symasoft_pdf", _params, socket) do
    case consume_uploaded_entries(socket, :pdf_file, fn %{path: path}, _entry ->
      # Leer el archivo
      file_content = File.read!(path)
    
    # Generar nombre único para el archivo
      filename = "symasoft_import_#{System.system_time(:millisecond)}.pdf"
    file_path = Path.join([File.cwd!(), "sample_data", filename])
      content_hash = :crypto.hash(:sha256, file_content) |> Base.encode16()
    
    # Crear registro en la base de datos
    import_attrs = %{
      filename: filename,
      file_path: file_path,
      content_hash: content_hash,
      business_id: socket.assigns.current_user.business_id,
      user_id: socket.assigns.current_user.id,
      import_status: "processing"
    }
    
          case %SymasoftImport{} |> SymasoftImport.changeset(import_attrs) |> Repo.insert() do
        {:ok, symasoft_import} ->
          # Asegurar que el directorio existe
          File.mkdir_p(Path.dirname(file_path))
          
          # Guardar archivo en sample_data
          case File.write(file_path, file_content) do
            :ok ->
              # Procesar el PDF
              case parse_symasoft_pdf(file_path) do
                {:ok, parsed_data} ->
                  # Actualizar registro como completado
                  symasoft_import
                  |> SymasoftImport.changeset(%{
                    import_status: "completed",
                    processed_at: DateTime.utc_now(),
                    quotation_number: parsed_data.numero_factura,
                    quotation_amount: if(parsed_data.monto_total != "0.00", do: Decimal.new(parsed_data.monto_total), else: nil),
                    quotation_date: parsed_data.fecha_procesamiento
                  })
                  |> Repo.update()
                  
                  {:ok, parsed_data, symasoft_import}
                
                {:error, reason} ->
                  # Actualizar registro como fallido
                  symasoft_import
                  |> SymasoftImport.changeset(%{
                    import_status: "failed",
                    error_message: "Error al procesar PDF: #{reason}"
                  })
                  |> Repo.update()
                  
                  {:error, "Error al procesar PDF: #{reason}"}
              end
            
            {:error, reason} ->
              # Actualizar registro como fallido
              symasoft_import
              |> SymasoftImport.changeset(%{
                import_status: "failed",
                error_message: "Error al guardar archivo: #{reason}"
              })
              |> Repo.update()
              
              {:error, "Error al guardar archivo: #{reason}"}
          end
        
        {:error, changeset} ->
          {:error, "Error al crear registro: #{inspect(changeset.errors)}"}
      end
    end) do
      [{:ok, parsed_data, symasoft_import}] ->
        {:noreply,
         socket
         |> assign(:import_result, parsed_data)
         |> assign(:show_import_modal, false)
         |> assign(:symasoft_imports, load_symasoft_imports())
         |> put_flash(:success, "✅ PDF procesado exitosamente. Los datos han sido extraídos y guardados.")}
      
      [{:error, reason}] ->
        {:noreply,
         socket
         |> assign(:show_import_modal, false)
         |> put_flash(:error, "❌ Error al procesar PDF: #{reason}")}
      
      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "❌ Por favor selecciona un archivo PDF antes de procesar")}
      end
  end

  @impl true
  def handle_event("import_symasoft_pdf", %{"_target" => ["pdf_file"]}, socket) do
    # Manejar el cambio del archivo (phx-change)
    {:noreply, socket}
  end

  @impl true
  def handle_event("import_symasoft_pdf", params, socket) do
    # Manejar otros casos
    IO.inspect(params, label: "Unexpected params for import_symasoft_pdf")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:update_progress, progress, status}, socket) do
    {:noreply,
     socket
     |> assign(:upload_progress, progress)
     |> assign(:upload_status, status)}
  end

  @impl true
  def handle_info({:upload_completed, parsed_data, _pdf_data, _symasoft_import}, socket) do
    {:noreply,
     socket
     |> assign(:is_uploading, false)
     |> assign(:upload_progress, 100)
     |> assign(:upload_status, "¡Completado!")
     |> assign(:show_import_modal, false)
     |> assign(:import_result, parsed_data)
     |> assign(:symasoft_imports, load_symasoft_imports())
     |> put_flash(:success, "🎉 ¡Excelente! PDF importado exitosamente. Datos extraídos y procesados correctamente.")}
  end

  @impl true
  def handle_info({:upload_failed, error_message}, socket) do
    {:noreply,
     socket
     |> assign(:is_uploading, false)
     |> assign(:upload_progress, 0)
     |> assign(:upload_status, "Error")
     |> assign(:show_import_modal, false)
     |> put_flash(:error, "❌ Error al importar PDF: #{error_message}")}
  end

  @impl true
  def handle_event("load_import", %{"import_id" => import_id}, socket) do
    import_record = Repo.get(SymasoftImport, import_id)
    
    if import_record && File.exists?(import_record.file_path) do
      case parse_symasoft_pdf(import_record.file_path) do
              {:ok, parsed_data} ->
                {:noreply,
                 socket
           |> assign(:import_result, parsed_data)}
              
        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "❌ Error al cargar importación")}
            end
    else
      {:noreply,
       socket
       |> put_flash(:error, "❌ Archivo no encontrado")}
    end
  end

  defp load_symasoft_imports do
    import Ecto.Query
    
    Repo.all(
      from s in SymasoftImport,
      where: s.business_id == 1,
      order_by: [desc: s.inserted_at],
      limit: 10,
      preload: [:truck, :maintenance_ticket, :production_order]
    )
  end

  defp load_trucks do
    import Ecto.Query
    
    Repo.all(
      from t in Truck,
      where: t.business_id == 1,
      order_by: [asc: t.license_plate],
      select: {t.license_plate, t.id}
    )
  end

  defp load_maintenance_tickets do
    import Ecto.Query
    
    Repo.all(
      from t in MaintenanceTicket,
      where: t.business_id == 1,
      order_by: [desc: t.inserted_at],
      limit: 50
    )
    |> Enum.map(fn ticket -> {"Ticket ##{ticket.id} - #{ticket.title}", ticket.id} end)
  end

  defp load_production_orders do
    import Ecto.Query
    
    Repo.all(
      from p in ProductionOrder,
      where: p.business_id == 1,
      order_by: [desc: p.inserted_at],
      limit: 50
    )
    |> Enum.map(fn order -> {"Orden ##{order.id} - #{order.client_name} (#{order.license_plate})", order.id} end)
  end

  # Parsear PDF de Symasoft para importar a E.V.A
  defp parse_symasoft_pdf(pdf_path) do
    IO.puts("🔍 DEBUG: ===== INICIANDO PARSE_SYMASOFT_PDF =====")
    IO.puts("🔍 DEBUG: Ruta del PDF: #{pdf_path}")
    
    case extract_text_from_pdf(pdf_path) do
      {:ok, text_content} ->
        IO.puts("🔍 DEBUG: ✅ Texto extraído exitosamente")
        IO.puts("🔍 DEBUG: Tamaño del texto: #{String.length(text_content)} caracteres")
        IO.puts("🔍 DEBUG: Primeros 300 caracteres: #{String.slice(text_content, 0, 300)}")
        
        lines = String.split(text_content, "\n")
        IO.puts("🔍 DEBUG: Número de líneas: #{length(lines)}")
        IO.puts("🔍 DEBUG: Primeras 5 líneas: #{Enum.take(lines, 5)}")
        
        case parse_recibo_ingreso(lines) do
          {:ok, parsed_data} -> 
            IO.puts("🔍 DEBUG: ✅ Datos parseados exitosamente")
            IO.puts("🔍 DEBUG: Datos parseados: #{inspect(parsed_data)}")
            {:ok, parsed_data}
          {:error, reason} -> 
            IO.puts("🔍 DEBUG: ❌ Error al parsear recibo: #{inspect(reason)}")
            {:error, reason}
        end
      
      {:error, reason} ->
        IO.puts("🔍 DEBUG: ❌ Error al extraer texto: #{inspect(reason)}")
        {:error, "Error al extraer texto del PDF: #{reason}"}
    end
  end

  # Extraer texto de un archivo PDF
  defp extract_text_from_pdf(pdf_path) do
    try do
      # Intentar usar pdftotext (poppler-utils) primero
      case System.cmd("pdftotext", [pdf_path, "-"]) do
        {text, 0} -> {:ok, text}
        {_error, _} -> 
          # Si pdftotext no está disponible, usar Python con PyPDF2
          IO.puts("🔍 DEBUG: pdftotext no disponible, usando Python fallback")
          extract_with_python(pdf_path)
      end
    rescue
      e -> 
        IO.puts("🔍 DEBUG: Error en pdftotext, usando Python fallback: #{inspect(e)}")
        extract_with_python(pdf_path)
    end
  end

  # Extraer texto usando Python y PyPDF2
  defp extract_with_python(pdf_path) do
    IO.puts("🔍 DEBUG: Iniciando extracción con Python para: #{pdf_path}")
    
    python_script = """
    import sys
    import PyPDF2
    
    try:
        with open(sys.argv[1], 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            text = ""
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\\n"
            print(text)
    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)
    """
    
    # Guardar el script temporalmente
    script_path = Path.join(System.tmp_dir!(), "extract_pdf.py")
    File.write!(script_path, python_script)
    IO.puts("🔍 DEBUG: Script guardado en: #{script_path}")
    
    # Ejecutar el script de Python
    case System.cmd("python3", [script_path, pdf_path]) do
      {text, 0} -> 
        # Limpiar archivo temporal
        File.rm(script_path)
        IO.puts("🔍 DEBUG: Extracción exitosa, texto obtenido: #{String.length(text)} caracteres")
        {:ok, text}
      
      {error, exit_code} -> 
        # Limpiar archivo temporal
        File.rm(script_path)
        IO.puts("🔍 DEBUG: Error en Python, código: #{exit_code}, error: #{error}")
        {:error, "Error al extraer texto con Python (código #{exit_code}): #{error}"}
    end
  end

  # Guardar archivo PDF desde datos base64
  defp save_pdf_file(file_path, pdf_data) do
    IO.puts("🔍 DEBUG: ===== INICIANDO SAVE_PDF_FILE =====")
    IO.puts("🔍 DEBUG: Ruta del archivo: #{file_path}")
    IO.puts("🔍 DEBUG: Tamaño de datos base64: #{String.length(pdf_data)} caracteres")
    
    try do
      # Remover el prefijo data:application/pdf;base64, si existe
      clean_data = case String.split(pdf_data, ",") do
        [_prefix, data] -> 
          IO.puts("🔍 DEBUG: Prefijo removido, datos limpios")
          data
        _ -> 
          IO.puts("🔍 DEBUG: No se encontró prefijo, usando datos originales")
          pdf_data
      end
      
      IO.puts("🔍 DEBUG: Tamaño de datos limpios: #{String.length(clean_data)} caracteres")
      
      # Decodificar base64 y guardar
      case Base.decode64(clean_data) do
        {:ok, binary_data} ->
          IO.puts("🔍 DEBUG: Base64 decodificado exitosamente, tamaño: #{byte_size(binary_data)} bytes")
          
          # Crear directorio si no existe
          dir_path = Path.dirname(file_path)
          IO.puts("🔍 DEBUG: Creando directorio: #{dir_path}")
          File.mkdir_p!(dir_path)
          
          # Escribir archivo
          IO.puts("🔍 DEBUG: Escribiendo archivo...")
          File.write!(file_path, binary_data)
          IO.puts("🔍 DEBUG: ✅ Archivo guardado exitosamente")
          
          # Verificar que el archivo existe
          if File.exists?(file_path) do
            file_size = File.stat!(file_path).size
            IO.puts("🔍 DEBUG: ✅ Archivo confirmado, tamaño: #{file_size} bytes")
            :ok
          else
            IO.puts("🔍 DEBUG: ❌ ERROR: Archivo no encontrado después de escribir")
            {:error, "Archivo no encontrado después de escribir"}
          end
        
        :error ->
          IO.puts("🔍 DEBUG: ❌ Error al decodificar base64")
          {:error, "Error al decodificar PDF"}
      end
    rescue
      e -> 
        IO.puts("🔍 DEBUG: ❌ Error al guardar archivo: #{inspect(e)}")
        {:error, "Error al guardar PDF: #{inspect(e)}"}
    end
  end

  # Determinar el tipo de documento basado en el contenido
  defp determine_document_type(lines) do
    text = Enum.join(lines, " ")
    
    cond do
      String.contains?(text, "FACTURA") -> "FACTURA"
      String.contains?(text, "RECIBO DE INGRESO") -> "RECIBO DE INGRESO"
      true -> "FACTURA" # Por defecto
    end
  end

  # Parsear recibo de ingreso (dispatcher)
  defp parse_recibo_ingreso(lines) do
    document_type = determine_document_type(lines)
    
    case document_type do
      "FACTURA" -> parse_factura(lines)
      "RECIBO DE INGRESO" -> parse_recibo_ingreso_original(lines)
      _ -> parse_factura(lines) # Por defecto
    end
  end

  # Parsear factura específicamente
  defp parse_factura(lines) do
    try do
      parsed_data = %{
        tipo_documento: "FACTURA",
        cliente: extract_cliente_factura(lines),
        monto_total: extract_monto_total_factura(lines),
        numero_factura: extract_numero_factura(lines),
        fecha_factura: extract_fecha_factura(lines),
        forma_pago: "No especificado",
        concepto: "Venta de productos",
        balance_pendiente: "0.00",
        fecha_procesamiento: Date.utc_today(),
        items: extract_items_factura(lines),
        facturas: []
      }
      
      {:ok, parsed_data}
    rescue
      e -> {:error, "Error al parsear factura: #{inspect(e)}"}
    end
  end

  # Extraer cliente de factura
  defp extract_cliente_factura(lines) do
    lines
    |> Enum.find(fn line -> String.contains?(line, "Cliente:") end)
    |> case do
      nil -> "Cliente no encontrado"
      line -> 
        case Regex.run(~r/Cliente:\s*(.+)/, line) do
          [_, cliente] -> String.trim(cliente)
          _ -> "Cliente no encontrado"
        end
    end
  end

  # Extraer monto total de factura
  defp extract_monto_total_factura(lines) do
    lines
    |> Enum.find(fn line -> String.contains?(line, "Total") && !String.contains?(line, "ITBIS") && !String.contains?(line, "Precio Unit") end)
    |> case do
      nil -> "0.00"
      line -> 
        case Regex.run(~r/Total\s+([\d,]+\.?\d*)/, line) do
          [_, number] -> String.replace(number, ",", "")
          _ -> "0.00"
        end
    end
  end

  # Extraer número de factura
  defp extract_numero_factura(lines) do
    lines
    |> Enum.find(fn line -> String.contains?(line, "Factura:") end)
    |> case do
      nil -> "N/A"
      line -> 
        case Regex.run(~r/Factura:\s*(.+)/, line) do
          [_, numero] -> String.trim(numero)
          _ -> "N/A"
        end
    end
  end

  # Extraer fecha de factura
  defp extract_fecha_factura(lines) do
    lines
    |> Enum.find(fn line -> String.contains?(line, "Fecha:") end)
    |> case do
      nil -> "N/A"
      line -> 
        case Regex.run(~r/Fecha:\s*(.+)/, line) do
          [_, fecha] -> String.trim(fecha)
          _ -> "N/A"
        end
    end
  end

  # Extraer items de factura
  defp extract_items_factura(lines) do
    lines
    |> Enum.filter(fn line -> 
      # Buscar líneas que contengan productos (tienen números y no son totales)
      case Regex.run(~r/(.+)\s+(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)/, line) do
        [_, descripcion, cantidad, precio_unit, total] ->
          # Excluir líneas que son totales
          !String.contains?(descripcion, "Subtotal") && 
          !String.contains?(descripcion, "ITBIS") && 
          !String.contains?(descripcion, "Total")
        _ -> false
      end
    end)
    |> Enum.map(fn line ->
      case Regex.run(~r/(.+)\s+(\d+)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)/, line) do
        [_, descripcion, cantidad, precio_unit, total] ->
          %{
            descripcion: String.trim(descripcion),
            cantidad: cantidad,
            precio_unitario: String.replace(precio_unit, ",", ""),
            total: String.replace(total, ",", "")
          }
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # Parsear recibo de ingreso original (mantener compatibilidad)
  defp parse_recibo_ingreso_original(lines) do
    try do
      # Extraer "Recibido de"
      recibido_de = lines
                   |> Enum.find(fn line -> String.contains?(line, "Recibido de:") end)
                   |> case do
                     nil -> "No especificado"
                     line -> 
                       case Regex.run(~r/Recibido de:\s*(.+)/, line) do
                         [_, nombre] -> String.trim(nombre)
                         _ -> "No especificado"
                       end
                   end

      # Extraer monto
      monto = lines
              |> Enum.find(fn line -> String.contains?(line, "La Suma de:") end)
    |> case do
      nil -> "0.00"
      line -> 
                  case Regex.run(~r/La Suma de:\s*RD\$\s*([\d,]+\.?\d*)/, line) do
                    [_, amount] -> String.replace(amount, ",", "")
          _ -> "0.00"
        end
              end

      # Extraer forma de pago
      forma_pago = lines
                   |> Enum.find(fn line -> String.contains?(line, "Forma de Pago:") end)
                   |> case do
                     nil -> "No especificado"
                     line -> 
                       case Regex.run(~r/Forma de Pago:\s*(.+)/, line) do
                         [_, forma] -> String.trim(forma)
                         _ -> "No especificado"
                       end
                   end

      # Extraer concepto
      concepto = lines
                 |> Enum.find(fn line -> String.contains?(line, "Concepto:") end)
                 |> case do
                   nil -> "No especificado"
                   line -> 
                     case Regex.run(~r/Concepto:\s*(.+)/, line) do
                       [_, concept] -> String.trim(concept)
                       _ -> "No especificado"
                     end
                 end

      # Extraer facturas relacionadas
      facturas = lines
                 |> Enum.filter(fn line -> 
                   case Regex.run(~r/(\d+)\s+(\d{2}\/\d{2}\/\d{4})\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)/, line) do
                     [_, numero, fecha, valor, recibido, pendiente] ->
                       !String.contains?(line, "TOTALES")
                     _ -> false
                   end
                 end)
                 |> Enum.map(fn line ->
                   case Regex.run(~r/(\d+)\s+(\d{2}\/\d{2}\/\d{4})\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)/, line) do
                     [_, numero, fecha, valor, recibido, pendiente] ->
                       %{
                         numero: numero,
                         fecha: fecha,
                         valor: String.replace(valor, ",", ""),
                         recibido: String.replace(recibido, ",", ""),
                         pendiente: String.replace(pendiente, ",", "")
                       }
                     _ -> nil
                   end
                 end)
                 |> Enum.reject(&is_nil/1)

      # Calcular balance pendiente
      balance_pendiente = facturas
                          |> Enum.map(fn factura -> 
                            case Decimal.parse(factura.pendiente) do
                              {:ok, decimal} -> decimal
                              _ -> Decimal.new(0)
                            end
                          end)
                          |> Enum.reduce(Decimal.new(0), fn x, acc -> Decimal.add(acc, x) end)
                          |> Decimal.to_string()

      parsed_data = %{
        tipo_documento: "RECIBO DE INGRESO",
        cliente: recibido_de,
        monto_total: monto,
        forma_pago: forma_pago,
        concepto: concepto,
        balance_pendiente: balance_pendiente,
        fecha_procesamiento: Date.utc_today(),
        facturas: facturas,
        items: []
      }

      {:ok, parsed_data}
    rescue
      e -> {:error, "Error al parsear recibo de ingreso: #{inspect(e)}"}
    end
  end

  # Helper function for template
  def format_currency(value) when is_binary(value) do
    # Si es un string, intentar convertirlo a Decimal primero
    case Decimal.parse(value) do
      {decimal, _remainder} ->
        decimal
        |> Decimal.to_string()
        |> String.replace(".", ",")
      :error ->
        # Si no se puede parsear, devolver el valor original
        value
    end
  end
  
  def format_currency(%Decimal{} = decimal) do
    decimal
    |> Decimal.to_string()
    |> String.replace(".", ",")
  end
  
  def format_currency(value) do
    # Para otros tipos, convertir a string
    to_string(value)
  end

  # Generar vista de datos para la UI
  def generate_symasoft_view(parsed_data) do
    case parsed_data.tipo_documento do
      "FACTURA" ->
        %{
          header: %{
            title: "FACTURA",
            cliente: parsed_data.cliente,
            monto_total: parsed_data.monto_total,
            numero_factura: parsed_data.numero_factura,
            fecha_factura: parsed_data.fecha_factura,
            forma_pago: parsed_data.forma_pago,
            concepto: parsed_data.concepto
          },
          items: parsed_data.items,
          facturas: parsed_data.facturas, # Keep for compatibility if needed, but items is primary for FACTURA
          balance_pendiente: parsed_data.balance_pendiente,
          footer: %{
            cajero: "GAETANO PELLICCE",
            balance_final: parsed_data.balance_pendiente
          }
        }
      
      "RECIBO DE INGRESO" ->
    %{
      header: %{
        title: "RECIBO DE INGRESO RD$",
        cliente: parsed_data.cliente,
        monto_total: parsed_data.monto_total,
        forma_pago: parsed_data.forma_pago,
        concepto: parsed_data.concepto
      },
      facturas: parsed_data.facturas,
      balance_pendiente: parsed_data.balance_pendiente,
      footer: %{
        cajero: "GAETANO PELLICCE",
        balance_final: parsed_data.balance_pendiente
      }
    }
      
      _ ->
        # Por defecto, tratar como factura
        %{
          header: %{
            title: "DOCUMENTO",
            cliente: parsed_data.cliente,
            monto_total: parsed_data.monto_total,
            forma_pago: parsed_data.forma_pago,
            concepto: parsed_data.concepto
          },
          facturas: parsed_data.facturas,
          balance_pendiente: parsed_data.balance_pendiente,
          footer: %{
            cajero: "GAETANO PELLICCE",
            balance_final: parsed_data.balance_pendiente
          }
        }
    end
  end
end 