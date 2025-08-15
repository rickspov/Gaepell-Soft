defmodule EvaaCrmWebGaepell.ProductionOrdersLive do
  use EvaaCrmWebGaepell, :live_view

  alias EvaaCrmGaepell.{ProductionOrder, Repo, Truck, Quotation, User}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    
    socket = assign(socket, 
      current_user: current_user,
      production_orders: load_production_orders(),
      show_production_order_modal: false,
      selected_truck_id: nil,
      trucks: load_trucks(),
      quotations: load_quotations(),
      show_status_modal: false,
      selected_order_id: nil
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("show_production_order_form", _params, socket) do
    {:noreply, assign(socket, show_production_order_modal: true)}
  end



  @impl true
  def handle_info(:close_production_order_modal, socket) do
    {:noreply, assign(socket, show_production_order_modal: false)}
  end

  @impl true
  def handle_info({:production_order_created, _order}, socket) do
    {:noreply, 
     socket
     |> assign(production_orders: load_production_orders())
     |> assign(show_production_order_modal: false)
     |> put_flash(:success, "Orden de producción creada exitosamente")}
  end

  @impl true
  def handle_event("view_production_order", %{"order_id" => order_id}, socket) do
    # Por ahora solo redirigimos a una página de detalles (puedes implementar esto después)
    {:noreply, put_flash(socket, :info, "Funcionalidad de ver detalles próximamente")}
  end

  @impl true
  def handle_event("edit_production_order", %{"order_id" => order_id}, socket) do
    # Por ahora solo redirigimos a una página de edición (puedes implementar esto después)
    {:noreply, put_flash(socket, :info, "Funcionalidad de edición próximamente")}
  end

  @impl true
  def handle_event("delete_production_order", %{"order_id" => order_id}, socket) do
    order_id = String.to_integer(order_id)
    order = Repo.get(ProductionOrder, order_id)
    
    if order do
      case Repo.delete(order) do
        {:ok, _deleted_order} ->
          {:noreply, 
           socket
           |> assign(production_orders: load_production_orders())
           |> put_flash(:success, "Orden de producción eliminada exitosamente")}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al eliminar la orden de producción")}
      end
    else
      {:noreply, put_flash(socket, :error, "Orden de producción no encontrada")}
    end
  end

  @impl true
  def handle_event("show_status_modal", %{"order_id" => order_id}, socket) do
    order_id = String.to_integer(order_id)
    {:noreply, 
     socket
     |> assign(show_status_modal: true)
     |> assign(selected_order_id: order_id)}
  end

  @impl true
  def handle_event("hide_status_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(show_status_modal: false)
     |> assign(selected_order_id: nil)}
  end

  @impl true
  def handle_event("change_order_status", %{"order_id" => order_id, "status" => status}, socket) do
    order_id = String.to_integer(order_id)
    order = Repo.get(ProductionOrder, order_id)
    
    if order do
      case Repo.update(Ecto.Changeset.change(order, %{status: status})) do
        {:ok, _updated_order} ->
          {:noreply, 
           socket
           |> assign(production_orders: load_production_orders())
           |> assign(show_status_modal: false)
           |> assign(selected_order_id: nil)
           |> put_flash(:success, "Estado de la orden actualizado exitosamente")}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Error al actualizar el estado de la orden")}
      end
    else
      {:noreply, put_flash(socket, :error, "Orden de producción no encontrada")}
    end
  end

  defp load_production_orders do
    ProductionOrder
    |> order_by([po], desc: po.inserted_at)
    |> Repo.all()
  end

  defp load_trucks do
    Truck
    |> order_by([t], t.license_plate)
    |> Repo.all()
  end

  defp load_quotations do
    Quotation
    |> where([q], q.status == "approved")
    |> order_by([q], desc: q.inserted_at)
    |> Repo.all()
  end

  defp status_color("new_order"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  defp status_color("reception"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp status_color("assembly"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp status_color("mounting"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  defp status_color("final_check"), do: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
  defp status_color("completed"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp status_color("cancelled"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp status_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  defp status_text("new_order"), do: "Nueva Orden"
  defp status_text("reception"), do: "Recepción"
  defp status_text("assembly"), do: "Ensamblaje"
  defp status_text("mounting"), do: "Montaje"
  defp status_text("final_check"), do: "Final Check"
  defp status_text("completed"), do: "Completada"
  defp status_text("cancelled"), do: "Cancelada"
  defp status_text(_), do: "Desconocido"
end 