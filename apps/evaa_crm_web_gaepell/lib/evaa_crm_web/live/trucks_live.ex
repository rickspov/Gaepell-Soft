defmodule EvaaCrmWebGaepell.TrucksLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Truck, MaintenanceTicket, Quotation, ProductionOrder, Repo}
  import Ecto.Query

  def mount(_params, _session, socket) do
    # Obtener años disponibles para filtros
    available_years = get_available_years()
    
    # Cargar camiones iniciales
    trucks = load_trucks(nil)
    
    # Obtener marcas, modelos y propietarios existentes para autocompletado
    existing_brands = get_existing_brands()
    existing_models = get_existing_models()
    existing_owners = get_existing_owners()
    
    socket = socket
    |> assign(:trucks, trucks)
    |> assign(:available_years, available_years)
    |> assign(:selected_year, "all")
    |> assign(:show_sidebar, true)
    |> assign(:expanded_trucks, [])
    |> assign(:show_truck_form, false)
    |> assign(:editing_truck, nil)
    |> assign(:search_query, "")
    |> assign(:current_user, get_current_user())
    |> assign(:existing_brands, existing_brands)
    |> assign(:existing_models, existing_models)
    |> assign(:existing_owners, existing_owners)

    {:ok, socket}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :show_sidebar, !socket.assigns.show_sidebar)}
  end

  def handle_event("filter_by_year", %{"year" => year}, socket) do
    trucks = load_trucks(year)
    {:noreply, assign(socket, :trucks, trucks) |> assign(:selected_year, year)}
  end

  def handle_event("search_trucks", %{"value" => query}, socket) do
    trucks = search_trucks(query, socket.assigns.selected_year)
    {:noreply, assign(socket, :trucks, trucks) |> assign(:search_query, query)}
  end

  def handle_event("toggle_truck_expanded", %{"truck_id" => truck_id}, socket) do
    truck_id = String.to_integer(truck_id)
    expanded_trucks = socket.assigns.expanded_trucks
    
    new_expanded_trucks = if truck_id in expanded_trucks do
      List.delete(expanded_trucks, truck_id)
    else
      [truck_id | expanded_trucks]
    end
    
    {:noreply, assign(socket, :expanded_trucks, new_expanded_trucks)}
  end

  def handle_event("toggle_all_expanded", _params, socket) do
    expanded_trucks = socket.assigns.expanded_trucks
    all_truck_ids = Enum.map(socket.assigns.trucks, & &1.id)
    
    new_expanded_trucks = if length(expanded_trucks) == length(all_truck_ids) do
      []
    else
      all_truck_ids
    end
    
    {:noreply, assign(socket, :expanded_trucks, new_expanded_trucks)}
  end

  def handle_event("show_new_truck_form", _params, socket) do
    {:noreply, assign(socket, :show_truck_form, true) |> assign(:editing_truck, nil)}
  end

  def handle_event("hide_truck_form", _params, socket) do
    {:noreply, assign(socket, :show_truck_form, false) |> assign(:editing_truck, nil)}
  end

  def handle_event("edit_truck", %{"truck_id" => truck_id}, socket) do
    truck = Repo.get(Truck, truck_id)
    {:noreply, assign(socket, :show_truck_form, true) |> assign(:editing_truck, truck)}
  end

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

  def handle_event("save_truck", %{"truck" => truck_params}, socket) do
    # Debug: Imprimir parámetros
    IO.inspect(truck_params, label: "TRUCK_PARAMS")
    IO.inspect(socket.assigns.editing_truck, label: "EDITING_TRUCK")
    
    # Determinar si es un nuevo camión o una actualización
    is_new_truck = is_nil(socket.assigns.editing_truck) or 
                   (is_struct(socket.assigns.editing_truck, Ecto.Changeset) and 
                    socket.assigns.editing_truck.action == :insert)
    
    IO.inspect(is_new_truck, label: "IS_NEW_TRUCK")
    
    case save_truck(truck_params, socket.assigns.editing_truck, socket.assigns.current_user) do
      {:ok, truck} ->
        IO.inspect(truck, label: "SAVED_TRUCK")
        # Recargar trucks y forzar actualización
        trucks = load_trucks(socket.assigns.selected_year)
        {:noreply, socket
          |> assign(:trucks, trucks)
          |> assign(:show_truck_form, false)
          |> assign(:editing_truck, nil)
          |> put_flash(:info, "Camión guardado exitosamente")
          |> push_event("refresh_table", %{})}
      
      {:error, changeset} ->
        IO.inspect(changeset, label: "ERROR_CHANGESET")
        {:noreply, assign(socket, :editing_truck, changeset)}
    end
  end

  def handle_event("view_truck_profile", %{"truck_id" => truck_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/trucks/#{truck_id}")}
  end

  def handle_event("delete_truck", %{"truck_id" => truck_id}, socket) do
    truck = Repo.get(Truck, truck_id)
    
    case Repo.delete(truck) do
      {:ok, _deleted_truck} ->
        trucks = load_trucks(socket.assigns.selected_year)
        {:noreply, socket
          |> assign(:trucks, trucks)
          |> put_flash(:info, "Camión eliminado exitosamente")}
      
      {:error, _changeset} ->
        {:noreply, socket
          |> put_flash(:error, "Error al eliminar el camión. Verifique que no tenga tickets de mantenimiento asociados.")}
    end
  end

  def handle_event("view_ticket_details", %{"ticket_id" => ticket_id, "ticket_type" => ticket_type}, socket) do
    case ticket_type do
      "maintenance" -> {:noreply, push_navigate(socket, to: ~p"/maintenance/#{ticket_id}")}
      "quotation" -> {:noreply, push_navigate(socket, to: ~p"/quotations")}
      "production" -> {:noreply, push_navigate(socket, to: ~p"/production-orders")}
      _ -> {:noreply, socket}
    end
  end

  # Funciones privadas
  defp get_available_years do
    current_year = DateTime.utc_now().year
    
    # Obtener años únicos de los camiones existentes
    truck_years = Truck
    |> select([t], fragment("EXTRACT(YEAR FROM ?)", t.inserted_at))
    |> distinct(true)
    |> Repo.all()
    |> Enum.map(fn year -> 
      case year do
        %Decimal{} -> Decimal.to_integer(year)
        year when is_number(year) -> trunc(year)
        _ -> nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.sort(:desc)
    
    # Combinar con años recientes si no hay datos
    if Enum.empty?(truck_years) do
      [current_year, current_year - 1, current_year - 2]
    else
      # Agregar años recientes si no están en la lista
      recent_years = [current_year, current_year - 1, current_year - 2]
      (truck_years ++ recent_years)
      |> Enum.uniq()
      |> Enum.sort(:desc)
    end
  end

  defp load_trucks(year_filter) do
    query = Truck
    |> order_by([t], desc: t.inserted_at)
    
    query = case year_filter do
      "all" -> query
      nil -> query
      year when is_binary(year) -> 
        year_int = String.to_integer(year)
        query
        |> where([t], fragment("EXTRACT(YEAR FROM ?)", t.inserted_at) == ^year_int)
      _ -> query
    end
    
    Repo.all(query)
  end

  defp search_trucks(query, year_filter) when byte_size(query) > 0 do
    search_term = "%#{query}%"
    
    Truck
    |> where([t], ilike(t.brand, ^search_term) or ilike(t.model, ^search_term) or ilike(t.license_plate, ^search_term) or ilike(t.owner, ^search_term))
    |> then(fn query -> 
      case year_filter do
        "all" -> query
        year when is_binary(year) -> 
          year_int = String.to_integer(year)
          query
          |> where([t], fragment("EXTRACT(YEAR FROM ?)", t.inserted_at) == ^year_int)
        _ -> query
      end
    end)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  defp search_trucks(_query, year_filter) do
    load_trucks(year_filter)
  end

  defp save_truck(params, nil, current_user) do
    # Crear nuevo camión
    params_with_business = Map.put(params, "business_id", current_user.business_id)
    
    %Truck{}
    |> Truck.changeset(params_with_business)
    |> Repo.insert()
  end

  defp save_truck(params, truck, _current_user) when is_struct(truck, Truck) do
    # Debug: Imprimir información
    IO.inspect(params, label: "SAVE_TRUCK_PARAMS")
    IO.inspect(truck, label: "SAVE_TRUCK_EXISTING_TRUCK")
    
    # Actualizar camión existente
    changeset = Truck.changeset(truck, params)
    IO.inspect(changeset, label: "SAVE_TRUCK_CHANGESET")
    
    case Repo.update(changeset) do
      {:ok, updated_truck} ->
        IO.inspect(updated_truck, label: "SAVE_TRUCK_UPDATED_TRUCK")
        {:ok, updated_truck}
      {:error, error_changeset} ->
        IO.inspect(error_changeset, label: "SAVE_TRUCK_ERROR")
        {:error, error_changeset}
    end
  end

  defp save_truck(params, changeset, current_user) when is_struct(changeset, Ecto.Changeset) do
    # Si es un changeset con acción :insert, crear nuevo camión
    if changeset.action == :insert do
      params_with_business = Map.put(params, "business_id", current_user.business_id)
      
      %Truck{}
      |> Truck.changeset(params_with_business)
      |> Repo.insert()
    else
      # Si es un changeset con acción :update, actualizar
      changeset
    |> Repo.update()
    end
  end

  defp get_current_user do
    # Implementar según tu sistema de autenticación
    # Por ahora devolvemos un usuario mock con los campos necesarios
    %{
      id: 1, 
      business_id: 1, 
      email: "admin@evaa.com",
      first_name: "Admin",
      last_name: "User"
    }
  end

  # Funciones helper para el template
  def get_truck_tickets(truck_id) do
    # Obtener el camión para buscar por placa, marca y modelo
    truck = Repo.get(Truck, truck_id)
    
    if truck do
      # Obtener tickets de mantenimiento
      maintenance_tickets = MaintenanceTicket
      |> where([mt], mt.truck_id == ^truck_id)
      |> select([mt], %{
        id: mt.id,
        type: "maintenance",
        date: mt.entry_date,
        mileage: mt.mileage,
        notes: mt.description,
        status: mt.status
      })
      |> Repo.all()

      # Obtener órdenes de producción que coincidan con la placa, marca y modelo del camión
      production_orders = ProductionOrder
      |> where([po], po.license_plate == ^truck.license_plate or 
                    (po.truck_brand == ^truck.brand and po.truck_model == ^truck.model))
      |> select([po], %{
        id: po.id,
        type: "production",
        date: po.estimated_delivery,
        mileage: nil,
        notes: po.specifications,
        status: po.status,
        client_name: po.client_name,
        box_type: po.box_type
      })
      |> Repo.all()
      |> Enum.map(fn order ->
        %{order | 
          notes: "#{order.client_name} - #{EvaaCrmGaepell.ProductionOrder.box_type_label(order.box_type)}"
        }
      end)

      # Combinar y ordenar por fecha descendente
      (maintenance_tickets ++ production_orders)
      |> Enum.sort_by(& &1.date, {:desc, Date})
    else
      []
    end
  end

  def get_ticket_type_label("maintenance"), do: "Mantenimiento"
  def get_ticket_type_label("quotation"), do: "Cotización"
  def get_ticket_type_label("production"), do: "Producción"
  def get_ticket_type_label(_), do: "Otro"

  def get_ticket_type_color("maintenance"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  def get_ticket_type_color("quotation"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  def get_ticket_type_color("production"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  def get_ticket_type_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"

  def format_date(date) when is_struct(date, Date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  def format_date(datetime) when is_struct(datetime, DateTime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  def format_date(_), do: "-"

  def truncate_text(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end

  def truncate_text(text, _max_length) when is_binary(text), do: text
  def truncate_text(nil, _max_length), do: "-"
  def truncate_text(_, _max_length), do: "-"

  # Funciones para autocompletado de marcas y modelos
  defp get_existing_brands do
    Truck
    |> select([t], t.brand)
    |> where([t], not is_nil(t.brand) and t.brand != "")
    |> distinct([t], t.brand)
    |> order_by([t], t.brand)
    |> Repo.all()
  end

  defp get_existing_models do
    Truck
    |> select([t], t.model)
    |> where([t], not is_nil(t.model) and t.model != "")
    |> distinct([t], t.model)
    |> order_by([t], t.model)
    |> Repo.all()
  end

  defp get_existing_owners do
    Truck
    |> select([t], t.owner)
    |> where([t], not is_nil(t.owner) and t.owner != "")
    |> distinct([t], t.owner)
    |> order_by([t], t.owner)
    |> Repo.all()
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
end 