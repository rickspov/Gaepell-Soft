defmodule EvaaCrmWebGaepell.EditTicketModalComponent do
  use EvaaCrmWebGaepell, :live_component

  alias EvaaCrmGaepell.{MaintenanceTicket, Evaluation, User}
  alias EvaaCrmGaepell.Repo
  import Ecto.Query

  @impl true
  def update(%{id: id, ticket: ticket, show: show, ticket_type: ticket_type} = assigns, socket) do
    socket = assign(socket, 
      id: id,
      ticket: ticket,
      show: show,
      ticket_type: ticket_type,
             form_data: %{
         title: ticket.title || "",
         description: ticket.description || "",
         status: ticket.status || "pending",
         priority: ticket.priority || "medium",
         severity: get_severity_level_safe(ticket, ticket_type),
         owner: get_owner_safe(ticket, ticket_type),
         estimated_cost: get_estimated_cost_safe(ticket, ticket_type),
         actual_cost: get_actual_cost_safe(ticket, ticket_type),
         estimated_hours: get_estimated_hours_safe(ticket, ticket_type),
         actual_hours: get_actual_hours_safe(ticket, ticket_type),
         assigned_to: get_assigned_to_safe(ticket, ticket_type),
         progress: 0,
         has_insurance: get_has_insurance_safe(ticket, ticket_type),
         insurance_company: get_insurance_company_safe(ticket, ticket_type),
         insurance_case: get_insurance_case_safe(ticket, ticket_type)
       },
             scheduled_date: get_scheduled_date_safe(ticket, ticket_type),
       evaluation_date: get_evaluation_date_safe(ticket, ticket_type),
       due_date: get_due_date_safe(ticket, ticket_type),
      available_users: get_available_users(),
      isLoading: false
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {:close_edit_modal})
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    socket = assign(socket, :isLoading, true)
    
    case update_ticket(socket.assigns.ticket, socket.assigns.form_data, socket) do
      {:ok, updated_ticket} ->
        send(self(), {:ticket_updated, updated_ticket})
        {:noreply, assign(socket, :isLoading, false)}
      
      {:error, _changeset} ->
        {:noreply, 
         socket
         |> assign(:isLoading, false)
         |> put_flash(:error, "Error al actualizar ticket")}
    end
  end

  @impl true
  def handle_event("input_changed", %{"field" => field, "value" => value}, socket) do
    form_data = Map.put(socket.assigns.form_data, String.to_atom(field), value)
    {:noreply, assign(socket, :form_data, form_data)}
  end

  @impl true
  def handle_event("date_changed", %{"field" => field, "value" => value}, socket) do
    case Date.from_iso8601(value) do
      {:ok, date} ->
        socket = case field do
          "scheduled_date" -> assign(socket, :scheduled_date, date)
          "evaluation_date" -> assign(socket, :evaluation_date, date)
          "due_date" -> assign(socket, :due_date, date)
          _ -> socket
        end
        {:noreply, socket}
      
      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("insurance_toggled", _params, socket) do
    has_insurance = !socket.assigns.form_data.has_insurance
    form_data = Map.put(socket.assigns.form_data, :has_insurance, has_insurance)
    {:noreply, assign(socket, :form_data, form_data)}
  end

  defp get_available_users do
    User
    |> where([u], u.role in ["technician", "specialist", "supervisor"])
    |> select([u], %{id: u.id, name: u.email, role: u.role})
    |> Repo.all()
  end

  defp update_ticket(ticket, params, socket) do
    # Add dates to params
    params = params
    |> Map.put(:scheduled_date, socket.assigns.scheduled_date)
    |> Map.put(:evaluation_date, socket.assigns.evaluation_date)
    |> Map.put(:due_date, socket.assigns.due_date)
    |> Map.delete(:owner)  # No guardamos el owner en el ticket, es solo para mostrar

    case socket.assigns.ticket_type do
      "maintenance" -> MaintenanceTicket.update_ticket(ticket, params, socket.assigns.current_user.id)
      "evaluation" -> Evaluation.update_evaluation(ticket, params, socket.assigns.current_user.id)
      _ -> {:error, :invalid_ticket_type}
    end
  end

  defp get_type_icon(type) do
    case type do
      "maintenance" -> "🔧"
      "evaluation" -> "🛡️"
      _ -> "📄"
    end
  end

  defp format_date(date) do
    if date do
      Calendar.strftime(date, "%A, %d de %B de %Y")
    else
      "Seleccionar fecha"
    end
  end

  # Helper functions for safe field access
  defp get_severity_level_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :priority, "medium")
      "evaluation" -> Map.get(ticket, :severity_level, "medium")
      _ -> "medium"
    end
  end

  defp get_owner_safe(ticket, ticket_type) do
    # Obtener el propietario del truck asociado al ticket
    case ticket.truck do
      %{owner: owner} when is_binary(owner) and byte_size(owner) > 0 -> owner
      _ -> "No especificado"
    end
  end

  defp get_estimated_cost_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :estimated_repair_cost, 0)
      "evaluation" -> Map.get(ticket, :estimated_cost, 0)
      _ -> 0
    end
  end

  defp get_actual_cost_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :actual_cost, 0)
      "evaluation" -> Map.get(ticket, :actual_cost, 0)
      _ -> 0
    end
  end

  defp get_estimated_hours_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :estimated_hours, 0)
      "evaluation" -> Map.get(ticket, :estimated_hours, 0)
      _ -> 0
    end
  end

  defp get_actual_hours_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :actual_hours, 0)
      "evaluation" -> Map.get(ticket, :actual_hours, 0)
      _ -> 0
    end
  end

  defp get_assigned_to_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> 
        if Map.get(ticket, :specialist_id), do: "Asignado", else: ""
      "evaluation" -> Map.get(ticket, :assigned_to, "")
      _ -> ""
    end
  end

  defp get_has_insurance_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> false  # No existe en maintenance tickets
      "evaluation" -> Map.get(ticket, :has_insurance, false)
      _ -> false
    end
  end

  defp get_insurance_company_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :insurance_company, "")
      "evaluation" -> Map.get(ticket, :insurance_company, "")
      _ -> ""
    end
  end

  defp get_insurance_case_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :insurance_claim_number, "")
      "evaluation" -> Map.get(ticket, :insurance_case, "")
      _ -> ""
    end
  end

  defp get_scheduled_date_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> nil  # No existe en maintenance tickets
      "evaluation" -> Map.get(ticket, :scheduled_date, nil)
      _ -> nil
    end
  end

  defp get_evaluation_date_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :entry_date, nil)  # Usar entry_date como fallback
      "evaluation" -> Map.get(ticket, :evaluation_date, nil)
      _ -> nil
    end
  end

  defp get_due_date_safe(ticket, ticket_type) do
    case ticket_type do
      "maintenance" -> Map.get(ticket, :estimated_delivery, nil)  # Usar estimated_delivery como fallback
      "evaluation" -> Map.get(ticket, :due_date, nil)
      _ -> nil
    end
  end
end
