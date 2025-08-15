defmodule EvaaCrmGaepell.Fleet do
  import Ecto.Query, warn: false
  alias EvaaCrmGaepell.Repo

  alias EvaaCrmGaepell.Truck
  alias EvaaCrmGaepell.MaintenanceTicket
  alias EvaaCrmGaepell.Activity

  # CRUD para Camiones
  def list_trucks do
    Repo.all(Truck)
  end

  def get_truck!(id), do: Repo.get!(Truck, id)

  def create_truck(attrs \\ %{}) do
    %Truck{}
    |> Truck.changeset(attrs)
    |> Repo.insert()
  end

  def update_truck(%Truck{} = truck, attrs) do
    truck
    |> Truck.changeset(attrs)
    |> Repo.update()
  end

  def delete_truck(%Truck{} = truck) do
    Repo.delete(truck)
  end

  def change_truck(%Truck{} = truck, attrs \\ %{}) do
    Truck.changeset(truck, attrs)
  end

  # CRUD para Tickets de Mantenimiento
  def list_maintenance_tickets do
    Repo.all(MaintenanceTicket)
  end

  def get_maintenance_ticket!(id), do: Repo.get!(MaintenanceTicket, id)

  def create_maintenance_ticket(attrs \\ %{}) do
    Repo.transaction(fn ->
      {:ok, ticket} = %MaintenanceTicket{}
      |> MaintenanceTicket.changeset(attrs)
      |> Repo.insert()

      # Sincronizar actividad
      {:ok, _activity} = maybe_create_or_update_activity_for_ticket(ticket)
      
      # Registrar log de creación si hay user_id en attrs
      user_id = attrs[:user_id] || attrs["user_id"]
      if user_id do
        EvaaCrmGaepell.ActivityLog.log_creation(
          "maintenance_ticket",
          ticket.id,
          ticket.title,
          user_id,
          ticket.business_id
        )
      end
      
      ticket
    end)
    |> case do
      {:ok, ticket} -> {:ok, ticket}
      {:error, reason} -> {:error, reason}
    end
  end

  def update_maintenance_ticket(ticket, params, current_user_id) do
    old_status = ticket.status
    changeset = EvaaCrmGaepell.MaintenanceTicket.changeset(ticket, params)
    case EvaaCrmGaepell.Repo.update(changeset) do
      {:ok, updated_ticket} ->
        # Registrar cambio de estado si ocurrió
        if updated_ticket.status != old_status do
          EvaaCrmGaepell.ActivityLog.log_status_change(
            "maintenance_ticket", 
            ticket.id, 
            old_status, 
            updated_ticket.status, 
            current_user_id, 
            ticket.business_id
          )
        end
        {:ok, updated_ticket}
      error -> error
    end
  end

  def delete_maintenance_ticket(%MaintenanceTicket{} = ticket) do
    Repo.transaction(fn ->
      # Eliminar actividad asociada
      maybe_delete_activity_for_ticket(ticket)
      Repo.delete(ticket)
    end)
  end

  def change_maintenance_ticket(%MaintenanceTicket{} = ticket, attrs \\ %{}) do
    MaintenanceTicket.changeset(ticket, attrs)
  end

  # --- Helpers privados de sincronización ---
  defp maybe_create_or_update_activity_for_ticket(ticket) do
    attrs = %{
      type: "maintenance",
      title: ticket.title,
      description: ticket.description,
      due_date: ticket.entry_date,
      duration_minutes: 60,
      priority: ticket.priority,
      status: ticket_status_to_activity_status(ticket.status),
      truck_id: ticket.truck_id,
      specialist_id: ticket.specialist_id,
      business_id: ticket.business_id,
      maintenance_ticket_id: ticket.id,
      color: ticket.color
    }

    case Repo.get_by(Activity, maintenance_ticket_id: ticket.id) do
      nil ->
        %Activity{}
        |> Activity.changeset(attrs)
        |> Repo.insert()
      activity ->
        activity
        |> Activity.changeset(attrs)
        |> Repo.update()
    end
  end

  defp maybe_delete_activity_for_ticket(ticket) do
    from(a in Activity, where: a.maintenance_ticket_id == ^ticket.id)
    |> Repo.delete_all()
  end

  # --- Sincronización inversa: actualizar ticket desde actividad ---
  def update_ticket_from_activity(%Activity{} = activity) do
    case Repo.get(MaintenanceTicket, activity.maintenance_ticket_id) do
      nil -> {:error, :not_found}
      ticket ->
        attrs = %{
          title: activity.title,
          description: activity.description,
          entry_date: activity.due_date,
          priority: activity.priority,
          status: activity_status_to_ticket_status(activity.status),
          truck_id: activity.truck_id,
          specialist_id: activity.specialist_id,
          business_id: activity.business_id,
          color: activity.color
        }
        ticket
        |> MaintenanceTicket.changeset(attrs)
        |> Repo.update()
    end
  end

  # Helper para mapear status de ticket a actividad, robusto:
  defp ticket_status_to_activity_status(status) do
    case status do
      "open" -> "pending"
      "in_progress" -> "in_progress"
      "completed" -> "completed"
      "cancelled" -> "cancelled"
      "finalizado" -> "cancelled"
      s when s in ["pending", "in_progress", "completed", "cancelled"] -> s
      _ -> "pending" # fallback seguro
    end
  end

  # Helper para mapear status de actividad a ticket, robusto:
  defp activity_status_to_ticket_status(status) do
    case status do
      "pending" -> "open"
      "in_progress" -> "in_progress"
      "completed" -> "completed"
      "cancelled" -> "cancelled"
      s when s in ["open", "in_progress", "completed", "cancelled"] -> s
      _ -> "open" # fallback seguro
    end
  end
end 