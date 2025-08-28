defmodule EvaaCrmWebGaepell.TicketDetailLive do
  use EvaaCrmWebGaepell, :live_view

  alias EvaaCrmGaepell.{MaintenanceTicket, Evaluation, Truck, User, ActivityLog}
  alias EvaaCrmGaepell.Repo
  import Ecto.Query
  import Phoenix.LiveView.Helpers
  import Path
  import Jason

  @impl true
  def mount(%{"id" => ticket_id}, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    
    # Try to find maintenance ticket first, then evaluation
    {ticket, ticket_type} = case Repo.get(MaintenanceTicket, ticket_id) do
      nil -> 
        case Repo.get(Evaluation, ticket_id) do
          nil -> {nil, nil}
          evaluation -> 
            evaluation = evaluation 
              |> Repo.preload([:truck, :specialist, :business])
            {evaluation, "evaluation"}
        end
      maintenance_ticket -> 
        maintenance_ticket = maintenance_ticket 
          |> Repo.preload([:truck, :specialist, :business])
        {maintenance_ticket, "maintenance"}
    end

    if ticket do
      # Debug logging
      IO.inspect(ticket, label: "[DEBUG] Ticket loaded")
      IO.inspect(ticket_type, label: "[DEBUG] Ticket type")
      if ticket_type == "evaluation" do
        IO.inspect(ticket.damage_areas, label: "[DEBUG] Damage areas in ticket")
        IO.inspect(ticket.description, label: "[DEBUG] Description in ticket")
        IO.inspect(ticket.severity_level, label: "[DEBUG] Severity level in ticket")
        IO.inspect(ticket.estimated_cost, label: "[DEBUG] Estimated cost in ticket")
      end
      
      # Load related data
      truck = ticket.truck |> Repo.preload([:business])
      activity_logs = get_activity_logs(ticket, ticket_type)
      comments = get_comments(ticket, ticket_type)
      
      socket = 
        socket
        |> assign(
          current_user: current_user,
          ticket: ticket,
          ticket_type: ticket_type,
          truck: truck,
          activity_logs: activity_logs,
          comments: comments,
          new_comment: "",
          new_status: "",
          is_editing: false,
          show_edit_modal: false,
          show_maintenance_form_edit_modal: false,
          show_damage_info_edit_modal: false,
          show_edit_file_description_modal: false,
          editing_file_index: nil,
          editing_file_name: "",
          editing_file_path: "",
          editing_file_description: "",
          show_convert_modal: false,
      show_status_modal: false,
          is_updating_progress: false,
          page_title: "Detalles del Ticket - #{ticket.id}",
          show_upload_modal: false,
          file_descriptions: %{},
          show_delete_modal: false,
          file_to_delete: nil,
          is_adding_comment: false,
          is_updating_status: false,
          is_uploading_files: false,
          show_checkout_modal: false,
          checkout_file_descriptions: %{},
          checkout_signature: ""
        )

        |> allow_upload(:ticket_attachments, 
          accept: ~w(.jpg .jpeg .png .gif .pdf .doc .docx .txt .xlsx .xls),
          max_entries: 10,
          max_file_size: 10_000_000,  # 10MB
          auto_upload: true
        )
        # |> allow_upload(:checkout_photos, 
        #   accept: ~w(.jpg .jpeg .png .gif .pdf .doc .docx .txt .xlsx .xls),
        #   max_entries: 10,
        #   max_file_size: 10_000_000,  # 10MB
        #   auto_upload: true
        # )

      {:ok, socket}
    else
      {:ok, 
       socket
       |> assign(:ticket, nil)
       |> assign(:ticket_type, nil)
       |> assign(:page_title, "Ticket no encontrado")
       |> put_flash(:error, "El ticket solicitado no existe")}
    end
  end

  @impl true
  def handle_event("back", _params, socket) do
    case socket.assigns.ticket_type do
      "maintenance" -> {:noreply, push_navigate(socket, to: "/tickets?tab=maintenance")}
      "evaluation" -> {:noreply, push_navigate(socket, to: "/tickets?tab=evaluation")}
      "orders" -> {:noreply, push_navigate(socket, to: "/tickets?tab=production")}
      _ -> {:noreply, push_navigate(socket, to: "/tickets")}
    end
  end

  @impl true
  def handle_event("show_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_modal, true)}
  end

  @impl true
  def handle_event("show_maintenance_form_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_maintenance_form_edit_modal, true)}
  end

  @impl true
  def handle_event("show_damage_info_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_damage_info_edit_modal, true)}
  end

  @impl true
  def handle_event("close_damage_info_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_damage_info_edit_modal, false)}
  end

  @impl true
  def handle_event("show_edit_file_description_modal", %{"index" => index, "file-path" => file_path, "current-description" => current_description}, socket) do
    # Get file info to display the name
    photos = get_photos(socket.assigns.ticket, socket.assigns.ticket_type) || []
    file_info = case Enum.at(photos, String.to_integer(index)) do
      nil -> %{original_name: "Archivo desconocido"}
      photo -> 
        try do
          parse_file_info(photo)
        rescue
          _ -> %{original_name: "Archivo desconocido"}
        end
    end

    {:noreply, 
     socket
     |> assign(:show_edit_file_description_modal, true)
     |> assign(:editing_file_index, index)
     |> assign(:editing_file_name, file_info.original_name)
     |> assign(:editing_file_path, file_path)
     |> assign(:editing_file_description, current_description)}
  end

  @impl true
  def handle_event("close_edit_file_description_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_file_description_modal, false)}
  end

  @impl true
  def handle_event("show_convert_modal", _params, socket) do
    {:noreply, assign(socket, :show_convert_modal, true)}
  end

  @impl true
  def handle_event("close_convert_modal", _params, socket) do
    {:noreply, assign(socket, :show_convert_modal, false)}
  end

  @impl true
  def handle_event("show_status_modal", _params, socket) do
    {:noreply, assign(socket, :show_status_modal, true)}
  end

  @impl true
  def handle_event("hide_status_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_status_modal, false)
     |> assign(:new_status, "")}
  end

  @impl true
  def handle_event("convert_to_maintenance", _params, socket) do
    # Convertir la evaluación a ticket de mantenimiento
    case Evaluation.convert_to_maintenance_ticket(socket.assigns.ticket, socket.assigns.current_user.id) do
      {:ok, maintenance_ticket} ->
        {:noreply,
          socket
          |> assign(:show_convert_modal, false)
          |> put_flash(:info, "Evaluación convertida a ticket de mantenimiento exitosamente")
          |> push_navigate(to: "/maintenance/#{maintenance_ticket.id}")}
      
      {:error, changeset} ->
        {:noreply,
          socket
          |> put_flash(:error, "Error al convertir la evaluación: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("update_file_description", %{"file_description" => description, "file_index" => index, "file_path" => file_path}, socket) do
    # Update the file description in the photos array
    photos = get_photos(socket.assigns.ticket, socket.assigns.ticket_type) || []
    index_int = String.to_integer(index)
    
    updated_photos = case Enum.at(photos, index_int) do
      nil -> photos
      photo ->
        # Parse the current photo info
        file_info = try do
          parse_file_info(photo)
        rescue
          _ -> %{path: to_string(photo), description: nil, original_name: "archivo"}
        end
        
        # Update the description
        updated_file_info = %{file_info | description: description}
        
        # Convert back to JSON string
        updated_photo = Jason.encode!(updated_file_info)
        
        # Replace the photo in the array
        List.replace_at(photos, index_int, updated_photo)
    end

    # Update the ticket with the new photos
    update_params = %{"photos" => updated_photos}
    
    case update_ticket_photos(socket.assigns.ticket, updated_photos, socket.assigns.ticket_type) do
      {:ok, updated_ticket} ->
        # Add activity log
        add_activity_log(updated_ticket, "actualizó la descripción de un archivo adjunto", socket.assigns.current_user, socket.assigns.ticket_type)
        
        # Reload the ticket with preloads
        reloaded_ticket = updated_ticket |> Repo.preload([:truck, :specialist, :business])
        
        {:noreply, 
         socket
         |> assign(:ticket, reloaded_ticket)
         |> assign(:show_edit_file_description_modal, false)
         |> put_flash(:info, "Descripción del archivo actualizada exitosamente")}
      
      {:error, _changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al actualizar la descripción del archivo")}
    end
  end

  @impl true
  def handle_event("close_maintenance_form_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_maintenance_form_edit_modal, false)}
  end

  @impl true
  def handle_event("update_maintenance_form", params, socket) do
    case socket.assigns.ticket_type do
      "maintenance" ->
        # Parse maintenance areas from checkboxes
        maintenance_areas = case params["maintenance_areas"] do
          nil -> []
          areas when is_list(areas) -> areas
          _ -> []
        end

        # Build the evaluation_notes string with maintenance type and areas
        evaluation_notes = "Tipo: #{params["maintenance_type"] || "preventive"}\nÁreas: #{Enum.join(maintenance_areas, ", ")}"

        # Prepare update params
        update_params = %{
          "priority" => params["priority"] || "medium",
          "description" => params["description"] || "",
          "visible_damage" => params["visible_damage"] || "",
          "fuel_level" => params["fuel_level"] || "empty",
          "mileage" => parse_integer(params["mileage"]),
          "evaluation_notes" => evaluation_notes,
          "deliverer_name" => params["delivered_by"] || "",
          "document_number" => params["driver_cedula"] || "",
          "estimated_repair_cost" => parse_decimal(params["estimated_cost"])
        }

        case MaintenanceTicket.update_ticket(socket.assigns.ticket, update_params, socket.assigns.current_user.id) do
          {:ok, updated_ticket} ->
            # Reload the ticket with preloads
            reloaded_ticket = updated_ticket |> Repo.preload([:truck, :specialist, :business])
            
            {:noreply, 
             socket
             |> assign(:ticket, reloaded_ticket)
             |> assign(:show_maintenance_form_edit_modal, false)
             |> put_flash(:info, "Formulario de mantenimiento actualizado exitosamente")}
          
          {:error, _changeset} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al actualizar el formulario de mantenimiento")}
        end
      
      _ ->
        {:noreply, 
         socket
         |> put_flash(:error, "Solo se puede editar formularios de mantenimiento")}
    end
  end

  @impl true
  def handle_event("update_damage_info", params, socket) do
    case socket.assigns.ticket_type do
      "evaluation" ->
        # Parse damage areas from checkboxes
        damage_areas = case params["damage_areas"] do
          nil -> []
          areas when is_list(areas) -> areas
          _ -> []
        end

        # Prepare update params
        update_params = %{
          "evaluation_type" => params["evaluation_type"] || "otro",
          "severity_level" => params["severity_level"] || "medium",
          "estimated_cost" => parse_decimal(params["estimated_cost"]),
          "damage_areas" => damage_areas,
          "description" => params["damage_description"] || "",
          "notes" => params["notes"] || ""
        }

        case Evaluation.update_evaluation(socket.assigns.ticket, update_params, socket.assigns.current_user.id) do
          {:ok, updated_ticket} ->
            # Reload the ticket with preloads
            reloaded_ticket = updated_ticket |> Repo.preload([:truck, :specialist, :business])
            
            {:noreply, 
             socket
             |> assign(:ticket, reloaded_ticket)
             |> assign(:show_damage_info_edit_modal, false)
             |> put_flash(:info, "Información de daños actualizada exitosamente")}
          
          {:error, _changeset} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al actualizar la información de daños")}
        end
      
      _ ->
        {:noreply, 
         socket
         |> put_flash(:error, "Solo se puede editar información de daños en evaluaciones")}
    end
  end

  @impl true
  def handle_event("close_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_modal, false)}
  end

  @impl true
  def handle_event("update_progress", %{"progress" => progress}, socket) do
    if socket.assigns.ticket_type == "maintenance" do
      progress = String.to_integer(progress)
      user_id = socket.assigns.current_user.id
      
      case update_maintenance_progress(socket.assigns.ticket, progress, user_id) do
        {:ok, updated_ticket} ->
          flash_message = if progress == 100 do
            "Progreso actualizado a #{progress}% - Estado cambiado automáticamente a 'Completada'"
          else
            "Progreso actualizado a #{progress}%"
          end
          
          {:noreply, 
           socket
           |> assign(:ticket, updated_ticket)
           |> put_flash(:info, flash_message)}
          
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al actualizar progreso")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_status", %{"status" => status}, socket) do
    user_id = socket.assigns.current_user.id
    case update_ticket_status(socket.assigns.ticket, status, user_id, socket.assigns.ticket_type) do
      {:ok, updated_ticket} ->
        # Reload activity logs and comments to show the status change in real-time
        activity_logs = get_activity_logs(updated_ticket, socket.assigns.ticket_type)
        comments = get_comments(updated_ticket, socket.assigns.ticket_type)
        
        {:noreply, 
         socket
         |> assign(:ticket, updated_ticket)
         |> assign(:activity_logs, activity_logs)
         |> assign(:comments, comments)
         |> assign(:new_status, "")
         |> assign(:show_status_modal, false)
         |> put_flash(:info, "Estado actualizado a #{get_status_label(status)}")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar estado")}
    end
  end

  @impl true
  def handle_event("update_status", %{"new_status" => status}, socket) do
    user_id = socket.assigns.current_user.id
    case update_ticket_status(socket.assigns.ticket, status, user_id, socket.assigns.ticket_type) do
      {:ok, updated_ticket} ->
        # Reload activity logs and comments to show the status change in real-time
        activity_logs = get_activity_logs(updated_ticket, socket.assigns.ticket_type)
        comments = get_comments(updated_ticket, socket.assigns.ticket_type)
        
        {:noreply, 
         socket
         |> assign(:ticket, updated_ticket)
         |> assign(:activity_logs, activity_logs)
         |> assign(:comments, comments)
         |> assign(:new_status, "")
         |> assign(:show_status_modal, false)
         |> put_flash(:info, "Estado actualizado a #{get_status_label(status)}")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar estado")}
    end
  end

  @impl true
  def handle_event("update_status", _params, socket) do
    # Si no hay estado seleccionado, no hacer nada
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_comment", _params, socket) do
    IO.inspect("Add comment event triggered", label: "[DEBUG]")
    IO.inspect(socket.assigns.new_comment, label: "[DEBUG] new_comment value")
    IO.inspect(String.trim(socket.assigns.new_comment), label: "[DEBUG] trimmed comment")
    
    if String.trim(socket.assigns.new_comment) != "" do
      IO.inspect("Comment is not empty, adding...", label: "[DEBUG]")
      # Set loading state
      socket = assign(socket, :is_adding_comment, true)
      
      case add_comment(socket.assigns.ticket, socket.assigns.new_comment, socket.assigns.current_user, socket.assigns.ticket_type) do
        {:ok, _comment} ->
          IO.inspect("Comment added successfully", label: "[DEBUG]")
          # Reload comments and update in real-time
          comments = get_comments(socket.assigns.ticket, socket.assigns.ticket_type)
          {:noreply, 
           socket
           |> assign(:comments, comments)
           |> assign(:new_comment, "")
           |> assign(:is_adding_comment, false)
           |> put_flash(:info, "Comentario agregado")}
        
        {:error, changeset} ->
          IO.inspect(changeset, label: "[DEBUG] Error adding comment")
          {:noreply, 
           socket
           |> assign(:is_adding_comment, false)
           |> put_flash(:error, "Error al agregar comentario")}
      end
    else
      IO.inspect("Comment is empty, not adding", label: "[DEBUG]")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("comment_changed", %{"value" => comment}, socket) do
    IO.inspect(comment, label: "[DEBUG] comment_changed value")
    {:noreply, assign(socket, :new_comment, comment)}
  end

  @impl true
  def handle_event("status_changed", %{"value" => status}, socket) do
    {:noreply, assign(socket, :new_status, status)}
  end

  @impl true
  def handle_event("status_changed", %{"new_status" => status}, socket) do
    {:noreply, assign(socket, :new_status, status)}
  end

  @impl true
  def handle_event("save_ticket", %{"ticket" => ticket_params}, socket) do
    user_id = socket.assigns.current_user.id
    case update_ticket(socket.assigns.ticket, ticket_params, user_id, socket.assigns.ticket_type) do
      {:ok, updated_ticket} ->
        # Reload activity logs and comments to show the ticket update in real-time
        activity_logs = get_activity_logs(updated_ticket, socket.assigns.ticket_type)
        comments = get_comments(updated_ticket, socket.assigns.ticket_type)
        
        {:noreply, 
         socket
         |> assign(:ticket, updated_ticket)
         |> assign(:activity_logs, activity_logs)
         |> assign(:comments, comments)
         |> assign(:show_edit_modal, false)
         |> put_flash(:info, "Ticket actualizado correctamente")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar ticket")}
    end
  end

  @impl true
  def handle_event("navigate_to_truck", _params, socket) do
    {:noreply, push_navigate(socket, to: "/trucks/#{socket.assigns.truck.id}")}
  end

  @impl true
  def handle_event("show_upload_modal", _params, socket) do
    {:noreply, assign(socket, :show_upload_modal, true)}
  end

  @impl true
  def handle_event("close_upload_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_upload_modal, false)
     |> assign(:file_descriptions, %{})}
  end

  @impl true
  def handle_event("validate_attachments", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_file_description", %{"ref" => ref, "value" => description}, socket) do
    file_descriptions = Map.put(socket.assigns.file_descriptions, ref, description)
    {:noreply, assign(socket, :file_descriptions, file_descriptions)}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    # Remover la descripción cuando se cancela el upload
    file_descriptions = Map.delete(socket.assigns.file_descriptions, ref)
    socket = assign(socket, :file_descriptions, file_descriptions)
    {:noreply, cancel_upload(socket, :ticket_attachments, ref)}
  end

  @impl true
  def handle_event("show_delete_modal", %{"index" => index}, socket) do
    index = String.to_integer(index)
    photos = get_photos(socket.assigns.ticket, socket.assigns.ticket_type)
    
    if index >= 0 and index < length(photos) do
      file_to_delete = Enum.at(photos, index)
      file_info = parse_file_info(file_to_delete)
      
      {:noreply, 
       socket
       |> assign(:show_delete_modal, true)
       |> assign(:file_to_delete, %{index: index, info: file_info})}
    else
      {:noreply, put_flash(socket, :error, "Archivo no encontrado")}
    end
  end

  @impl true
  def handle_event("close_delete_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:file_to_delete, nil)}
  end

  @impl true
  def handle_event("confirm_delete_attachment", _params, socket) do
    %{index: index, info: file_info} = socket.assigns.file_to_delete
    photos = get_photos(socket.assigns.ticket, socket.assigns.ticket_type)
    
    # Eliminar archivo físico
    file_path = Path.join([File.cwd!(), "priv", "static", file_info.path])
    if File.exists?(file_path) do
      File.rm!(file_path)
    end
    
    # Remover de la lista
    updated_photos = List.delete_at(photos, index)
    
          # Actualizar el ticket
      case update_ticket_photos(socket.assigns.ticket, updated_photos, socket.assigns.ticket_type) do
        {:ok, updated_ticket} ->
          # Crear log de actividad
          add_activity_log(updated_ticket, "eliminó el archivo '#{file_info.original_name}'", socket.assigns.current_user, socket.assigns.ticket_type)
          
          # Reload activity logs to show the file deletion in real-time
          activity_logs = get_activity_logs(updated_ticket, socket.assigns.ticket_type)
          
          {:noreply, 
           socket
           |> assign(:ticket, updated_ticket)
           |> assign(:activity_logs, activity_logs)
           |> assign(:show_delete_modal, false)
           |> assign(:file_to_delete, nil)
           |> put_flash(:info, "Archivo eliminado correctamente")}
      
              {:error, _changeset} ->
          {:noreply, 
           socket
           |> assign(:show_delete_modal, false)
           |> assign(:file_to_delete, nil)
           |> put_flash(:error, "Error al eliminar el archivo")}
    end
  end

  # @impl true
  # def handle_event("show_checkout_modal", _params, socket) do
  #   {:noreply, assign(socket, :show_checkout_modal, true)}
  # end

  # @impl true
  # def handle_event("close_checkout_modal", _params, socket) do
  #   {:noreply, 
  #    socket
  #    |> assign(:show_checkout_modal, false)
  #    |> assign(:checkout_file_descriptions, %{})
  #    |> assign(:checkout_signature, "")}
  # end

  # @impl true
  # def handle_event("update_checkout_file_description", %{"ref" => ref, "value" => description}, socket) do
  #   updated_descriptions = Map.put(socket.assigns.checkout_file_descriptions, ref, description)
  #   {:noreply, assign(socket, :checkout_file_descriptions, updated_descriptions)}
  # end

  # @impl true
  # def handle_event("save_checkout", params, socket) do
  #   IO.inspect("Save checkout event triggered", label: "[DEBUG]")
    
  #   # Procesar archivos subidos
  #   uploaded_files = consume_uploaded_entries(socket, :checkout_photos, fn %{path: path}, entry ->
  #     IO.inspect("Processing checkout file: #{entry.client_name}", label: "[DEBUG]")
      
  #     # Crear directorio para archivos si no existe
  #     upload_dir = Path.join(["priv", "static", "uploads", "checkout", to_string(socket.assigns.ticket.id)])
  #     File.mkdir_p!(upload_dir)
      
  #     # Generar nombre único para el archivo usando timestamp y nombre original
  #     timestamp = System.system_time(:millisecond)
  #     unique_filename = "#{timestamp}_#{entry.client_name}"
  #     dest_path = Path.join(upload_dir, unique_filename)
      
  #     # Copiar archivo
  #     File.cp!(path, dest_path)
      
  #     # Obtener descripción del archivo
  #     description = Map.get(socket.assigns.checkout_file_descriptions, entry.ref, "")
      
  #     file_info = %{
  #       original_name: entry.client_name,
  #       filename: unique_filename,
  #       path: "/uploads/checkout/#{socket.assigns.ticket.id}/#{unique_filename}",
  #       size: entry.client_size,
  #       content_type: entry.client_type,
  #       description: description
  #     }
      
  #     IO.inspect(file_info, label: "[DEBUG] Checkout file info")
  #     {:ok, file_info}
  #   end)

  #   # Preparar datos de check-out
  #   checkout_data = %{
  #     "checkout_driver_cedula" => params["driver_cedula"],
  #     "checkout_driver_name" => params["driver_name"],
  #     "checkout_details" => params["details"],
  #     "checkout_notes" => params["notes"],
  #     "checkout_signature" => socket.assigns.checkout_signature,
  #     "checkout_date" => DateTime.utc_now(),
  #     "checkout_photos" => Enum.map(uploaded_files, & &1.path)
  #   }

  #   # Actualizar el ticket con los datos de check-out
  #   case update_ticket_checkout(socket.assigns.ticket, checkout_data, socket.assigns.ticket_type, socket.assigns.current_user.id) do
  #     {:ok, updated_ticket} ->
  #       # Reload the ticket from database to ensure we have the latest data
  #       reloaded_ticket = reload_ticket(updated_ticket.id, socket.assigns.ticket_type)
        
  #       # Reload activity logs to show the checkout in real-time
  #       activity_logs = get_activity_logs(reloaded_ticket, socket.assigns.ticket_type)
        
  #       {:noreply, 
  #        socket
  #        |> assign(:ticket, reloaded_ticket)
  #        |> assign(:activity_logs, activity_logs)
  #        |> assign(:show_checkout_modal, false)
  #        |> assign(:checkout_file_descriptions, %{})
  #        |> assign(:checkout_signature, "")
  #        |> put_flash(:info, "Check-out realizado correctamente")}
      
  #     {:error, changeset} ->
  #       IO.inspect(changeset, label: "[DEBUG] Error updating ticket checkout")
  #       {:noreply, 
  #        socket
  #        |> put_flash(:error, "Error al realizar el check-out: #{inspect(changeset.errors)}")}
  #   end
  # end

  @impl true
  def handle_event("save_attachments", _params, socket) do
    IO.inspect("Save attachments event triggered", label: "[DEBUG]")
    
    # Procesar archivos subidos
    uploaded_files = consume_uploaded_entries(socket, :ticket_attachments, fn %{path: path}, entry ->
      IO.inspect("Processing file: #{entry.client_name}", label: "[DEBUG]")
      
      # Crear directorio para archivos si no existe
      upload_dir = Path.join(["priv", "static", "uploads", "tickets", to_string(socket.assigns.ticket.id)])
      File.mkdir_p!(upload_dir)
      
      # Generar nombre único para el archivo usando timestamp y nombre original
      timestamp = System.system_time(:millisecond)
      unique_filename = "#{timestamp}_#{entry.client_name}"
      dest_path = Path.join(upload_dir, unique_filename)
      
      # Copiar archivo
      File.cp!(path, dest_path)
      
      # Obtener descripción del archivo
      description = Map.get(socket.assigns.file_descriptions, entry.ref, "")
      
      file_info = %{
        original_name: entry.client_name,
        filename: unique_filename,
        path: "/uploads/tickets/#{socket.assigns.ticket.id}/#{unique_filename}",
        size: entry.client_size,
        content_type: entry.client_type,
        description: description
      }
      
      IO.inspect(file_info, label: "[DEBUG] File info")
      IO.inspect("File copied successfully to: #{dest_path}", label: "[DEBUG]")
      {:ok, file_info}
    end)

    IO.inspect(uploaded_files, label: "[DEBUG] Uploaded files")
    IO.inspect(length(uploaded_files), label: "[DEBUG] Number of uploaded files")

    if length(uploaded_files) > 0 do
      IO.inspect("Updating ticket with #{length(uploaded_files)} files", label: "[DEBUG]")
      
      # Actualizar el ticket con los nuevos archivos
      case update_ticket_attachments(socket.assigns.ticket, uploaded_files, socket.assigns.ticket_type) do
        {:ok, updated_ticket} ->
          IO.inspect("Ticket updated successfully", label: "[DEBUG]")
          IO.inspect(get_photos(updated_ticket, socket.assigns.ticket_type), label: "[DEBUG] Updated ticket photos")
          
          # Reload the ticket from database to ensure we have the latest data
          reloaded_ticket = reload_ticket(updated_ticket.id, socket.assigns.ticket_type)
          IO.inspect(get_photos(reloaded_ticket, socket.assigns.ticket_type), label: "[DEBUG] Reloaded ticket photos")
          
          # Reload activity logs to show the file upload in real-time
          activity_logs = get_activity_logs(reloaded_ticket, socket.assigns.ticket_type)
          
          {:noreply, 
           socket
           |> assign(:ticket, reloaded_ticket)
           |> assign(:activity_logs, activity_logs)
           |> assign(:show_upload_modal, false)
           |> assign(:file_descriptions, %{})
           |> put_flash(:info, "Archivos subidos correctamente")}
        
        {:error, changeset} ->
          IO.inspect(changeset, label: "[DEBUG] Error updating ticket")
          IO.inspect(changeset.errors, label: "[DEBUG] Changeset errors")
          {:noreply, 
           socket
           |> put_flash(:error, "Error al guardar los archivos: #{inspect(changeset.errors)}")}
      end
    else
      IO.inspect("No files to upload", label: "[DEBUG]")
      {:noreply, 
       socket
       |> assign(:show_upload_modal, false)
       |> assign(:file_descriptions, %{})
       |> put_flash(:info, "No se seleccionaron archivos")}
    end
  end

  @impl true
  def handle_info({:close_edit_modal}, socket) do
    {:noreply, assign(socket, :show_edit_modal, false)}
  end

  @impl true
  def handle_info({:ticket_updated, updated_ticket}, socket) do
    {:noreply, 
     socket
     |> assign(:ticket, updated_ticket)
     |> assign(:show_edit_modal, false)
     |> put_flash(:info, "Ticket actualizado correctamente")}
  end

  defp get_activity_logs(ticket, ticket_type) do
    entity_type = if ticket_type == "maintenance", do: "maintenance_ticket", else: "evaluation"
    
    ActivityLog
    |> where([log], log.entity_type == ^entity_type and log.entity_id == ^ticket.id)
    |> order_by([log], desc: log.inserted_at)
    |> limit(10)
    |> preload([:user])
    |> Repo.all()
  end

  defp reload_ticket(ticket_id, ticket_type) do
    case ticket_type do
      "maintenance" -> 
        Repo.get(MaintenanceTicket, ticket_id)
      "evaluation" -> 
        Repo.get(Evaluation, ticket_id)
      _ -> 
        nil
    end
  end



  defp get_comments(ticket, ticket_type) do
    # For now, we'll use activity logs as comments
    # In a real implementation, you'd have a separate comments table
    get_activity_logs(ticket, ticket_type)
    |> Enum.map(fn log -> 
      %{
        id: log.id,
        user: if(log.user, do: log.user.email, else: "Sistema"),
        role: "Usuario",
        date: log.inserted_at,
        message: log.description,
        type: "update"
      }
    end)
  end

  defp update_maintenance_progress(ticket, progress, user_id) do
    IO.inspect("Updating progress to: #{progress}", label: "[DEBUG] Progress Update")
    
    # Si el progreso llega al 100%, cambiar automáticamente el estado a completed
    update_data = if progress == 100 do
      %{"progress" => progress, "status" => "completed"}
    else
      %{"progress" => progress}
    end
    
    result = MaintenanceTicket.update_ticket(ticket, update_data, user_id)
    IO.inspect(result, label: "[DEBUG] Update result")
    result
  end

  defp update_ticket_status(ticket, status, user_id, ticket_type) do
    case ticket_type do
      "maintenance" -> MaintenanceTicket.update_ticket(ticket, %{"status" => status}, user_id)
      "evaluation" -> Evaluation.update_evaluation(ticket, %{"status" => status}, user_id)
      _ -> {:error, :invalid_ticket_type}
    end
  end

  defp update_ticket(ticket, params, user_id, ticket_type) do
    case ticket_type do
      "maintenance" -> MaintenanceTicket.update_ticket(ticket, params, user_id)
      "evaluation" -> Evaluation.update_evaluation(ticket, params, user_id)
      _ -> {:error, :invalid_ticket_type}
    end
  end

  # defp update_ticket_checkout(ticket, checkout_data, ticket_type, user_id) do
  #   case ticket_type do
  #     "maintenance" -> MaintenanceTicket.update_ticket(ticket, checkout_data, user_id)
  #     "evaluation" -> Evaluation.update_evaluation(ticket, checkout_data, user_id)
  #     "production" -> EvaaCrmGaepell.ProductionOrder.update_production_order(ticket, checkout_data, user_id)
  #     _ -> {:error, :invalid_ticket_type}
  #   end
  # end

  # @impl true
  # def handle_event("save_signature", %{"signature" => signature_data}, socket) do
  #   {:noreply, assign(socket, :checkout_signature, signature_data)}
  # end

  defp update_ticket_attachments(ticket, uploaded_files, ticket_type) do
    IO.inspect("update_ticket_attachments called", label: "[DEBUG]")
    IO.inspect(ticket.id, label: "[DEBUG] Ticket ID")
    IO.inspect(ticket_type, label: "[DEBUG] Ticket type")
    
    # Obtener archivos existentes según el tipo de ticket
    existing_photos = get_photos(ticket, ticket_type)
    IO.inspect(existing_photos, label: "[DEBUG] Existing photos")
    
    # Crear lista de nuevos archivos con descripciones
    new_photos = Enum.map(uploaded_files, fn file ->
      if file.description && file.description != "" do
        # Si hay descripción, crear un objeto JSON
        json_data = Jason.encode!(%{
          path: file.path,
          description: file.description,
          original_name: file.original_name,
          size: file.size,
          content_type: file.content_type
        })
        IO.inspect(json_data, label: "[DEBUG] JSON photo data")
        json_data
      else
        # Si no hay descripción, mantener solo la ruta (compatibilidad)
        IO.inspect(file.path, label: "[DEBUG] Simple photo path")
        file.path
      end
    end)
    
    IO.inspect(new_photos, label: "[DEBUG] New photos")
    
    # Combinar archivos existentes con nuevos
    all_photos = existing_photos ++ new_photos
    IO.inspect(all_photos, label: "[DEBUG] All photos combined")
    
    # Actualizar el ticket con todos los archivos
    result = case ticket_type do
      "maintenance" -> 
        IO.inspect("Updating maintenance ticket", label: "[DEBUG]")
        # Necesitamos el user_id para actualizar, pero no lo tenemos aquí
        # Vamos a usar un método directo para evitar el error
        ticket
        |> Ecto.Changeset.change(%{damage_photos: all_photos})
        |> Repo.update()
      "evaluation" -> 
        IO.inspect("Updating evaluation ticket", label: "[DEBUG]")
        # Para evaluaciones, necesitamos usar el user_id, pero no lo tenemos aquí
        # Por ahora, vamos a usar un método directo
        ticket
        |> Ecto.Changeset.change(%{photos: all_photos})
        |> Repo.update()
      _ -> 
        IO.inspect("Invalid ticket type", label: "[DEBUG]")
        {:error, :invalid_ticket_type}
    end
    
    IO.inspect(result, label: "[DEBUG] Update result")
    result
  end

  defp update_ticket_photos(ticket, photos, ticket_type) do
    # Actualizar el ticket con la nueva lista de fotos
    case ticket_type do
      "maintenance" -> 
        # Usar método directo para evitar necesidad de user_id
        ticket
        |> Ecto.Changeset.change(%{damage_photos: photos})
        |> Repo.update()
      "evaluation" -> 
        ticket
        |> Ecto.Changeset.change(%{photos: photos})
        |> Repo.update()
      _ -> 
        {:error, :invalid_ticket_type}
    end
  end

  defp add_comment(ticket, message, user, ticket_type) do
    entity_type = if ticket_type == "maintenance", do: "maintenance_ticket", else: "evaluation"
    
    ActivityLog.create_log(%{
      action: "commented",
      description: message,
      user_id: user.id,
      business_id: user.business_id,
      entity_type: entity_type,
      entity_id: ticket.id
    })
  end

  defp add_activity_log(ticket, action_description, user, ticket_type) do
    entity_type = if ticket_type == "maintenance", do: "maintenance_ticket", else: "evaluation"
    
    ActivityLog.create_log(%{
      action: "updated",
      description: "#{user.email} #{action_description}",
      user_id: user.id,
      business_id: user.business_id,
      entity_type: entity_type,
      entity_id: ticket.id
    })
  end

  defp get_priority_color(priority) do
    case priority do
      "critical" -> "bg-red-500 text-white"
      "high" -> "bg-orange-500 text-white"
      "medium" -> "bg-blue-500 text-white"
      "low" -> "bg-green-500 text-white"
      _ -> "bg-gray-500 text-white"
    end
  end

  defp get_type_icon(type) do
    case type do
      "maintenance" -> "🔧"
      "evaluation" -> "🛡️"
      "orders" -> "📋"
      _ -> "📄"
    end
  end

  defp format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y %H:%M")
  end

  defp format_currency(amount) do
    :erlang.float_to_binary(amount, [decimals: 2])
    |> String.replace(".", ",")
    |> then(&"$#{&1}")
  end

  # Helper functions for template
  defp get_status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400"
      "in-progress" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400"
      "completed" -> "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400"
    end
  end

  defp get_status_label(status) do
    case status do
      "new_ticket" -> "Nueva Orden"
      "reception" -> "Recepción"
      "diagnosis" -> "Diagnóstico"
      "repair" -> "Reparación"
      "final_check" -> "Revisión Final"
      "completed" -> "Completada"
      "cancelled" -> "Cancelada"
      # Estados legacy para compatibilidad
      "check_in" -> "Check In"
      "in_workshop" -> "En Taller/Reparación"
      "car_wash" -> "Car Wash"
      "check_out" -> "Check Out"
      _ -> "Desconocido"
    end
  end

  defp get_priority_label(priority) do
    case priority do
      "high" -> "Alta"
      "medium" -> "Media"
      "low" -> "Baja"
      "critical" -> "Crítica"
      _ -> "Normal"
    end
  end

  defp get_severity_label(severity) do
    case severity do
      "high" -> "Alta"
      "medium" -> "Media"
      "low" -> "Baja"
      _ -> "Normal"
    end
  end

  defp error_to_string(:too_large), do: "El archivo es demasiado grande"
  defp error_to_string(:too_many_files), do: "Demasiados archivos seleccionados"
  defp error_to_string(:not_accepted), do: "Tipo de archivo no permitido"
  defp error_to_string(_), do: "Error desconocido"

  # Helper para parsear archivos con descripciones
  defp parse_file_info(file_info) when is_binary(file_info) do
    case Jason.decode(file_info) do
      {:ok, parsed} -> 
        # Es un archivo con descripción
        %{
          path: parsed["path"] || file_info,
          description: parsed["description"],
          original_name: parsed["original_name"] || Path.basename(parsed["path"] || file_info),
          size: parsed["size"],
          content_type: parsed["content_type"]
        }
      {:error, _} -> 
        # Es un archivo sin descripción (solo ruta)
        %{
          path: file_info,
          description: nil,
          original_name: Path.basename(file_info),
          size: nil,
          content_type: nil
        }
    end
  end
  
  defp parse_file_info(file_info) do
    # Fallback para cualquier otro tipo de dato
    %{
      path: to_string(file_info),
      description: nil,
      original_name: "archivo",
      size: nil,
      content_type: nil
    }
  end

  # Helper para obtener fotos según el tipo de ticket
  defp get_photos(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :damage_photos, [])
      "evaluation" -> Map.get(ticket, :photos, [])
      _ -> []
    end
  end

  # Helper para obtener horas según el tipo de ticket
  defp get_actual_hours(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :actual_hours, 0)
      "evaluation" -> Map.get(ticket, :actual_hours, 0)
      _ -> 0
    end
  end

  defp get_estimated_hours(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :estimated_hours, 0)
      "evaluation" -> Map.get(ticket, :estimated_hours, 0)
      _ -> 0
    end
  end

  # Helper para obtener costos según el tipo de ticket
  defp get_actual_cost(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :actual_cost, 0)
      "evaluation" -> Map.get(ticket, :actual_cost, 0)
      _ -> 0
    end
  end

  defp get_estimated_cost(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :estimated_repair_cost, 0)
      "evaluation" -> Map.get(ticket, :estimated_cost, 0)
      _ -> 0
    end
  end

  # Helper para obtener progreso según el tipo de ticket
  defp get_progress(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :progress, 0)
      "evaluation" -> Map.get(ticket, :progress, 0)
      _ -> 0
    end
  end

  # Helper para obtener campos de evaluación según el tipo de ticket
  defp get_damage_areas(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> 
        # Extraer áreas de mantenimiento de evaluation_notes temporalmente
        notes = Map.get(ticket, :evaluation_notes, "") || ""
        case String.split(notes, "\n") do
          [_type_line, areas_line | _] -> 
            case String.split(areas_line, ": ") do
              ["Áreas", areas] -> 
                if areas == "", do: [], else: String.split(areas, ", ")
              _ -> []
            end
          _ -> []
        end
      "evaluation" -> Map.get(ticket, :damage_areas, [])
      _ -> []
    end
  end

  defp get_evaluation_type(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> 
        # Extraer tipo de mantenimiento de evaluation_notes temporalmente
        notes = Map.get(ticket, :evaluation_notes, "") || ""
        case String.split(notes, "\n") do
          [type_line | _] -> 
            case String.split(type_line, ": ") do
              ["Tipo", type] -> type
              _ -> "No especificado"
            end
          _ -> "No especificado"
        end
      "evaluation" -> Map.get(ticket, :evaluation_type, "No especificado")
      _ -> "No especificado"
    end
  end

  # Nueva función para obtener el tipo específico de mantenimiento
  defp get_maintenance_specific_type(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> 
        # Extraer tipo específico de mantenimiento de evaluation_notes
        notes = Map.get(ticket, :evaluation_notes, "") || ""
        case String.split(notes, "\n") do
          [type_line | _] -> 
            case String.split(type_line, ": ") do
              ["Tipo", type] -> type
              _ -> "preventive"  # Default para tickets existentes
            end
          _ -> "preventive"  # Default para tickets existentes
        end
      _ -> "No aplica"
    end
  end

  defp get_severity_level(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :priority, "No especificado")
      "evaluation" -> Map.get(ticket, :severity_level, "No especificado")
      _ -> "No especificado"
    end
  end

  defp get_notes(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :notes, "") || ""
      "evaluation" -> Map.get(ticket, :evaluation_notes, "") || ""
      _ -> ""
    end
  end

  defp get_evaluated_by(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :deliverer_name, "No especificado")
      "evaluation" -> Map.get(ticket, :evaluated_by, "No especificado")
      _ -> "No especificado"
    end
  end

  defp get_driver_cedula(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :document_number, "No especificada")
      "evaluation" -> Map.get(ticket, :driver_cedula, "No especificada")
      _ -> "No especificada"
    end
  end

  defp get_reported_by(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :deliverer_name, "No especificado")
      "evaluation" -> Map.get(ticket, :reported_by, "No especificado")
      _ -> "No especificado"
    end
  end

  defp get_assigned_to(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> 
        if Map.get(ticket, :specialist_id), do: "Asignado", else: "No asignado"
      "evaluation" -> Map.get(ticket, :assigned_to, "No asignado")
      _ -> "No asignado"
    end
  end

  defp get_location(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> "Taller"
      "evaluation" -> Map.get(ticket, :location, "No especificada")
      _ -> "No especificada"
    end
  end

  # Helper functions for maintenance-specific fields
  defp get_maintenance_type_label(type) do
    case type do
      "preventive" -> "Preventivo"
      "corrective" -> "Correctivo"
      "emergency" -> "Emergencia"
      "inspection" -> "Inspección"
      "maintenance" -> "Mantenimiento"
      _ -> "No especificado"
    end
  end

  defp get_priority_label(priority) do
    case priority do
      "low" -> "Baja"
      "medium" -> "Media"
      "high" -> "Alta"
      "critical" -> "Crítica"
      _ -> "No especificada"
    end
  end

  defp get_priority_color(priority) do
    case priority do
      "low" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "medium" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "high" -> "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
      "critical" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      _ -> "bg-slate-100 text-slate-800 dark:bg-slate-900 dark:text-slate-200"
    end
  end

  # Helper functions for parsing values
  defp parse_integer(value) when is_binary(value) and value != "" do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(_), do: nil

  defp parse_decimal(value) when is_binary(value) and value != "" do
    case Decimal.parse(value) do
      {:ok, decimal} -> decimal
      :error -> nil
    end
  end
  defp parse_decimal(_), do: nil
end
