defmodule EvaaCrmWebGaepell.DocumentsLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Document, Fleet, MaintenanceTicket, Evaluation, ProductionOrder}
  import Path
  import Ecto.Query

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    current_user = EvaaCrmGaepell.Repo.get!(EvaaCrmGaepell.User, user_id)
    |> EvaaCrmGaepell.Repo.preload(:business)

    # Obtener camiones para el filtro
    trucks = Fleet.list_trucks() || []

    # Limpiar archivos mal formateados (solo una vez)
    clean_malformed_files()
    
    # Obtener archivos directamente de los tickets
    documents = load_files_from_tickets(current_user.business_id)
    
    # Calcular estadísticas
    stats = calculate_stats(documents)

    socket = socket
    |> allow_upload(:files, accept: ~w(.jpg .jpeg .png .gif .pdf .doc .docx .xls .xlsx), max_entries: 10, max_file_size: 10_000_000)
    |> assign(
      current_user: current_user,
      documents: documents,
      trucks: trucks,
      stats: stats,
      search_term: "",
      selected_category: "all",
      selected_truck: "all",
      sort_by: "date-desc",
      view_mode: "grid",
      show_upload_modal: false,
      show_preview_modal: false,
      selected_document: nil,
      selected_file_index: nil,
      show_edit_description_modal: false,
      editing_file_path: nil,
      editing_file_index: nil,
      editing_file_description: "",
      page_title: "Gestión de Documentos"
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    all_documents = load_files_from_tickets(socket.assigns.current_user.business_id)
    documents = filter_documents_by_search(all_documents, search)
    stats = calculate_stats(documents)
    {:noreply, assign(socket, documents: documents, search_term: search, stats: stats)}
  end

  @impl true
  def handle_event("change_view_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end



  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    all_documents = load_files_from_tickets(socket.assigns.current_user.business_id)
    documents = filter_documents_by_category(all_documents, category)
    stats = calculate_stats(documents)
    {:noreply, assign(socket, documents: documents, selected_category: category, stats: stats)}
  end

  @impl true
  def handle_event("filter_truck", %{"truck_id" => truck_id}, socket) do
    all_documents = load_files_from_tickets(socket.assigns.current_user.business_id)
    documents = filter_documents_by_truck(all_documents, truck_id)
    stats = calculate_stats(documents)
    {:noreply, assign(socket, documents: documents, selected_truck: truck_id, stats: stats)}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    documents = sort_documents(socket.assigns.documents, sort_by)
    {:noreply, assign(socket, documents: documents, sort_by: sort_by)}
  end

  @impl true
  def handle_event("change_view", %{"view_mode" => view_mode}, socket) do
    {:noreply, assign(socket, view_mode: view_mode)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    all_documents = load_files_from_tickets(socket.assigns.current_user.business_id)
    stats = calculate_stats(all_documents)
    {:noreply, assign(socket, 
      documents: all_documents, 
      search_term: "", 
      selected_category: "all", 
      selected_truck: "all",
      stats: stats
    )}
  end

  @impl true
  def handle_event("show_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_upload_modal: true)}
  end

  @impl true
  def handle_event("close_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_upload_modal: false)}
  end

  @impl true
  def handle_event("show_preview_modal", %{"document_id" => document_id}, socket) do
    document = find_document_by_id(socket.assigns.documents, document_id)
    
    # Seleccionar automáticamente el primer archivo si hay archivos disponibles
    initial_file_index = if length(document.files) > 0, do: 0, else: nil
    
    {:noreply, assign(socket, show_preview_modal: true, selected_document: document, selected_file_index: initial_file_index)}
  end

  @impl true
  def handle_event("close_preview_modal", _params, socket) do
    {:noreply, assign(socket, show_preview_modal: false, selected_document: nil, selected_file_index: nil)}
  end

  @impl true
  def handle_event("select_file", %{"index" => index}, socket) do
    file_index = String.to_integer(index)
    {:noreply, assign(socket, selected_file_index: file_index)}
  end

  @impl true
  def handle_event("next_file", _params, socket) do
    current_index = socket.assigns.selected_file_index || 0
    total_files = length(socket.assigns.selected_document.files)
    next_index = if current_index < total_files - 1, do: current_index + 1, else: 0
    {:noreply, assign(socket, selected_file_index: next_index)}
  end

  @impl true
  def handle_event("prev_file", _params, socket) do
    current_index = socket.assigns.selected_file_index || 0
    total_files = length(socket.assigns.selected_document.files)
    prev_index = if current_index > 0, do: current_index - 1, else: total_files - 1
    {:noreply, assign(socket, selected_file_index: prev_index)}
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    case key do
      "ArrowLeft" ->
        send(self(), {:prev_file, %{}})
        {:noreply, socket}
      "ArrowRight" ->
        send(self(), {:next_file, %{}})
        {:noreply, socket}
      "Escape" ->
        send(self(), {:close_preview_modal, %{}})
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:prev_file, _params}, socket) do
    current_index = socket.assigns.selected_file_index || 0
    total_files = length(socket.assigns.selected_document.files)
    prev_index = if current_index > 0, do: current_index - 1, else: total_files - 1
    {:noreply, assign(socket, selected_file_index: prev_index)}
  end

  @impl true
  def handle_info({:next_file, _params}, socket) do
    current_index = socket.assigns.selected_file_index || 0
    total_files = length(socket.assigns.selected_document.files)
    next_index = if current_index < total_files - 1, do: current_index + 1, else: 0
    {:noreply, assign(socket, selected_file_index: next_index)}
  end

  @impl true
  def handle_info({:close_preview_modal, _params}, socket) do
    {:noreply, assign(socket, show_preview_modal: false, selected_document: nil, selected_file_index: nil)}
  end

  @impl true
  def handle_event("delete_document", %{"document_id" => document_id}, socket) do
    document = Document.get_document!(document_id)
    
    case Document.delete_document(document) do
      {:ok, _} ->
        documents = Document.list_documents(socket.assigns.current_user.business_id)
        stats = Document.get_document_stats(socket.assigns.current_user.business_id)
        
        {:noreply, 
         socket
         |> assign(documents: documents, stats: stats)
         |> put_flash(:info, "Documento eliminado correctamente")}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error al eliminar el documento")}
    end
  end

  @impl true
  def handle_event("download_document", %{"document_id" => document_id}, socket) do
    # Buscar el documento en la lista en memoria usando el ID compuesto
    document = find_document_by_id(socket.assigns.documents, document_id)
    
    if document do
      # Crear un archivo ZIP con todos los archivos del documento
      case create_document_zip(document) do
        {:ok, zip_path, zip_filename} ->
          # Redirigir al usuario a la ruta de descarga
          {:noreply, 
           socket
           |> push_navigate(to: "/downloads/#{document_id}/#{zip_filename}")
           |> put_flash(:info, "Descarga iniciada para #{document.title}")}
        
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Error al crear el archivo ZIP: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Documento no encontrado")}
    end
  end

  @impl true
  def handle_event("share_document", %{"document_id" => document_id}, socket) do
    # Aquí implementarías la lógica de compartir
    {:noreply, put_flash(socket, :info, "Enlace copiado al portapapeles")}
  end

  @impl true
  def handle_event("upload_document", params, socket) do
    # Procesar la subida de documentos usando el mismo método que los tickets
    case process_document_upload(params, socket.assigns.current_user, socket) do
      {:ok, document} ->
        documents = Document.list_documents(socket.assigns.current_user.business_id)
        stats = Document.get_document_stats(socket.assigns.current_user.business_id)
        
        {:noreply, 
         socket
         |> assign(documents: documents, stats: stats, show_upload_modal: false)
         |> put_flash(:info, "Documento subido correctamente")}
      
      {:error, changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al subir el documento: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    documents = Document.list_documents(socket.assigns.current_user.business_id)
    {:noreply, assign(socket, 
      documents: documents, 
      search_term: "", 
      selected_category: "all", 
      selected_truck: "all"
    )}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl true
  def handle_event("edit_file_description", %{"file_path" => file_path, "file_index" => file_index}, socket) do
    # Obtener la descripción actual del archivo
    current_description = case socket.assigns.selected_document do
      nil -> ""
      document ->
        case Enum.at(document.files, String.to_integer(file_index)) do
          nil -> ""
          file -> file.description || ""
        end
    end

    {:noreply, assign(socket,
      show_edit_description_modal: true,
      editing_file_path: file_path,
      editing_file_index: String.to_integer(file_index),
      editing_file_description: current_description
    )}
  end

  @impl true
  def handle_event("close_edit_description_modal", _params, socket) do
    {:noreply, assign(socket,
      show_edit_description_modal: false,
      editing_file_path: nil,
      editing_file_index: nil,
      editing_file_description: ""
    )}
  end

  @impl true
  def handle_event("ignore", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_file_description", %{"file_description" => description}, socket) do
    case update_file_description_in_database(socket.assigns.editing_file_path, socket.assigns.editing_file_index, description, socket.assigns.selected_document) do
      {:ok, updated_document} ->
        # Actualizar la lista de documentos
        all_documents = load_files_from_tickets(socket.assigns.current_user.business_id)
        updated_documents = Enum.map(all_documents, fn doc ->
          if doc.id == updated_document.id do
            updated_document
          else
            doc
          end
        end)

        {:noreply, assign(socket,
          documents: updated_documents,
          selected_document: updated_document,
          show_edit_description_modal: false,
          editing_file_path: nil,
          editing_file_index: nil,
          editing_file_description: ""
        ) |> put_flash(:info, "Descripción actualizada correctamente")}

      {:error, reason} ->
        {:noreply, assign(socket,
          show_edit_description_modal: false,
          editing_file_path: nil,
          editing_file_index: nil,
          editing_file_description: ""
        ) |> put_flash(:error, "Error al actualizar la descripción: #{reason}")}
    end
  end

  # Función para procesar la subida de documentos
  defp process_document_upload(params, current_user, socket) do
    # Parsear tags
    tags = case params["tags"] do
      nil -> []
      tags_str when is_binary(tags_str) and byte_size(tags_str) > 0 ->
        tags_str
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(&1 != ""))
      _ -> []
    end

    # Parsear truck_id
    truck_id = case params["truck_id"] do
      nil -> nil
      "" -> nil
      id -> String.to_integer(id)
    end

    # Procesar archivos subidos
    uploaded_files = consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
      # Generar nombre único para el archivo
      timestamp = System.system_time(:millisecond)
      filename = "#{timestamp}_#{entry.client_name}"
      
      # Crear directorio si no existe
      upload_dir = "priv/static/uploads/documents/#{current_user.business_id}"
      File.mkdir_p!(upload_dir)
      
      # Ruta de destino
      dest_path = Path.join(upload_dir, filename)
      
      # Copiar archivo
      File.cp!(path, dest_path)
      
      # Retornar información del archivo
      %{
        size: entry.client_size,
        filename: filename,
        path: "/uploads/documents/#{current_user.business_id}/#{filename}",
        description: "",
        content_type: entry.client_type,
        original_name: entry.client_name
      }
    end)

    # Preparar los datos del documento
    document_attrs = %{
      title: params["title"],
      description: params["description"] || "",
      category: params["category"],
      tags: tags,
      business_id: current_user.business_id,
      truck_id: truck_id,
      total_files: length(uploaded_files),
      total_size: Enum.reduce(uploaded_files, 0, fn file, acc -> acc + file.size end),
      files: uploaded_files
    }

    # Crear el documento
    case Document.create_document(document_attrs, current_user.id) do
      {:ok, document} ->
        {:ok, document}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Función para sincronizar documentos desde tickets
  defp sync_documents_from_tickets(business_id) do
    try do
      # Obtener todos los tickets de mantenimiento con fotos
      maintenance_tickets = Fleet.list_maintenance_tickets()
      |> Enum.filter(fn ticket -> 
        ticket.damage_photos && length(ticket.damage_photos) > 0
      end)

      # Crear documentos para cada ticket con fotos
      Enum.each(maintenance_tickets, fn ticket ->
        # Verificar si ya existe un documento para este ticket
        existing_document = Document.get_documents_by_maintenance_ticket(ticket.id)
        |> List.first()

        if !existing_document do
          # Crear documento para las fotos del ticket
          document_attrs = %{
            title: "Fotos del Ticket #{ticket.id} - #{ticket.title}",
            description: "Fotografías asociadas al ticket de mantenimiento",
            category: "damage-photos",
            tags: ["ticket", "mantenimiento", "fotos"],
            business_id: business_id,
            maintenance_ticket_id: ticket.id,
            truck_id: ticket.truck_id,
            total_files: length(ticket.damage_photos),
            total_size: calculate_total_size(ticket.damage_photos),
            files: ticket.damage_photos
          }

          Document.create_document(document_attrs, ticket.created_by_id || 1)
        end
      end)
    rescue
      e ->
        # Log del error pero no fallar la carga de la página
        IO.puts("Error sincronizando documentos: #{inspect(e)}")
        :ok
    end
  end

  # Función para cargar archivos directamente desde tickets
  defp load_files_from_tickets(business_id) do
    # Obtener tickets de mantenimiento con fotos y preload truck
    maintenance_tickets = EvaaCrmGaepell.Repo.all(MaintenanceTicket)
    |> EvaaCrmGaepell.Repo.preload(:truck)
    
    # Filtrar tickets que tienen fotos
    maintenance_tickets_with_photos = Enum.filter(maintenance_tickets, fn ticket -> 
      has_photos = ticket.damage_photos && length(ticket.damage_photos) > 0
      
      has_photos
    end)
    
    maintenance_documents = Enum.map(maintenance_tickets_with_photos, fn ticket ->
      files = parse_files_from_ticket(ticket.damage_photos, "maintenance")
      total_size = calculate_files_size(files)
      
      %{
        id: "mt_#{ticket.id}",
        title: "Ticket de Mantenimiento ##{ticket.id}",
        description: ticket.title || "Ticket de mantenimiento",
        category: "maintenance",
        truck_id: ticket.truck_id,
        truck: ticket.truck,
        ticket_type: "maintenance",
        ticket_id: ticket.id,
        ticket_data: %{
          title: ticket.title,
          description: ticket.description,
          status: ticket.status,
          priority: ticket.priority,
          entry_date: ticket.entry_date,
          exit_date: ticket.exit_date,
          mileage: ticket.mileage,
          fuel_level: ticket.fuel_level,
          visible_damage: ticket.visible_damage,
          deliverer_name: ticket.deliverer_name,
          company_name: ticket.company_name,
          estimated_repair_cost: ticket.estimated_repair_cost,
          insurance_claim_number: ticket.insurance_claim_number,
          insurance_company: ticket.insurance_company
        },
        files: files,
        inserted_at: ticket.inserted_at,
        total_files: length(files),
        total_size: total_size,
        tags: [],
        created_by: nil
      }
    end)

    # Obtener evaluaciones con fotos y preload truck
    evaluations = EvaaCrmGaepell.Repo.all(Evaluation)
    |> EvaaCrmGaepell.Repo.preload(:truck)
    
    # Filtrar evaluaciones que tienen fotos
    evaluations_with_photos = Enum.filter(evaluations, fn evaluation -> 
      has_photos = evaluation.photos && length(evaluation.photos) > 0
      
      has_photos
    end)
    
    evaluation_documents = Enum.map(evaluations_with_photos, fn evaluation ->
      files = parse_files_from_ticket(evaluation.photos, "evaluation")
      total_size = calculate_files_size(files)
      
      %{
        id: "ev_#{evaluation.id}",
        title: "Evaluación ##{evaluation.id}",
        description: evaluation.title || "Evaluación de vehículo",
        category: "evaluation",
        truck_id: evaluation.truck_id,
        truck: evaluation.truck,
        ticket_type: "evaluation",
        ticket_id: evaluation.id,
        ticket_data: %{
          title: evaluation.title,
          description: evaluation.description,
          evaluation_type: evaluation.evaluation_type,
          evaluation_date: evaluation.evaluation_date,
          evaluated_by: evaluation.evaluated_by,
          driver_cedula: evaluation.driver_cedula,
          location: evaluation.location,
          damage_areas: evaluation.damage_areas,
          severity_level: evaluation.severity_level,
          estimated_cost: evaluation.estimated_cost,
          notes: evaluation.notes,
          status: evaluation.status,
          priority: evaluation.priority,
          entry_date: evaluation.entry_date,
          mileage: evaluation.mileage,
          fuel_level: evaluation.fuel_level,
          visible_damage: evaluation.visible_damage,
          deliverer_name: evaluation.deliverer_name,
          company_name: evaluation.company_name
        },
        files: files,
        inserted_at: evaluation.inserted_at,
        total_files: length(files),
        total_size: total_size,
        tags: [],
        created_by: nil
      }
    end)

    # Combinar todos los documentos
    all_documents = maintenance_documents ++ evaluation_documents
    
    all_documents
  end

  # Función para parsear archivos desde tickets
  defp parse_files_from_ticket(files, ticket_type) when is_list(files) do
    Enum.map(files, fn file ->
      file_map = case file do
        %{"path" => path, "original_name" => name, "size" => size, "description" => desc} ->
          %{
            path: path,
            original_name: name,
            size: size,
            content_type: get_content_type(path),
            description: desc
          }
        %{"path" => path, "original_name" => name, "size" => size} ->
          %{
            path: path,
            original_name: name,
            size: size,
            content_type: get_content_type(path),
            description: nil
          }
        %{"path" => path, "description" => desc} ->
          %{
            path: path,
            original_name: Path.basename(path),
            size: 0,
            content_type: get_content_type(path),
            description: desc
          }
        path when is_binary(path) ->
          # Verificar si es una ruta válida o un JSON string
          if String.starts_with?(path, "/uploads/") or String.starts_with?(path, "uploads/") do
            %{
              path: path,
              original_name: Path.basename(path),
              size: 0,
              content_type: get_content_type(path),
              description: nil
            }
          else
            # Intentar parsear como JSON
            case Jason.decode(path) do
              {:ok, %{"path" => json_path, "original_name" => name, "size" => size, "description" => desc}} ->
                %{
                  path: json_path,
                  original_name: name,
                  size: size,
                  content_type: get_content_type(json_path),
                  description: desc
                }
              {:ok, %{"path" => json_path, "original_name" => name, "size" => size}} ->
                %{
                  path: json_path,
                  original_name: name,
                  size: size,
                  content_type: get_content_type(json_path),
                  description: nil
                }
              {:ok, %{"path" => json_path, "description" => desc}} ->
                %{
                  path: json_path,
                  original_name: Path.basename(json_path),
                  size: 0,
                  content_type: get_content_type(json_path),
                  description: desc
                }
              {:ok, %{"path" => json_path}} ->
                %{
                  path: json_path,
                  original_name: Path.basename(json_path),
                  size: 0,
                  content_type: get_content_type(json_path),
                  description: nil
                }
              _ ->
                # Si no se puede parsear, usar placeholder
                %{
                  path: "/images/placeholder.jpg",
                  original_name: "archivo_corrupto",
                  size: 0,
                  content_type: "image/jpeg",
                  description: nil
                }
            end
          end
        json_string when is_binary(json_string) ->
          # Intentar parsear JSON si es una cadena
          case Jason.decode(json_string) do
            {:ok, %{"path" => path, "original_name" => name, "size" => size, "description" => desc}} ->
              %{
                path: path,
                original_name: name,
                size: size,
                content_type: get_content_type(path),
                description: desc
              }
            {:ok, %{"path" => path, "original_name" => name, "size" => size}} ->
              %{
                path: path,
                original_name: name,
                size: size,
                content_type: get_content_type(path),
                description: nil
              }
            {:ok, %{"path" => path, "description" => desc}} ->
              %{
                path: path,
                original_name: Path.basename(path),
                size: 0,
                content_type: get_content_type(path),
                description: desc
              }
            {:ok, %{"path" => path}} ->
              %{
                path: path,
                original_name: Path.basename(path),
                size: 0,
                content_type: get_content_type(path),
                description: nil
              }
            _ ->
              %{
                path: "/images/placeholder.jpg",
                original_name: "archivo_corrupto",
                size: 0,
                content_type: "image/jpeg",
                description: nil
              }
          end
        _ ->
          %{
            path: "/images/placeholder.jpg",
            original_name: "archivo_desconocido",
            size: 0,
            content_type: "image/jpeg",
            description: nil
          }
      end

      # Si el tamaño es 0 o nil, intentar calcularlo desde el archivo
      final_file = case file_map do
        %{size: size, path: path} when (is_nil(size) or size == 0) and is_binary(path) ->
          case get_file_size_from_path(path) do
            {:ok, file_size} -> 
              %{file_map | size: file_size}
            _ -> 
              file_map
          end
        _ -> file_map
      end

      final_file
    end)
  end

  defp parse_files_from_ticket(_, _), do: []

  # Función para obtener el tipo de contenido basado en la extensión
  defp get_content_type(path) when is_binary(path) do
    ext = Path.extname(path) |> String.downcase()
    
    case ext do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".bmp" -> "image/bmp"
      ".webp" -> "image/webp"
      ".pdf" -> "application/pdf"
      ".doc" -> "application/msword"
      ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ".xls" -> "application/vnd.ms-excel"
      ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      ".txt" -> "text/plain"
      ".csv" -> "text/csv"
      "" -> 
        # Si no hay extensión, intentar detectar por el nombre del archivo
        filename = Path.basename(path) |> String.downcase()
        cond do
          String.contains?(filename, "photo") or String.contains?(filename, "img") or String.contains?(filename, "image") -> "image/jpeg"
          String.contains?(filename, "doc") -> "application/msword"
          String.contains?(filename, "pdf") -> "application/pdf"
          true -> "application/octet-stream"
        end
      _ -> 
        # Para extensiones desconocidas, intentar detectar por el nombre
        filename = Path.basename(path) |> String.downcase()
        cond do
          String.contains?(filename, "photo") or String.contains?(filename, "img") or String.contains?(filename, "image") -> "image/jpeg"
          String.contains?(filename, "doc") -> "application/msword"
          String.contains?(filename, "pdf") -> "application/pdf"
          true -> "application/octet-stream"
        end
    end
  end
  defp get_content_type(_), do: "application/octet-stream"

  # Función para calcular el tamaño de los archivos
  defp calculate_files_size(files) when is_list(files) do
    Enum.reduce(files, 0, fn file, acc ->
      case file do
        %{"size" => size} when is_integer(size) and size > 0 -> 
          acc + size
        %{"size" => size} when is_integer(size) -> 
          # Si el tamaño es 0, intentar calcularlo desde el archivo
          case get_file_size_from_path(file["path"]) do
            {:ok, file_size} -> 
              acc + file_size
            _ -> 
              acc
          end
        %{"path" => path} when is_binary(path) ->
          # Intentar calcular el tamaño desde el archivo
          case get_file_size_from_path(path) do
            {:ok, file_size} -> 
              acc + file_size
            _ -> 
              acc
          end
        _ -> 
          acc
      end
    end)
  end
  defp calculate_files_size(files) do
    0
  end

  # Función para calcular estadísticas
  defp calculate_stats(documents) do
    total_files = Enum.reduce(documents, 0, fn doc, acc -> acc + doc.total_files end)
    
    categories = documents
    |> Enum.group_by(fn doc -> doc.category end)
    |> Enum.map(fn {category, docs} -> {category, length(docs)} end)
    |> Enum.into(%{})

    %{
      total_documents: length(documents),
      total_files: total_files,
      categories: categories
    }
  end

  # Funciones de filtrado
  defp filter_documents_by_search(documents, search) when search == "" or search == nil do
    documents
  end
  defp filter_documents_by_search(documents, search) do
    search_lower = String.downcase(search)
    Enum.filter(documents, fn doc ->
      String.contains?(String.downcase(doc.title), search_lower) or
      String.contains?(String.downcase(doc.description), search_lower)
    end)
  end

  defp filter_documents_by_category(documents, "all") do
    documents
  end
  defp filter_documents_by_category(documents, category) do
    Enum.filter(documents, fn doc -> doc.category == category end)
  end

  defp filter_documents_by_truck(documents, "all") do
    documents
  end
  defp filter_documents_by_truck(documents, truck_id) do
    Enum.filter(documents, fn doc -> to_string(doc.truck_id) == truck_id end)
  end

  # Función para ordenar documentos
  defp sort_documents(documents, sort_by) do
    case sort_by do
      "date-desc" -> Enum.sort_by(documents, & &1.inserted_at, {:desc, Date})
      "date-asc" -> Enum.sort_by(documents, & &1.inserted_at, {:asc, Date})
      "name-asc" -> Enum.sort_by(documents, & &1.title, {:asc, String})
      "name-desc" -> Enum.sort_by(documents, & &1.title, {:desc, String})
      "size-desc" -> Enum.sort_by(documents, & &1.total_size, {:desc, Integer})
      "size-asc" -> Enum.sort_by(documents, & &1.total_size, {:asc, Integer})
      _ -> documents
    end
  end

  # Funciones helper para el template
  defp format_file_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_000_000_000 -> "#{Float.round(bytes / 1_000_000_000, 1)} GB"
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)} KB"
      true -> "#{bytes} B"
    end
  end
  defp format_file_size(_), do: "0 B"

  defp format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  defp category_config do
    %{
      "maintenance" => %{
        icon: "🔧",
        name: "Mantenimiento",
        color: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      },
      "evaluation" => %{
        icon: "📋",
        name: "Evaluación",
        color: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      }
    }
  end

  # Función para obtener el tipo de archivo
  defp get_file_type(filename) when is_binary(filename) do
    case Path.extname(filename) do
      ".jpg" -> "image"
      ".jpeg" -> "image"
      ".png" -> "image"
      ".gif" -> "image"
      ".pdf" -> "pdf"
      ".doc" -> "document"
      ".docx" -> "document"
      ".xls" -> "spreadsheet"
      ".xlsx" -> "spreadsheet"
      _ -> "unknown"
    end
  end
  defp get_file_type(_), do: "unknown"

  # Función para obtener el icono del archivo
  defp get_file_icon(file_type) do
    case file_type do
      "image" -> "🖼️"
      "pdf" -> "📄"
      "document" -> "📝"
      "spreadsheet" -> "📊"
      _ -> "📎"
    end
  end

  # Función para encontrar documento por ID
  defp find_document_by_id(documents, document_id) do
    Enum.find(documents, fn doc -> doc.id == document_id end)
  end

  # Función para calcular el tamaño total de los archivos
  defp calculate_total_size(files) when is_list(files) do
    Enum.reduce(files, 0, fn file, acc ->
      case file do
        %{"size" => size} when is_integer(size) and size > 0 -> acc + size
        %{"path" => path} when is_binary(path) -> 
          # Si no hay tamaño o es 0, intentar calcularlo desde el archivo
          case get_file_size_from_path(path) do
            {:ok, file_size} -> acc + file_size
            _ -> acc
          end
        _ -> acc
      end
    end)
  end
  defp calculate_total_size(_), do: 0

  # Función para obtener el tamaño del archivo desde el sistema de archivos
  defp get_file_size_from_path(path) do
    try do
      # Convertir la ruta relativa a absoluta
      # Los archivos están en priv/static/uploads, no en priv/uploads
      clean_path = if String.starts_with?(path, "/") do
        String.slice(path, 1..-1//1)  # Remover el slash inicial
      else
        path
      end
      
      # Construir la ruta correcta para el directorio de uploads
      # Los archivos están en priv/static/uploads, no en priv/uploads
      full_path = Path.join([File.cwd!(), "apps", "evaa_crm_web_gaepell", "priv", "static", clean_path])
      
      case File.stat(full_path) do
        {:ok, %File.Stat{size: size}} -> 
          {:ok, size}
        {:error, reason} -> 
          # Intentar con la ruta alternativa (sin apps/)
          alt_path = Path.join([File.cwd!(), "priv", "static", clean_path])
          
          case File.stat(alt_path) do
            {:ok, %File.Stat{size: size}} -> 
              {:ok, size}
            {:error, alt_reason} -> 
              :error
          end
      end
    rescue
      error -> 
        :error
    end
  end

  # Función para ordenar documentos
  defp sort_documents(documents, sort_by) do
    case sort_by do
      "date-desc" -> Enum.sort_by(documents, & &1.inserted_at, {:desc, DateTime})
      "date-asc" -> Enum.sort_by(documents, & &1.inserted_at, {:asc, DateTime})
      "name-asc" -> Enum.sort_by(documents, & &1.title, :asc)
      "name-desc" -> Enum.sort_by(documents, & &1.title, :desc)
      "size-desc" -> Enum.sort_by(documents, & &1.total_size, :desc)
      "size-asc" -> Enum.sort_by(documents, & &1.total_size, :asc)
      _ -> documents
    end
  end

  # Configuración de categorías
  defp category_config do
    %{
      "truck-photos" => %{
        label: "Fotos del Camión",
        icon: "🚛",
        color: "bg-blue-500",
        description: "Fotografías del vehículo"
      },
      "damage-photos" => %{
        label: "Fotos de Daños",
        icon: "⚠️",
        color: "bg-red-500",
        description: "Evidencia de daños"
      },
      "purchase-orders" => %{
        label: "Órdenes de Compra",
        icon: "🛒",
        color: "bg-green-500",
        description: "Órdenes y requisiciones"
      },
      "quotes" => %{
        label: "Cotizaciones",
        icon: "💰",
        color: "bg-yellow-500",
        description: "Cotizaciones de servicios"
      },
      "invoices" => %{
        label: "Facturas",
        icon: "🧾",
        color: "bg-purple-500",
        description: "Facturas y comprobantes"
      },
      "insurance" => %{
        label: "Seguros",
        icon: "📄",
        color: "bg-indigo-500",
        description: "Pólizas de seguro"
      },
      "permits" => %{
        label: "Permisos",
        icon: "📋",
        color: "bg-orange-500",
        description: "Permisos y licencias"
      },
      "maintenance" => %{
        label: "Mantenimiento",
        icon: "🔧",
        color: "bg-teal-500",
        description: "Registros de mantenimiento"
      },
      "others" => %{
        label: "Otros",
        icon: "📎",
        color: "bg-gray-500",
        description: "Documentos diversos"
      }
    }
  end

  # Función para formatear fechas
  defp format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y %H:%M")
  end

  # Función para formatear tamaño de archivo
  defp format_file_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 1)} KB"
      true -> "#{bytes} Bytes"
    end
  end
  defp format_file_size(_), do: "0 Bytes"

  # Función para obtener el tipo de archivo
  defp get_file_type(filename) when is_binary(filename) do
    ext = Path.extname(filename) |> String.downcase()
    case ext do
      ".jpg" -> "image"
      ".jpeg" -> "image"
      ".png" -> "image"
      ".gif" -> "image"
      ".bmp" -> "image"
      ".webp" -> "image"
      ".pdf" -> "pdf"
      ".doc" -> "document"
      ".docx" -> "document"
      ".xls" -> "spreadsheet"
      ".xlsx" -> "spreadsheet"
      ".txt" -> "document"
      ".csv" -> "spreadsheet"
      "" -> 
        # Si no hay extensión, intentar detectar por el nombre del archivo
        filename_lower = String.downcase(filename)
        cond do
          String.contains?(filename_lower, "photo") or String.contains?(filename_lower, "img") or String.contains?(filename_lower, "image") -> "image"
          String.contains?(filename_lower, "doc") -> "document"
          String.contains?(filename_lower, "pdf") -> "pdf"
          true -> "other"
        end
      _ -> 
        # Para extensiones desconocidas, intentar detectar por el nombre
        filename_lower = String.downcase(filename)
        cond do
          String.contains?(filename_lower, "photo") or String.contains?(filename_lower, "img") or String.contains?(filename_lower, "image") -> "image"
          String.contains?(filename_lower, "doc") -> "document"
          String.contains?(filename_lower, "pdf") -> "pdf"
          true -> "other"
        end
    end
  end
  defp get_file_type(_), do: "other"

  # Función para obtener el icono del tipo de archivo
  defp get_file_icon(file_type) do
    case file_type do
      "image" -> "🖼️"
      "pdf" -> "📄"
      "document" -> "📝"
      "spreadsheet" -> "📊"
      _ -> "📎"
    end
  end

  # Función para limpiar archivos mal formateados en la base de datos
  defp clean_malformed_files do
    # Limpiar tickets de mantenimiento
    maintenance_tickets = EvaaCrmGaepell.Repo.all(MaintenanceTicket)
    |> Enum.filter(fn ticket -> 
      ticket.damage_photos && length(ticket.damage_photos) > 0
    end)

    Enum.each(maintenance_tickets, fn ticket ->
      cleaned_photos = Enum.map(ticket.damage_photos, fn photo ->
        case photo do
          path when is_binary(path) ->
            if String.starts_with?(path, "/uploads/") or String.starts_with?(path, "uploads/") do
              # Es una ruta simple, mantenerla como está
              path
            else
              # Intentar parsear como JSON para preservar metadatos
              case Jason.decode(path) do
                {:ok, %{"path" => json_path, "description" => desc, "original_name" => name, "size" => size, "content_type" => content_type}} ->
                  # Preservar todos los metadatos
                  Jason.encode!(%{
                    "path" => json_path,
                    "description" => desc,
                    "original_name" => name,
                    "size" => size,
                    "content_type" => content_type
                  })
                {:ok, %{"path" => json_path, "description" => desc, "original_name" => name}} ->
                  # Preservar descripción y nombre original
                  Jason.encode!(%{
                    "path" => json_path,
                    "description" => desc,
                    "original_name" => name
                  })
                {:ok, %{"path" => json_path, "description" => desc}} ->
                  # Preservar descripción
                  Jason.encode!(%{
                    "path" => json_path,
                    "description" => desc
                  })
                {:ok, %{"path" => json_path}} ->
                  # Solo extraer la ruta si no hay metadatos
                  json_path
                _ -> nil
              end
            end
          _ -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

      if cleaned_photos != ticket.damage_photos do
        # Actualizar el ticket con las fotos limpias
        EvaaCrmGaepell.Repo.update_all(
          from(t in MaintenanceTicket, where: t.id == ^ticket.id),
          set: [damage_photos: cleaned_photos]
        )
      end
    end)

    # Limpiar evaluaciones
    evaluations = EvaaCrmGaepell.Repo.all(Evaluation)
    |> Enum.filter(fn evaluation -> 
      evaluation.photos && length(evaluation.photos) > 0
    end)

    Enum.each(evaluations, fn evaluation ->
      cleaned_photos = Enum.map(evaluation.photos, fn photo ->
        case photo do
          path when is_binary(path) ->
            if String.starts_with?(path, "/uploads/") or String.starts_with?(path, "uploads/") do
              # Es una ruta simple, mantenerla como está
              path
            else
              # Intentar parsear como JSON para preservar metadatos
              case Jason.decode(path) do
                {:ok, %{"path" => json_path, "description" => desc, "original_name" => name, "size" => size, "content_type" => content_type}} ->
                  # Preservar todos los metadatos
                  Jason.encode!(%{
                    "path" => json_path,
                    "description" => desc,
                    "original_name" => name,
                    "size" => size,
                    "content_type" => content_type
                  })
                {:ok, %{"path" => json_path, "description" => desc, "original_name" => name}} ->
                  # Preservar descripción y nombre original
                  Jason.encode!(%{
                    "path" => json_path,
                    "description" => desc,
                    "original_name" => name
                  })
                {:ok, %{"path" => json_path, "description" => desc}} ->
                  # Preservar descripción
                  Jason.encode!(%{
                    "path" => json_path,
                    "description" => desc
                  })
                {:ok, %{"path" => json_path}} ->
                  # Solo extraer la ruta si no hay metadatos
                  json_path
                _ -> nil
              end
            end
          _ -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

      if cleaned_photos != evaluation.photos do
        # Actualizar la evaluación con las fotos limpias
        EvaaCrmGaepell.Repo.update_all(
          from(e in Evaluation, where: e.id == ^evaluation.id),
          set: [photos: cleaned_photos]
        )
      end
    end)
  end

  # Función para crear un archivo ZIP con todos los archivos de un documento
  defp create_document_zip(document) do
    try do
      # Crear directorio temporal para el ZIP
      temp_dir = Path.join(System.tmp_dir!(), "document_zip_#{document.id}")
      File.mkdir_p!(temp_dir)
      
      # Crear el archivo ZIP (usar ID en lugar del título para evitar caracteres especiales)
      zip_filename = "document_#{document.id}_#{Date.utc_today()}.zip"
      zip_path = Path.join(temp_dir, zip_filename)
      
      # Usar :zip para crear el archivo ZIP
      files_to_zip = Enum.map(document.files, fn file ->
        # Construir la ruta completa del archivo
        file_path = if String.starts_with?(file.path, "/") do
          Path.join([File.cwd!(), "priv", "static", String.slice(file.path, 1..-1//1)])
        else
          Path.join([File.cwd!(), "priv", "static", file.path])
        end
        
        # Normalizar la ruta para que funcione con :zip en Windows
        file_path = String.replace(file_path, "\\", "/")
        
        # Debug logging
        # IO.inspect("Checking file: #{file.original_name}", label: "ZIP Creation")
        # IO.inspect("File path: #{file_path}", label: "ZIP Creation")
        # IO.inspect("File exists: #{File.exists?(file_path)}", label: "ZIP Creation")
        
        # Verificar que el archivo existe
        if File.exists?(file_path) do
          {file_path, file.original_name}
        else
          nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
      
      if length(files_to_zip) > 0 do
        # Debug logging
        # IO.inspect("Creating ZIP with #{length(files_to_zip)} files", label: "ZIP Creation")
        # IO.inspect("ZIP path: #{zip_path}", label: "ZIP Creation")
        # IO.inspect("Files to zip: #{inspect(files_to_zip)}", label: "ZIP Creation")
        
        # Normalizar la ruta del ZIP para que funcione con :zip en Windows
        zip_path_normalized = String.replace(zip_path, "\\", "/")
        
        # Crear el ZIP
        case :zip.create(zip_path_normalized, files_to_zip) do
          :ok ->
            # IO.inspect("ZIP created successfully at: #{zip_path_normalized}", label: "ZIP Creation")
            # IO.inspect("ZIP file exists: #{File.exists?(zip_path)}", label: "ZIP Creation")
            {:ok, zip_path, zip_filename}
          {:error, reason} ->
            # IO.inspect("ZIP creation failed: #{inspect(reason)}", label: "ZIP Creation")
            {:error, "Error al crear el archivo ZIP: #{inspect(reason)}"}
        end
      else
        {:error, "No se encontraron archivos válidos para comprimir"}
      end
    rescue
      error -> 
        # IO.inspect("Error creating ZIP: #{inspect(error)}", label: "ZIP Creation")
        {:error, "Error al crear el archivo ZIP"}
    end
  end

  # Función para verificar que los archivos físicos existan
  defp debug_file_existence(files) when is_list(files) do
    # IO.inspect("=== DEBUG: Checking file existence ===", label: "DEBUG")
    
    Enum.each(files, fn file ->
      case file do
        %{"path" => path} when is_binary(path) ->
          clean_path = if String.starts_with?(path, "/") do
            String.slice(path, 1..-1//1)
          else
            path
          end
          
          # Los archivos están en priv/static/uploads, no en priv/uploads
          full_path = Path.join([File.cwd!(), "apps", "evaa_crm_web_gaepell", "priv", "static", clean_path])
          alt_path = Path.join([File.cwd!(), "priv", "static", clean_path])
          
          exists_full = File.exists?(full_path)
          exists_alt = File.exists?(alt_path)
          
          # IO.inspect("File #{path}:", label: "DEBUG")
          # IO.inspect("  Full path: #{full_path} - Exists: #{exists_full}", label: "DEBUG")
          # IO.inspect("  Alt path: #{alt_path} - Exists: #{exists_alt}", label: "DEBUG")
          
          if exists_full or exists_alt do
            actual_path = if exists_full, do: full_path, else: alt_path
            case File.stat(actual_path) do
              {:ok, %File.Stat{size: size}} -> 
                # IO.inspect("  Actual size: #{size} bytes", label: "DEBUG")
                :ok
              {:error, reason} -> 
                # IO.inspect("  Stat error: #{inspect(reason)}", label: "DEBUG")
                :ok
            end
          end
        _ -> 
          # IO.inspect("File format not recognized for existence check: #{inspect(file)}", label: "DEBUG")
          :ok
      end
    end)
  end
  defp debug_file_existence(_), do: :ok

  # Función para actualizar la descripción de un archivo en la base de datos
  defp update_file_description_in_database(file_path, file_index, description, selected_document) do
    case selected_document do
      %{ticket_type: "maintenance", ticket_id: ticket_id} ->
        update_maintenance_ticket_file_description(ticket_id, file_path, file_index, description)
      %{ticket_type: "evaluation", ticket_id: ticket_id} ->
        update_evaluation_file_description(ticket_id, file_path, file_index, description)
      _ ->
        {:error, "Tipo de documento no soportado"}
    end
  end

  # Actualizar descripción en ticket de mantenimiento
  defp update_maintenance_ticket_file_description(ticket_id, file_path, file_index, description) do
    case EvaaCrmGaepell.Repo.get(MaintenanceTicket, ticket_id) do
      nil ->
        {:error, "Ticket de mantenimiento no encontrado"}
      
      ticket ->
        # Actualizar el archivo específico en damage_photos
        updated_photos = Enum.with_index(ticket.damage_photos)
        |> Enum.map(fn {photo, index} ->
          if index == file_index do
            case photo do
              path when is_binary(path) ->
                # Verificar si es una ruta simple
                if String.starts_with?(path, "/uploads/") or String.starts_with?(path, "uploads/") do
                  # Es una ruta simple, convertir a JSON con descripción
                  Jason.encode!(%{
                    "path" => path,
                    "description" => description,
                    "original_name" => Path.basename(path)
                  })
                else
                  # Intentar parsear como JSON
                  case Jason.decode(path) do
                    {:ok, photo_data} ->
                      updated_data = Map.put(photo_data, "description", description)
                      Jason.encode!(updated_data)
                    _ ->
                      # Si no se puede parsear, crear nuevo JSON
                      Jason.encode!(%{
                        "path" => file_path,
                        "description" => description,
                        "original_name" => Path.basename(file_path)
                      })
                  end
                end
              _ ->
                photo
            end
          else
            photo
          end
        end)

        # Actualizar en la base de datos
        case EvaaCrmGaepell.Repo.update(Ecto.Changeset.change(ticket, damage_photos: updated_photos)) do
          {:ok, updated_ticket} ->
            # Precargar la asociación del truck
            updated_ticket_with_truck = EvaaCrmGaepell.Repo.preload(updated_ticket, :truck)
            
            # Recrear el documento con los datos actualizados
            updated_document = %{
              id: "mt_#{updated_ticket_with_truck.id}",
              title: updated_ticket_with_truck.title || "Ticket de Mantenimiento",
              description: updated_ticket_with_truck.description || "Documentos de mantenimiento",
              category: "maintenance",
              truck_id: updated_ticket_with_truck.truck_id,
              truck: updated_ticket_with_truck.truck,
              ticket_type: "maintenance",
              ticket_id: updated_ticket_with_truck.id,
              ticket_data: %{
                title: updated_ticket_with_truck.title,
                description: updated_ticket_with_truck.description,
                status: updated_ticket_with_truck.status,
                priority: updated_ticket_with_truck.priority,
                entry_date: updated_ticket_with_truck.entry_date,
                exit_date: updated_ticket_with_truck.exit_date,
                mileage: updated_ticket_with_truck.mileage,
                fuel_level: updated_ticket_with_truck.fuel_level,
                visible_damage: updated_ticket_with_truck.visible_damage,
                deliverer_name: updated_ticket_with_truck.deliverer_name,
                company_name: updated_ticket_with_truck.company_name,
                estimated_repair_cost: updated_ticket_with_truck.estimated_repair_cost,
                insurance_claim_number: updated_ticket_with_truck.insurance_claim_number,
                insurance_company: updated_ticket_with_truck.insurance_company
              },
              files: parse_files_from_ticket(updated_photos, "maintenance"),
              inserted_at: updated_ticket_with_truck.inserted_at,
              total_files: length(updated_photos),
              total_size: calculate_total_size(updated_photos),
              tags: [],
              created_by: nil
            }
            {:ok, updated_document}
          
          {:error, changeset} ->
            {:error, "Error al actualizar el ticket: #{inspect(changeset.errors)}"}
        end
    end
  end

  # Actualizar descripción en evaluación
  defp update_evaluation_file_description(evaluation_id, file_path, file_index, description) do
    case EvaaCrmGaepell.Repo.get(Evaluation, evaluation_id) do
      nil ->
        {:error, "Evaluación no encontrada"}
      
      evaluation ->
        # Actualizar el archivo específico en photos
        updated_photos = Enum.with_index(evaluation.photos)
        |> Enum.map(fn {photo, index} ->
          if index == file_index do
            case photo do
              path when is_binary(path) ->
                # Verificar si es una ruta simple
                if String.starts_with?(path, "/uploads/") or String.starts_with?(path, "uploads/") do
                  # Es una ruta simple, convertir a JSON con descripción
                  Jason.encode!(%{
                    "path" => path,
                    "description" => description,
                    "original_name" => Path.basename(path)
                  })
                else
                  # Intentar parsear como JSON
                  case Jason.decode(path) do
                    {:ok, photo_data} ->
                      updated_data = Map.put(photo_data, "description", description)
                      Jason.encode!(updated_data)
                    _ ->
                      # Si no se puede parsear, crear nuevo JSON
                      Jason.encode!(%{
                        "path" => file_path,
                        "description" => description,
                        "original_name" => Path.basename(file_path)
                      })
                  end
                end
              _ ->
                photo
            end
          else
            photo
          end
        end)

        # Actualizar en la base de datos
        case EvaaCrmGaepell.Repo.update(Ecto.Changeset.change(evaluation, photos: updated_photos)) do
          {:ok, updated_evaluation} ->
            # Precargar la asociación del truck
            updated_evaluation_with_truck = EvaaCrmGaepell.Repo.preload(updated_evaluation, :truck)
            
            # Recrear el documento con los datos actualizados
            updated_document = %{
              id: "ev_#{updated_evaluation_with_truck.id}",
              title: updated_evaluation_with_truck.title || "Evaluación de Vehículo",
              description: updated_evaluation_with_truck.description || "Documentos de evaluación",
              category: "evaluation",
              truck_id: updated_evaluation_with_truck.truck_id,
              truck: updated_evaluation_with_truck.truck,
              ticket_type: "evaluation",
              ticket_id: updated_evaluation_with_truck.id,
              ticket_data: %{
                title: updated_evaluation_with_truck.title,
                description: updated_evaluation_with_truck.description,
                evaluation_type: updated_evaluation_with_truck.evaluation_type,
                evaluation_date: updated_evaluation_with_truck.evaluation_date,
                evaluated_by: updated_evaluation_with_truck.evaluated_by,
                driver_cedula: updated_evaluation_with_truck.driver_cedula,
                location: updated_evaluation_with_truck.location,
                damage_areas: updated_evaluation_with_truck.damage_areas,
                severity_level: updated_evaluation_with_truck.severity_level,
                estimated_cost: updated_evaluation_with_truck.estimated_cost,
                notes: updated_evaluation_with_truck.notes,
                status: updated_evaluation_with_truck.status,
                priority: updated_evaluation_with_truck.priority,
                entry_date: updated_evaluation_with_truck.entry_date,
                mileage: updated_evaluation_with_truck.mileage,
                fuel_level: updated_evaluation_with_truck.fuel_level,
                visible_damage: updated_evaluation_with_truck.visible_damage,
                deliverer_name: updated_evaluation_with_truck.deliverer_name,
                company_name: updated_evaluation_with_truck.company_name
              },
              files: parse_files_from_ticket(updated_photos, "evaluation"),
              inserted_at: updated_evaluation_with_truck.inserted_at,
              total_files: length(updated_photos),
              total_size: calculate_total_size(updated_photos),
              tags: [],
              created_by: nil
            }
            {:ok, updated_document}
          
          {:error, changeset} ->
            {:error, "Error al actualizar la evaluación: #{inspect(changeset.errors)}"}
        end
    end
  end

  # Función auxiliar para calcular el tamaño total
  defp calculate_total_size(files) when is_list(files) do
    Enum.reduce(files, 0, fn file, acc ->
      case file do
        path when is_binary(path) ->
          acc
        json_string when is_binary(json_string) ->
          case Jason.decode(json_string) do
            {:ok, %{"size" => size}} when is_integer(size) -> acc + size
            _ -> acc
          end
        _ -> acc
      end
    end)
  end
end
