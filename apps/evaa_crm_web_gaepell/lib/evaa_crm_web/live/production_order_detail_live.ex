defmodule EvaaCrmWebGaepell.ProductionOrderDetailLive do
  use EvaaCrmWebGaepell, :live_view

  alias EvaaCrmGaepell.{ProductionOrder, Truck, User, ActivityLog, Business}
  alias EvaaCrmGaepell.Repo
  import Ecto.Query
  import Phoenix.LiveView.Helpers

  @impl true
  def mount(%{"id" => order_id}, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    
    # Load production order with preloads
    order = Repo.get(ProductionOrder, order_id)
    
    if order do
      # Load related data
      business = Repo.get(Business, order.business_id)
      # Load truck information if license plate exists
      truck = if order.license_plate, do: get_truck_by_license_plate(order.license_plate), else: nil
      activity_logs = get_activity_logs(order)
      comments = get_comments(order)
      
      socket = 
                 socket
         |> assign(
           current_user: current_user,
           order: order,
           business: business,
           truck: truck,
           activity_logs: activity_logs,
           comments: comments,
           new_comment: "",
           new_status: "",
           is_editing: false,
           show_edit_modal: false,
           show_status_modal: false,
           show_delete_modal: false,
           show_production_details_edit_modal: false,
           show_technical_measurements_edit_modal: false,
           page_title: "Orden de Producción - #{order.id}",
           is_adding_comment: false,
           is_updating_status: false
         )

      {:ok, socket}
    else
      {:ok, 
       socket
       |> assign(:order, nil)
       |> put_flash(:error, "Orden de producción no encontrada")}
    end
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/tickets?tab=production")}
  end

  @impl true
  def handle_event("edit_order", _params, socket) do
    {:noreply, assign(socket, :show_edit_modal, true)}
  end

  @impl true
  def handle_event("edit_production_details", _params, socket) do
    {:noreply, assign(socket, :show_production_details_edit_modal, true)}
  end

  @impl true
  def handle_event("show_technical_measurements_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_technical_measurements_edit_modal, true)}
  end

  @impl true
  def handle_event("hide_technical_measurements_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_technical_measurements_edit_modal, false)}
  end

  @impl true
  def handle_event("hide_production_details_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_production_details_edit_modal, false)}
  end

  @impl true
  def handle_event("update_production_details", params, socket) do
    order = socket.assigns.order
    user_id = socket.assigns.current_user.id
    
    # Parse and prepare the update data
    update_data = %{
      specifications: params["specifications"],
      notes: params["notes"],
      total_cost: if(params["total_cost"] && params["total_cost"] != "", do: params["total_cost"], else: nil),
      materials_used: params["materials_used"],
      quality_check_notes: params["quality_check_notes"]
    }
    
    # Add estimated_delivery if provided
    update_data = if params["estimated_delivery"] && params["estimated_delivery"] != "" do
      case Date.from_iso8601(params["estimated_delivery"]) do
        {:ok, date} -> Map.put(update_data, :estimated_delivery, date)
        _ -> update_data
      end
    else
      update_data
    end
    
    case Repo.update(Ecto.Changeset.change(order, update_data)) do
      {:ok, updated_order} ->
        # Create activity log for the update
        ActivityLog.create_log(%{
          description: "Detalles de producción actualizados",
          action: "updated",
          business_id: order.business_id,
          user_id: user_id,
          entity_id: order.id,
          entity_type: "production_order"
        })
        
        {:noreply, 
         socket
         |> assign(:order, updated_order)
         |> assign(:show_production_details_edit_modal, false)
         |> put_flash(:success, "Detalles de producción actualizados exitosamente")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar los detalles de producción")}
    end
  end

  @impl true
  def handle_event("update_technical_measurements", params, socket) do
    truck = socket.assigns.truck
    user_id = socket.assigns.current_user.id
    
    if truck do
      # Parse and prepare the update data with type conversion
      update_data = %{
        rear_tire_width: if(params["rear_tire_width"] && params["rear_tire_width"] != "", do: parse_integer(params["rear_tire_width"]), else: nil),
        useful_length: if(params["useful_length"] && params["useful_length"] != "", do: parse_integer(params["useful_length"]), else: nil),
        chassis_length: if(params["chassis_length"] && params["chassis_length"] != "", do: parse_integer(params["chassis_length"]), else: nil),
        chassis_width: if(params["chassis_width"] && params["chassis_width"] != "", do: parse_integer(params["chassis_width"]), else: nil)
      }
      
      case Repo.update(Ecto.Changeset.change(truck, update_data)) do
        {:ok, updated_truck} ->
          # Create activity log for the update
          ActivityLog.create_log(%{
            description: "Medidas técnicas del camión actualizadas",
            action: "updated",
            business_id: truck.business_id,
            user_id: user_id,
            entity_id: truck.id,
            entity_type: "truck"
          })
          
          {:noreply, 
           socket
           |> assign(:truck, updated_truck)
           |> assign(:show_technical_measurements_edit_modal, false)
           |> put_flash(:success, "Medidas técnicas actualizadas exitosamente")}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al actualizar las medidas técnicas")}
      end
    else
      {:noreply, put_flash(socket, :error, "No se encontró el camión asociado")}
    end
  end

  @impl true
  def handle_event("close_edit_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_modal, false)}
  end

  @impl true
  def handle_event("show_status_modal", _params, socket) do
    {:noreply, assign(socket, :show_status_modal, true)}
  end

  @impl true
  def handle_event("hide_status_modal", _params, socket) do
    {:noreply, assign(socket, :show_status_modal, false)}
  end

  @impl true
  def handle_event("change_order_status", %{"status" => status}, socket) do
    order = socket.assigns.order
    
    case Repo.update(Ecto.Changeset.change(order, %{status: status})) do
      {:ok, updated_order} ->
        # Reload the order with preloads
        reloaded_order = updated_order |> Repo.preload([:business])
        
        {:noreply, 
         socket
         |> assign(:order, reloaded_order)
         |> assign(:show_status_modal, false)
         |> put_flash(:success, "Estado de la orden actualizado exitosamente")}
      
      {:error, _changeset} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error al actualizar el estado de la orden")}
    end
  end

  @impl true
  def handle_event("add_comment", %{"comment" => comment}, socket) do
    if String.trim(comment) != "" do
      order = socket.assigns.order
      user_id = socket.assigns.current_user.id
      
      # Use the specific log_comment function for comments
      case ActivityLog.log_comment("production_order", order.id, String.trim(comment), user_id, order.business_id) do
        {:ok, _activity_log} ->
          # Reload activity logs and comments
          updated_activity_logs = get_activity_logs(order)
          updated_comments = get_comments(order)
          
          {:noreply, 
           socket
           |> assign(:new_comment, "")
           |> assign(:activity_logs, updated_activity_logs)
           |> assign(:comments, updated_comments)
           |> put_flash(:success, "Comentario agregado exitosamente")}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al agregar el comentario")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_order", _params, socket) do
    order = socket.assigns.order
    
    case Repo.delete(order) do
      {:ok, _} ->
        {:noreply, 
         socket
         |> put_flash(:success, "Orden de producción eliminada exitosamente")
         |> push_navigate(to: "/tickets?tab=production")}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error al eliminar la orden de producción")}
    end
  end

  @impl true
  def handle_event("show_delete_modal", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, true)}
  end

  @impl true
  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, false)}
  end

    @impl true
  def handle_event("update_production_progress", %{"progress" => progress}, socket) do
    progress = String.to_integer(progress)
    order = socket.assigns.order
    user_id = socket.assigns.current_user.id
    
    case update_production_progress(order, progress, user_id) do
      {:ok, updated_order} ->
        {:noreply, 
         socket
         |> assign(:order, updated_order)
         |> put_flash(:info, "Progreso actualizado a #{progress}%")}
         
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar progreso")}
    end
  end

  @impl true
  def handle_event("update_progress", %{"progress" => progress}, socket) do
    # Handle the progress update from the JavaScript hook
    progress = String.to_integer(progress)
    order = socket.assigns.order
    user_id = socket.assigns.current_user.id
    
    case update_production_progress(order, progress, user_id) do
      {:ok, updated_order} ->
        {:noreply, 
         socket
         |> assign(:order, updated_order)
         |> put_flash(:info, "Progreso actualizado a #{progress}%")}
         
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar progreso")}
    end
  end

  defp get_activity_logs(order) do
    ActivityLog
    |> where([log], log.entity_type == "production_order" and log.entity_id == ^order.id)
    |> order_by([log], desc: log.inserted_at)
    |> limit(10)
    |> preload([:user])
    |> Repo.all()
  end

  defp get_comments(order) do
    # For now, we'll use activity logs as comments
    # In a real implementation, you'd have a separate comments table
    get_activity_logs(order)
    |> Enum.map(fn log -> 
      # Extract the actual comment message based on the action type
      message = case log.action do
        "commented" -> 
          # For comments, get the actual comment from metadata
          if log.metadata && log.metadata["comment"] do
            log.metadata["comment"]
          else
            log.description
          end
        _ -> 
          # For other actions, use the description
          log.description
      end
      
      %{
        id: log.id,
        user: if(log.user, do: log.user.email, else: "Sistema"),
        role: "Usuario",
        date: log.inserted_at,
        message: message,
        type: log.action
      }
    end)
  end

  defp get_truck_by_license_plate(license_plate) do
    Truck
    |> where([t], t.license_plate == ^license_plate)
    |> first()
    |> Repo.one()
  end

  # Helper functions for template
  defp get_status_color(status) do
    case status do
      "new_order" -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
      "reception" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "assembly" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "mounting" -> "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
      "final_check" -> "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
      "completed" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

  defp get_status_label(status) do
    case status do
      "new_order" -> "Nueva Orden"
      "reception" -> "Recepción"
      "assembly" -> "Ensamblaje"
      "mounting" -> "Montaje"
      "final_check" -> "Final Check"
      "completed" -> "Completada"
      "cancelled" -> "Cancelada"
      _ -> "Desconocido"
    end
  end

  defp get_box_type_label(box_type) do
    case box_type do
      "seca" -> "Caja Seca"
      "refrigerada" -> "Caja Refrigerada"
      _ -> "No especificado"
    end
  end

  defp get_priority_color(priority) do
    case priority do
      "high" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      "medium" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "low" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

  defp get_priority_label(priority) do
    case priority do
      "high" -> "Alta"
      "medium" -> "Media"
      "low" -> "Baja"
      _ -> "No especificada"
    end
  end

  # Production progress helper functions
  defp get_production_progress(order) do
    # If order has a progress field, use it; otherwise calculate from status
    if Map.has_key?(order, :progress) and order.progress do
      order.progress
    else
      case order.status do
        "new_order" -> 0
        "reception" -> 20
        "assembly" -> 40
        "mounting" -> 60
        "final_check" -> 80
        "completed" -> 100
        "cancelled" -> 0
        _ -> 0
      end
    end
  end

  defp get_days_remaining(estimated_delivery) do
    today = Date.utc_today()
    case Date.diff(estimated_delivery, today) do
      days when days > 0 -> days
      _ -> 0
    end
  end

  defp update_production_progress(order, progress, user_id) do
    # Create activity log for progress update
    activity_log_attrs = %{
      description: "Progreso de producción actualizado a #{progress}%",
      action: "progress_updated",
      business_id: order.business_id,
      user_id: user_id,
      entity_id: order.id,
      entity_type: "production_order"
    }
    
    # Update the order with new progress
    order
    |> Ecto.Changeset.change(%{progress: progress})
    |> Repo.update()
  end

  # Helper function to safely parse integers
  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(_), do: nil
end
