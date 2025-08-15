defmodule EvaaCrmWebGaepell.QuotationsLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Repo, Quotation, QuotationOption, Material, MaterialCategory, User, Truck, MaintenanceTicket}
  import Ecto.Query

  @impl true
  def mount(%{"id" => ticket_id}, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil
    
    # Cargar el ticket específico
    ticket = Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload([:truck])
    
    if ticket && ticket.evaluation_type do
      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:selected_ticket, ticket)
       |> assign(:show_ticket_profile, true)
       |> assign(:show_edit_evaluation_modal, false)
       |> assign(:editing_evaluation_ticket, nil)
       |> assign(:show_pdf_upload_modal, false)
       |> assign(:show_photo_upload_modal, false)
       |> assign(:show_form, false)
       |> assign(:editing_ticket, nil)
       |> allow_upload(:evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
       |> assign(:page_title, "Evaluación - #{ticket.title}")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Ticket de evaluación no encontrado")
       |> push_navigate(to: ~p"/quotations")}
    end
  end

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil
    
    evaluation_tickets = load_evaluation_tickets(current_user.business_id)
    trucks = load_trucks(current_user.business_id)
    
    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:evaluation_tickets, evaluation_tickets)
     |> assign(:trucks, trucks)
     |> assign(:show_form, false)
     |> assign(:editing_ticket, nil)
     |> assign(:show_pdf_upload_modal, false)
     |> assign(:show_ticket_profile, false)
     |> assign(:selected_ticket, nil)
     |> assign(:show_edit_evaluation_modal, false)
     |> assign(:editing_evaluation_ticket, nil)
     |> assign(:show_photo_upload_modal, false)
     |> assign(:page_title, "Sistema de Evaluaciones")}
  end

  @impl true
  def handle_event("view_evaluation_ticket", %{"ticket_id" => ticket_id}, socket) do
    ticket = Repo.get(MaintenanceTicket, ticket_id) |> Repo.preload([:truck])
    
    if ticket && ticket.evaluation_type do
      {:noreply, 
       socket
       |> put_flash(:info, "Redirigiendo al ticket de evaluación...")
       |> push_navigate(to: ~p"/quotations/#{ticket.id}")}
    else
      {:noreply, socket |> put_flash(:error, "Ticket de evaluación no encontrado")}
    end
  end

  @impl true
  def handle_event("new_quotation", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/checkin")}
  end

  @impl true
  def handle_event("continue_draft", %{"quotation_id" => quotation_id}, socket) do
    quotation = Repo.get(Quotation, quotation_id) |> Repo.preload(:quotation_options)
    
    if quotation && quotation.status == "draft" do
      # Cargar materiales seleccionados si existen
      selected_materials = load_quotation_materials(quotation)
      
      # Cargar opciones calculadas si existen
      calculated_options = load_quotation_options(quotation)
      
      # Determinar el paso actual basado en si tiene opciones
      current_step = if length(calculated_options) > 0, do: 3, else: (if length(selected_materials) > 0, do: 2, else: 1)
      
      {:noreply,
       socket
       |> assign(:show_form, true)
       |> assign(:editing_quotation, %{
         id: quotation.id,
         quotation_number: quotation.quotation_number,
         client_name: quotation.client_name,
         client_email: quotation.client_email,
         client_phone: quotation.client_phone,
         quantity: quotation.quantity,
         special_requirements: quotation.special_requirements,
         markup_percentage: quotation.markup_percentage
       })
       |> assign(:current_step, current_step)
       |> assign(:selected_materials, selected_materials)
       |> assign(:calculated_options, calculated_options)}
    else
      {:noreply, socket |> put_flash(:error, "Cotización no encontrada o no es un borrador")}
    end
  end

  @impl true
  def handle_event("close_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:editing_quotation, nil)
     |> assign(:current_step, 1)
     |> assign(:selected_materials, [])
     |> assign(:calculated_options, [])}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    current_step = socket.assigns.current_step
    
    case current_step do
      1 -> 
        # Validar información del cliente
        if valid_client_info?(socket.assigns.editing_quotation) do
          {:noreply, assign(socket, :current_step, 2)}
        else
          {:noreply, socket |> put_flash(:error, "Por favor complete la información del cliente")}
        end
      
      2 ->
        # Generar opciones de cotización
        options = generate_quotation_options(socket.assigns.selected_materials, socket.assigns.editing_quotation)
        {:noreply, 
         socket
         |> assign(:current_step, 3)
         |> assign(:calculated_options, options)}
      
      3 ->
        # Guardar cotización
        save_quotation(socket)
    end
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    current_step = socket.assigns.current_step
    if current_step > 1 do
      {:noreply, assign(socket, :current_step, current_step - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_quotation", %{"field" => field, "value" => value}, socket) do
    field_atom = String.to_atom(field)
    converted_value = convert_field_value(field_atom, value)
    updated_quotation = Map.put(socket.assigns.editing_quotation, field_atom, converted_value)
    
    {:noreply, assign(socket, :editing_quotation, updated_quotation)}
  end

  @impl true
  def handle_event("update_quotation", %{"quotation" => quotation_params}, socket) do
    updated_quotation = Map.merge(socket.assigns.editing_quotation, quotation_params)
    
    {:noreply, assign(socket, :editing_quotation, updated_quotation)}
  end

  @impl true
  def handle_event("select_material", %{"material_id" => material_id}, socket) do
    material = Repo.get(Material, material_id)
    selected_materials = socket.assigns.selected_materials
    
    if material && !Enum.any?(selected_materials, fn m -> m.id == material.id end) do
      material_with_quantity = Map.put(material, :quantity, 1.0)
      updated_materials = [material_with_quantity | selected_materials]
      
      {:noreply, assign(socket, :selected_materials, updated_materials)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_material", %{"material_id" => material_id}, socket) do
    material_id = String.to_integer(material_id)
    selected_materials = Enum.reject(socket.assigns.selected_materials, fn m -> m.id == material_id end)
    
    {:noreply, assign(socket, :selected_materials, selected_materials)}
  end

  @impl true
  def handle_event("update_material_quantity", %{"material_id" => material_id, "quantity" => quantity}, socket) do
    material_id = String.to_integer(material_id)
    quantity = String.to_float(quantity)
    
    selected_materials = Enum.map(socket.assigns.selected_materials, fn material ->
      if material.id == material_id do
        Map.put(material, :quantity, quantity)
      else
        material
      end
    end)
    
    {:noreply, assign(socket, :selected_materials, selected_materials)}
  end

  # Helper functions
  defp load_quotations(business_id) do
    Quotation.get_by_business(business_id)
  end

  defp load_evaluation_tickets(business_id) do
    from(t in MaintenanceTicket, 
         where: t.business_id == ^business_id and not is_nil(t.evaluation_type),
         preload: [:truck],
         order_by: [desc: t.inserted_at])
    |> Repo.all()
  end

  defp load_material_categories(business_id) do
    MaterialCategory.get_by_business(business_id)
  end

  defp valid_client_info?(quotation) do
    quotation.client_name != "" && quotation.quantity > 0
  end

  defp generate_quotation_options(selected_materials, quotation) do
    # Calcular costo base de materiales
    base_material_cost = calculate_material_cost(selected_materials, quotation.quantity)
    
    # Generar opciones con diferentes márgenes
    [
      %{
        name: "Opción Premium",
        quality_level: "premium",
        material_cost: base_material_cost,
        markup_percentage: 40.0,
        delivery_time: 5,
        is_recommended: false
      },
      %{
        name: "Opción Estándar",
        quality_level: "standard", 
        material_cost: base_material_cost,
        markup_percentage: 30.0,
        delivery_time: 7,
        is_recommended: true
      },
      %{
        name: "Opción Económica",
        quality_level: "economy",
        material_cost: base_material_cost * 0.8, # 20% menos en materiales
        markup_percentage: 20.0,
        delivery_time: 10,
        is_recommended: false
      }
    ]
    |> Enum.map(fn option ->
      production_cost = option.material_cost + calculate_labor_cost(quotation.quantity)
      final_price = calculate_final_price(production_cost, option.markup_percentage)
      
      Map.merge(option, %{
        production_cost: production_cost,
        final_price: final_price
      })
    end)
  end

  defp calculate_material_cost(materials, quantity) do
    materials
    |> Enum.map(fn material ->
      Decimal.mult(material.cost_per_unit, Decimal.new(material.quantity))
    end)
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
    |> Decimal.mult(Decimal.new(quantity))
  end

  defp calculate_labor_cost(quantity) do
    # Costo base de mano de obra por unidad
    labor_per_unit = Decimal.new("25.0")
    Decimal.mult(labor_per_unit, Decimal.new(quantity))
  end

  defp calculate_final_price(production_cost, markup_percentage) do
    markup_decimal = Decimal.div(Decimal.new(markup_percentage), Decimal.new("100"))
    markup_amount = Decimal.mult(production_cost, markup_decimal)
    Decimal.add(production_cost, markup_amount)
  end

  defp save_quotation(socket) do
    quotation_attrs = %{
      quotation_number: socket.assigns.editing_quotation.quotation_number,
      client_name: socket.assigns.editing_quotation.client_name,
      client_email: socket.assigns.editing_quotation.client_email,
      client_phone: socket.assigns.editing_quotation.client_phone,
      quantity: socket.assigns.editing_quotation.quantity,
      special_requirements: socket.assigns.editing_quotation.special_requirements,
      markup_percentage: socket.assigns.editing_quotation.markup_percentage,
      business_id: 1,
      user_id: socket.assigns.current_user.id
    }
    
    case save_or_update_quotation(socket.assigns.editing_quotation, quotation_attrs) do
      {:ok, quotation} ->
        # Eliminar opciones existentes y guardar las nuevas
        delete_existing_options(quotation.id)
        save_quotation_options(quotation, socket.assigns.calculated_options)
        
        quotations = load_quotations(1)
        
        {:noreply,
         socket
         |> assign(:quotations, quotations)
         |> assign(:show_form, false)
         |> assign(:editing_quotation, nil)
         |> assign(:current_step, 1)
         |> put_flash(:info, "Cotización guardada exitosamente")}
      
      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Error al guardar la cotización")}
    end
  end

  defp save_quotation_options(quotation, options) do
    Enum.each(options, fn option ->
      option_attrs = %{
        option_name: option.name,
        quality_level: option.quality_level,
        production_cost: option.production_cost,
        markup_percentage: Decimal.new(option.markup_percentage),
        final_price: option.final_price,
        delivery_time_days: option.delivery_time,
        is_recommended: option.is_recommended,
        quotation_id: quotation.id
      }
      
      %QuotationOption{} |> QuotationOption.changeset(option_attrs) |> Repo.insert()
    end)
  end

  defp convert_field_value(:quantity, value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 1
    end
  end

  defp convert_field_value(:markup_percentage, value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _remainder} -> decimal
      :error -> Decimal.new("30.0")
    end
  end

  defp convert_field_value(_field, value), do: value

  defp load_quotation_materials(quotation) do
    # Por ahora retornamos una lista vacía, pero aquí podríamos cargar
    # los materiales guardados en la cotización si tuviéramos esa tabla
    []
  end

  defp load_quotation_options(quotation) do
    quotation.quotation_options
    |> Enum.map(fn option ->
      %{
        name: option.option_name,
        quality_level: option.quality_level,
        material_cost: option.production_cost,
        markup_percentage: Decimal.to_float(option.markup_percentage),
        delivery_time: option.delivery_time_days,
        is_recommended: option.is_recommended,
        production_cost: option.production_cost,
        final_price: option.final_price
      }
    end)
  end

  defp save_or_update_quotation(editing_quotation, quotation_attrs) do
    if Map.has_key?(editing_quotation, :id) do
      # Actualizar cotización existente
      quotation = Repo.get(Quotation, editing_quotation.id)
      quotation |> Quotation.changeset(quotation_attrs) |> Repo.update()
    else
      # Crear nueva cotización
      %Quotation{} |> Quotation.changeset(quotation_attrs) |> Repo.insert()
    end
  end

  defp delete_existing_options(quotation_id) do
    EvaaCrmGaepell.Repo.delete_all(
      from qo in EvaaCrmGaepell.QuotationOption,
      where: qo.quotation_id == ^quotation_id
    )
  end

  # Funciones para manejo de PDF y evaluaciones
  @impl true
  def handle_event("show_pdf_upload_modal", _params, socket) do
    {:noreply, assign(socket, :show_pdf_upload_modal, true)}
  end

  @impl true
  def handle_event("hide_pdf_upload_modal", _params, socket) do
    {:noreply, assign(socket, :show_pdf_upload_modal, false)}
  end

  @impl true
  def handle_event("upload_evaluation_pdf", %{"pdf_file" => %{"path" => path, "filename" => filename}}, socket) do
    # Generar nombre único para el archivo
    unique_filename = "evaluation_#{System.system_time()}_#{:rand.uniform(1000)}.pdf"
    dest_path = Path.join("priv/static/uploads", unique_filename)
    
    # Asegurar que el directorio existe
    File.mkdir_p!(Path.dirname(dest_path))
    
    # Copiar el archivo
    File.cp!(path, dest_path)
    
    # Extraer datos del PDF (simulado por ahora)
    extracted_data = extract_pdf_data(dest_path)
    
    # Actualizar la cotización con los datos del PDF
    quotation_attrs = %{
      pdf_file_path: "/uploads/#{unique_filename}",
      pdf_uploaded_at: DateTime.utc_now(),
      extracted_data: extracted_data
    }
    
    case update_quotation_with_pdf_data(socket.assigns.editing_quotation.id, quotation_attrs) do
      {:ok, updated_quotation} ->
        {:noreply,
         socket
         |> assign(:editing_quotation, Map.merge(socket.assigns.editing_quotation, quotation_attrs))
         |> assign(:show_pdf_upload_modal, false)
         |> put_flash(:info, "PDF subido y datos extraídos exitosamente")}
      
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Error al procesar el PDF")}
    end
  end

  @impl true
  def handle_event("approve_evaluation", %{"quotation_id" => quotation_id}, socket) do
    case update_approval_status(quotation_id, "approved", socket.assigns.current_user.name) do
      {:ok, _} ->
        quotations = load_quotations(1)
        {:noreply,
         socket
         |> assign(:quotations, quotations)
         |> put_flash(:info, "Evaluación aprobada exitosamente")}
      
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Error al aprobar la evaluación")}
    end
  end

  @impl true
  def handle_event("reject_evaluation", %{"quotation_id" => quotation_id, "rejection_notes" => notes}, socket) do
    case update_approval_status(quotation_id, "rejected", socket.assigns.current_user.name, notes) do
      {:ok, _} ->
        quotations = load_quotations(1)
        {:noreply,
         socket
         |> assign(:quotations, quotations)
         |> put_flash(:info, "Evaluación rechazada")}
      
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Error al rechazar la evaluación")}
    end
  end

  @impl true
  def handle_event("back_to_evaluations_list", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/quotations")}
  end

  @impl true
  def handle_event("show_edit_evaluation_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_edit_evaluation_modal, true)
     |> assign(:editing_evaluation_ticket, socket.assigns.selected_ticket)}
  end

  @impl true
  def handle_event("hide_edit_evaluation_modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_edit_evaluation_modal, false)
     |> assign(:editing_evaluation_ticket, nil)}
  end

  @impl true
  def handle_event("update_evaluation_ticket", %{"evaluation_ticket" => ticket_params}, socket) do
    case Repo.get(MaintenanceTicket, socket.assigns.selected_ticket.id) do
      nil ->
        {:noreply, socket |> put_flash(:error, "Ticket no encontrado")}
      
      ticket ->
        # Solo actualizar campos específicos de evaluación
        update_attrs = %{
          title: ticket_params["title"],
          description: ticket_params["description"],
          evaluation_notes: ticket_params["evaluation_notes"],
          evaluation_type: ticket_params["evaluation_type"],
          status: ticket_params["status"],
          visible_damage: ticket_params["visible_damage"]
        }
        
        case ticket |> MaintenanceTicket.changeset(update_attrs) |> Repo.update() do
          {:ok, updated_ticket} ->
            # Recargar el ticket actualizado
            updated_ticket_with_truck = Repo.get(MaintenanceTicket, updated_ticket.id) |> Repo.preload([:truck])
            
            {:noreply, 
             socket
             |> assign(:selected_ticket, updated_ticket_with_truck)
             |> assign(:show_edit_evaluation_modal, false)
             |> assign(:editing_evaluation_ticket, nil)
             |> put_flash(:success, "Ticket de evaluación actualizado exitosamente")}
          
          {:error, changeset} ->
            {:noreply, 
             socket
             |> assign(:editing_evaluation_ticket, changeset)
             |> put_flash(:error, "Error al actualizar: #{inspect(changeset.errors)}")}
        end
    end
  end

  @impl true
  def handle_event("show_photo_upload_modal", _params, socket) do
    IO.puts("[DEBUG] Inicializando upload para fotos de evaluación")
    socket = allow_upload(socket, :evaluation_photos, accept: ~w(.jpg .jpeg .png .gif), max_entries: 10, auto_upload: true)
    IO.inspect(socket.assigns.uploads.evaluation_photos, label: "[DEBUG] upload configurado")
    {:noreply, assign(socket, show_photo_upload_modal: true)}
  end

  @impl true
  def handle_event("close_photo_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_photo_upload_modal: false)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :evaluation_photos, ref)}
  end

  @impl true
  def handle_event("upload_evaluation_photos", _params, socket) do
    # Debug: Verificar si hay archivos en el upload
    IO.inspect(socket.assigns.uploads.evaluation_photos.entries, label: "[DEBUG] upload.entries")
    IO.inspect(socket.assigns.uploads.evaluation_photos.errors, label: "[DEBUG] upload.errors")
    
    # Check if there are any files selected and if they're all uploaded
    entries = socket.assigns.uploads.evaluation_photos.entries
    all_present = length(entries) > 0
    uploading_files = Enum.any?(entries, fn entry -> !entry.done? end)
    
    cond do
      !all_present ->
        {:noreply, 
         socket
         |> put_flash(:error, "Por favor selecciona al menos una foto")
         |> assign(:show_photo_upload_modal, true)}
      
      uploading_files ->
        {:noreply, 
         socket
         |> put_flash(:error, "Espera a que se completen todas las subidas antes de guardar")
         |> assign(:show_photo_upload_modal, true)}
      
      true ->
        case save_evaluation_photos(socket) do
          {:ok, _} ->
            # Recargar el ticket con las nuevas fotos
            updated_ticket = Repo.get(MaintenanceTicket, socket.assigns.selected_ticket.id) |> Repo.preload([:truck])
            
            {:noreply, 
             socket
             |> assign(:selected_ticket, updated_ticket)
             |> put_flash(:success, "Fotos de evaluación subidas exitosamente")
             |> assign(:show_photo_upload_modal, false)}
          
          {:error, :no_files} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Por favor selecciona al menos una foto")
             |> assign(:show_photo_upload_modal, true)}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al subir las fotos")
             |> assign(:show_photo_upload_modal, false)}
        end
    end
  end

  # Funciones helper
  defp load_trucks(business_id) do
    Repo.all(
      from t in Truck,
      where: t.business_id == ^business_id,
      order_by: t.brand
    )
  end

  defp extract_pdf_data(pdf_path) do
    # Por ahora retornamos datos simulados
    # En el futuro, aquí se implementaría la extracción real del PDF
    %{
      "total_cost" => "15000.00",
      "parts_cost" => "8000.00",
      "labor_cost" => "5000.00",
      "paint_cost" => "1500.00",
      "other_costs" => "500.00",
      "estimated_hours" => "25",
      "damage_description" => "Daños en parachoques frontal y luces"
    }
  end

  defp save_evaluation_photos(socket) do
    uploads_dir = Path.expand("priv/static/uploads")
    
    uploaded_files = 
      consume_uploaded_entries(socket, :evaluation_photos, fn %{path: path}, entry ->
        # Generate a unique filename with original extension
        ext = Path.extname(entry.client_name)
        filename = "evaluation_#{socket.assigns.selected_ticket.id}_#{System.system_time()}_#{:rand.uniform(1000)}#{ext}"
        dest = Path.join(uploads_dir, filename)
        
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
        # Add photos to the maintenance ticket's damage_photos field
        current_photos = socket.assigns.selected_ticket.damage_photos || []
        new_photos = current_photos ++ files
        
        case socket.assigns.selected_ticket 
             |> MaintenanceTicket.changeset(%{damage_photos: new_photos})
             |> Repo.update() do
          {:ok, _ticket} ->
            {:ok, files}
          {:error, _changeset} ->
            {:error, :save_failed}
        end
    end
  end

  defp update_quotation_with_pdf_data(quotation_id, attrs) do
    quotation = Repo.get(Quotation, quotation_id)
    if quotation do
      quotation |> Quotation.changeset(attrs) |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  defp update_approval_status(quotation_id, status, approved_by, notes \\ nil) do
    quotation = Repo.get(Quotation, quotation_id)
    if quotation do
      attrs = %{
        approval_status: status,
        approved_by: approved_by,
        approval_date: Date.utc_today(),
        approval_notes: notes
      }
      quotation |> Quotation.changeset(attrs) |> Repo.update()
    else
      {:error, :not_found}
    end
  end
end 