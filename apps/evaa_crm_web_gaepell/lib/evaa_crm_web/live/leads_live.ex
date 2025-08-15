defmodule EvaaCrmWebGaepell.LeadsLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Lead, Company, Contact, ProductionOrder, Repo, WorkflowService, WorkflowState}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(EvaaCrmGaepell.PubSub, "leads:updated")
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "CRM - Prospectos")
     |> assign(:leads, [])
     |> assign(:companies, [])
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:filter_source, "all")
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:show_form, false)
     |> assign(:editing_lead, nil)
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)
     |> assign(:editing_status_id, nil)
     |> load_leads()
     |> load_companies()}
  end

  @impl true
  def handle_info({:lead_status_updated, _lead_id, _new_status}, socket) do
    {:noreply, load_leads(socket)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, 
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> load_leads()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_status, status)
     |> assign(:page, 1)
     |> load_leads()}
  end

  @impl true
  def handle_event("filter_source", %{"source" => source}, socket) do
    {:noreply, 
     socket
     |> assign(:filter_source, source)
     |> assign(:page, 1)
     |> load_leads()}
  end

  @impl true
  def handle_event("show_form", %{"lead_id" => lead_id}, socket) do
    lead = if lead_id == "new" do
      %Lead{}
    else
      Repo.get(Lead, lead_id)
    end
    
    {:noreply, 
     socket
     |> assign(:show_form, true)
     |> assign(:editing_lead, lead)}
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_form, false)
     |> assign(:editing_lead, nil)}
  end

  @impl true
  def handle_event("save_lead", %{"lead" => lead_params}, socket) do
    # For demo purposes, use business_id = 1 (Spa Demo)
    lead_params = Map.put(lead_params, "business_id", 1)
    
    case save_lead(socket.assigns.editing_lead, lead_params) do
      {:ok, _lead} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Prospecto guardado exitosamente")
         |> assign(:show_form, false)
         |> assign(:editing_lead, nil)
         |> load_leads()}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :editing_lead, %{socket.assigns.editing_lead | action: :insert, errors: changeset.errors})}
    end
  end

  @impl true
  def handle_event("show_delete_confirm", %{"id" => id, "type" => "lead"}, socket) do
    lead = Repo.get(Lead, id)
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, true)
     |> assign(:delete_target, %{id: id, type: "lead", name: lead.name})}
  end

  @impl true
  def handle_event("hide_delete_confirm", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    case socket.assigns.delete_target do
      %{id: id, type: "lead"} ->
        lead = Repo.get(Lead, id)
        case Repo.delete(lead) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Prospecto eliminado exitosamente")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_leads()}
          
          {:error, _} ->
            {:noreply, 
             socket
             |> put_flash(:error, "Error al eliminar el prospecto")
             |> assign(:show_delete_confirm, false)
             |> assign(:delete_target, nil)
             |> load_leads()}
        end
      
      _ ->
        {:noreply, 
         socket
         |> put_flash(:error, "Tipo de eliminación no válido")
         |> assign(:show_delete_confirm, false)
         |> assign(:delete_target, nil)}
    end
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, 
     socket
     |> assign(:page, String.to_integer(page))
     |> load_leads()}
  end

  @impl true
  def handle_event("edit_status", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_status_id, String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel_edit_status", %{"id" => id, "value" => status}, socket) do
    # Actualizar automáticamente el estado del lead usando solo el campo status
    lead = Repo.get(Lead, String.to_integer(id))
    if lead && status in ["new", "contacted", "qualified", "converted", "lost"] do
      case Lead.changeset(lead, %{status: status}) |> Repo.update() do
        {:ok, updated_lead} ->
          # Si el estado cambió a "converted", crear contacto y orden de producción
          if status == "converted" do
            case convert_lead_to_contact_and_production_order(updated_lead) do
              {:ok, _contact} ->
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, socket |> put_flash(:info, "Prospecto convertido exitosamente. Se creó el contacto y la orden de producción.") |> load_leads()}
              {:error, error_message} ->
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, socket |> put_flash(:warning, "Estado actualizado pero hubo un problema al crear el contacto: #{error_message}") |> load_leads()}
            end
          else
            # Broadcast para que otros LiveViews recarguen leads
            Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
            {:noreply, socket |> put_flash(:info, "Estado del prospecto actualizado") |> load_leads()}
          end
        {:error, _changeset} ->
          {:noreply, socket |> put_flash(:error, "Error al actualizar el estado") |> load_leads()}
      end
    else
      {:noreply, socket |> put_flash(:error, "Lead o estado inválido") |> load_leads()}
    end
  end

  @impl true
  def handle_event("update_lead_status", %{"value" => status, "_target" => ["value"]}, socket) do
    # Obtener el ID del lead desde el editing_status_id
    lead_id = socket.assigns.editing_status_id
    if lead_id do
      lead = Repo.get(Lead, lead_id)
      if lead do
          case Lead.changeset(lead, %{status: status}) |> Repo.update() do
            {:ok, updated_lead} ->
              # Si el estado cambió a "converted", crear contacto y orden de producción
              if status == "converted" do
                case convert_lead_to_contact_and_production_order(updated_lead) do
                  {:ok, _contact} ->
                    Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                    {:noreply, 
                     socket
                     |> assign(:editing_status_id, nil)
                     |> put_flash(:info, "Prospecto convertido exitosamente. Se creó el contacto y la orden de producción.")
                     |> load_leads()}
                  {:error, error_message} ->
                    Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                    {:noreply, 
                     socket
                     |> assign(:editing_status_id, nil)
                     |> put_flash(:warning, "Estado actualizado pero hubo un problema al crear el contacto: #{error_message}")
                     |> load_leads()}
                end
              else
                # Broadcast para que otros LiveViews recarguen leads
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, 
                 socket
                 |> assign(:editing_status_id, nil)
                 |> put_flash(:info, "Estado del prospecto actualizado")
                 |> load_leads()}
              end
            {:error, _changeset} ->
              {:noreply, 
               socket
               |> assign(:editing_status_id, nil)
               |> put_flash(:error, "Error al actualizar el estado")
               |> load_leads()}
        end
      else
        {:noreply, socket |> assign(:editing_status_id, nil) |> put_flash(:error, "Lead no encontrado") |> load_leads()}
      end
    else
      {:noreply, socket |> assign(:editing_status_id, nil) |> put_flash(:error, "ID de lead no válido") |> load_leads()}
    end
  end

  @impl true
  def handle_event("update_lead_status", %{"id" => id, "status" => status}, socket) do
    lead = Repo.get(Lead, String.to_integer(id))
    if lead do
      case Lead.changeset(lead, %{status: status}) |> Repo.update() do
        {:ok, updated_lead} ->
          # Si el estado cambió a "converted", crear contacto y orden de producción
          if status == "converted" do
            case convert_lead_to_contact_and_production_order(updated_lead) do
              {:ok, _contact} ->
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, 
                 socket
                 |> assign(:editing_status_id, nil)
                 |> put_flash(:info, "Prospecto convertido exitosamente. Se creó el contacto y la orden de producción.")
                 |> load_leads()}
              {:error, error_message} ->
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, 
                 socket
                 |> assign(:editing_status_id, nil)
                 |> put_flash(:warning, "Estado actualizado pero hubo un problema al crear el contacto: #{error_message}")
                 |> load_leads()}
            end
          else
            # Broadcast para que otros LiveViews recarguen leads
            Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
            {:noreply, 
             socket
             |> assign(:editing_status_id, nil)
             |> put_flash(:info, "Estado del prospecto actualizado")
             |> load_leads()}
          end
        {:error, _changeset} ->
          {:noreply, 
           socket
           |> assign(:editing_status_id, nil)
           |> put_flash(:error, "Error al actualizar el estado")
           |> load_leads()}
      end
    else
      {:noreply, socket |> assign(:editing_status_id, nil) |> put_flash(:error, "Lead no encontrado") |> load_leads()}
    end
  end

  @impl true
  def handle_event("update_lead_status", %{"id" => id, "value" => status}, socket) do
    lead = Repo.get(Lead, String.to_integer(id))
    if lead do
      case Lead.changeset(lead, %{status: status}) |> Repo.update() do
        {:ok, updated_lead} ->
          # Si el estado cambió a "converted", crear contacto y orden de producción
          if status == "converted" do
            case convert_lead_to_contact_and_production_order(updated_lead) do
              {:ok, _contact} ->
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, 
                 socket
                 |> assign(:editing_status_id, nil)
                 |> put_flash(:info, "Prospecto convertido exitosamente. Se creó el contacto y la orden de producción.")
                 |> load_leads()}
              {:error, error_message} ->
                Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
                {:noreply, 
                 socket
                 |> assign(:editing_status_id, nil)
                 |> put_flash(:warning, "Estado actualizado pero hubo un problema al crear el contacto: #{error_message}")
                 |> load_leads()}
            end
          else
            # Broadcast para que otros LiveViews recarguen leads
            Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "leads:updated", {:lead_status_updated, updated_lead.id, status})
            {:noreply, 
             socket
             |> assign(:editing_status_id, nil)
             |> put_flash(:info, "Estado del prospecto actualizado")
             |> load_leads()}
          end
        {:error, _changeset} ->
          {:noreply, 
           socket
           |> assign(:editing_status_id, nil)
           |> put_flash(:error, "Error al actualizar el estado")
           |> load_leads()}
      end
    else
      {:noreply, socket |> assign(:editing_status_id, nil) |> put_flash(:error, "Lead no encontrado") |> load_leads()}
    end
  end

  defp load_leads(socket) do
    # Cargar leads solo usando el campo status
    query = from l in Lead,
            where: l.business_id == 1,
            preload: [:company],
            order_by: [desc: l.inserted_at]

    query = case socket.assigns.search do
      "" -> query
      search -> 
        search_term = "%#{search}%"
        from l in query,
        where: ilike(l.name, ^search_term) or 
               ilike(l.email, ^search_term) or
               ilike(l.company_name, ^search_term)
    end

    query = case socket.assigns.filter_source do
      "all" -> query
      source -> from l in query, where: l.source == ^source
    end

    total = Repo.aggregate(query, :count)
    leads = query
            |> limit(^socket.assigns.per_page)
            |> offset(^((socket.assigns.page - 1) * socket.assigns.per_page))
            |> Repo.all()

    # Aplicar filtro de estado después de obtener los leads
    leads_filtered = case socket.assigns.filter_status do
      "all" -> leads
      status -> Enum.filter(leads, fn lead -> lead.status == status end)
    end

    assign(socket, :leads, leads_filtered)
    |> assign(:total_leads, length(leads_filtered))
    |> assign(:total_pages, ceil(length(leads_filtered) / socket.assigns.per_page))
  end

  defp load_companies(socket) do
    companies = Repo.all(from c in Company, where: c.business_id == 1, select: {c.name, c.id})
    assign(socket, :companies, companies)
  end

  defp save_lead(nil, params) do
    %Lead{}
    |> Lead.changeset(params)
    |> Repo.insert()
  end

  defp save_lead(lead, params) do
    lead
    |> Lead.changeset(params)
    |> Repo.update()
  end

  defp status_color(status) do
    case status do
      "new" -> "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
      "contacted" -> "bg-blue-100 text-blue-800 dark:bg-blue-700 dark:text-blue-200"
      "qualified" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-700 dark:text-yellow-200"
      "converted" -> "bg-green-100 text-green-800 dark:bg-green-700 dark:text-green-200"
      "lost" -> "bg-red-100 text-red-800 dark:bg-red-700 dark:text-red-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
    end
  end

  defp status_label(status) do
    case status do
      "new" -> "Nuevo"
      "contacted" -> "Contactado"
      "qualified" -> "Calificado"
      "converted" -> "Convertido"
      "lost" -> "Perdido"
      _ -> status
    end
  end

  defp source_label(source) do
    case source do
      "website" -> "Sitio web"
      "referral" -> "Referido"
      "event" -> "Evento"
      "social_media" -> "Redes sociales"
      "other" -> "Otro"
      _ -> source
    end
  end

  defp convert_lead_to_contact_and_production_order(lead) do
    # Log para depuración
    IO.puts("=== INICIANDO CONVERSIÓN DE LEAD ===")
    IO.puts("Lead ID: #{lead.id}")
    IO.puts("Lead Name: #{lead.name}")
    IO.puts("Lead Status: #{lead.status}")
    
    # Obtener el workflow de producción para Furcar (business_id: 1)
    workflow = Repo.get_by(EvaaCrmGaepell.Workflow, workflow_type: "production", business_id: 1)
    
    case workflow do
      nil ->
        IO.puts("❌ No se encontró workflow de producción")
        {:error, "Workflow no encontrado"}
      
      workflow ->
        IO.puts("✅ Workflow encontrado: #{workflow.id}")
        
        # Obtener el estado inicial "new_order"
        initial_state = Repo.get_by(EvaaCrmGaepell.WorkflowState, name: "new_order", workflow_id: workflow.id)
        
        case initial_state do
          nil ->
            IO.puts("❌ No se encontró estado inicial")
            {:error, "Estado inicial no encontrado"}
          
          initial_state ->
            IO.puts("✅ Estado inicial encontrado: #{initial_state.id}")
            
            # Crear el contacto desde el lead
            contact_attrs = %{
              "first_name" => lead.name,
              "last_name" => "Cliente",
              "email" => lead.email,
              "phone" => lead.phone,
              "job_title" => "Cliente",
              "department" => "",
              "address" => "",
              "city" => "",
              "state" => "",
              "country" => "",
              "status" => "active",
              "source" => "other",
              "notes" => "Cliente convertido desde lead: #{lead.name}",
              "business_id" => lead.business_id,
              "company_id" => lead.company_id
            }
            
            IO.puts("Creando contacto con: #{inspect(contact_attrs)}")
            
            case %EvaaCrmGaepell.Contact{}
                 |> EvaaCrmGaepell.Contact.changeset(contact_attrs)
                 |> Repo.insert() do
              {:ok, contact} ->
                IO.puts("✅ Contacto creado exitosamente: #{contact.id}")
                
                # Crear la orden de producción
                production_order_attrs = %{
                  "client_name" => lead.name,
                  "truck_brand" => "Por definir",
                  "truck_model" => "Por definir", 
                  "license_plate" => "Por definir",
                  "box_type" => "dry_box",
                  "specifications" => "Orden creada automáticamente desde lead convertido: #{lead.name}",
                  "estimated_delivery" => Date.add(Date.utc_today(), 30),
                  "status" => "new_order",
                  "notes" => "Orden creada automáticamente desde lead convertido",
                  "business_id" => lead.business_id,
                  "workflow_id" => workflow.id,
                  "workflow_state_id" => initial_state.id,
                  "contact_id" => contact.id
                }
                
                IO.puts("Creando orden de producción con: #{inspect(production_order_attrs)}")
                
                case %EvaaCrmGaepell.ProductionOrder{}
                     |> EvaaCrmGaepell.ProductionOrder.changeset(production_order_attrs)
                     |> Repo.insert() do
                  {:ok, production_order} ->
                    IO.puts("✅ Orden de producción creada exitosamente: #{production_order.id}")
                    IO.puts("=== CONVERSIÓN COMPLETADA ===")
                    {:ok, contact}
                  {:error, changeset} ->
                    IO.puts("❌ Error al crear orden de producción: #{inspect(changeset.errors)}")
                    # Si falla la creación de la orden, eliminar el contacto creado
                    Repo.delete(contact)
                    {:error, changeset}
                end
              
              {:error, changeset} ->
                IO.puts("❌ Error al crear contacto: #{inspect(changeset.errors)}")
                {:error, changeset}
            end
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Prospectos</h1>
          <p class="text-gray-600 dark:text-gray-400 mt-1">Gestión de prospectos y leads</p>
        </div>
        <button 
          phx-click="show_form" 
          phx-value-lead_id="new"
          class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded-lg flex items-center space-x-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          <span>Nuevo Prospecto</span>
        </button>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <div class="flex flex-col md:flex-row gap-4">
          <!-- Search -->
          <div class="flex-1">
            <form phx-change="search" class="relative">
              <input 
                type="text" 
                name="search" 
                value={@search}
                placeholder="Buscar prospectos..." 
                class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
            </form>
          </div>
          
          <!-- Status Filter -->
          <div>
            <select 
              phx-change="filter_status" 
              name="status"
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <option value="all">Todos los estados</option>
              <option value="new">Nuevo</option>
              <option value="contacted">Contactado</option>
              <option value="qualified">Calificado</option>
              <option value="converted">Convertido</option>
              <option value="lost">Perdido</option>
            </select>
          </div>

          <!-- Source Filter -->
          <div>
            <select 
              phx-change="filter_source" 
              name="source"
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <option value="all">Todas las fuentes</option>
              <option value="website">Sitio web</option>
              <option value="referral">Referido</option>
              <option value="event">Evento</option>
              <option value="social_media">Redes sociales</option>
              <option value="other">Otro</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Leads Table -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Prospectos (<%= @total_leads %>)
          </h3>
        </div>
        
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Prospecto</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Contacto</th>
                                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Empresa</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Fuente</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Valor Esperado</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <%= for lead <- @leads do %>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="flex-shrink-0 h-10 w-10">
                        <div class="h-10 w-10 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                          <span class="text-sm font-medium text-green-600 dark:text-green-400">
                            <%= String.first(lead.name || "") %>
                          </span>
                        </div>
                      </div>
                      <div class="ml-4">
                        <div class="text-sm font-medium text-gray-900 dark:text-white">
                          <%= lead.name %>
                        </div>
                        <div class="text-sm text-gray-500 dark:text-gray-400">
                          <%= lead.company_name %>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm text-gray-900 dark:text-white"><%= lead.email %></div>
                    <div class="text-sm text-gray-500 dark:text-gray-400"><%= lead.phone %></div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    <%= if lead.company_name && lead.company_name != "", do: lead.company_name, else: "—" %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <%= if @editing_status_id == lead.id do %>
                      <form phx-change="update_lead_status" phx-blur="cancel_edit_status" class="inline">
                        <select name="value" phx-value-id={lead.id} class="px-2 py-1 text-xs rounded-full border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500">
                          <option value="new" selected={lead.status == "new"}>Nuevo</option>
                          <option value="contacted" selected={lead.status == "contacted"}>Contactado</option>
                          <option value="qualified" selected={lead.status == "qualified"}>Calificado</option>
                          <option value="converted" selected={lead.status == "converted"}>Convertido</option>
                          <option value="lost" selected={lead.status == "lost"}>Perdido</option>
                        </select>
                      </form>
                    <% else %>
                      <span class={[
                        "inline-flex px-2 py-1 text-xs font-semibold rounded-full cursor-pointer transition-all",
                        status_color(lead.status)
                      ]} phx-click="edit_status" phx-value-id={lead.id} title="Editar estado">
                        <%= status_label(lead.status) %>
                      </span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    <%= source_label(lead.source) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    —
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div class="flex space-x-2">
                      <button 
                        phx-click="show_form" 
                        phx-value-lead_id={lead.id}
                        class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                        title="Editar prospecto">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10"/>
                        </svg>
                      </button>
                      <button 
                        phx-click="show_delete_confirm" 
                        phx-value-id={lead.id}
                        phx-value-type="lead"
                        class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                        title="Eliminar prospecto">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"/>
                        </svg>
                      </button>
                      <%= if lead.status != "converted" do %>
                        <button 
                          phx-click="update_lead_status" 
                          phx-value-id={lead.id}
                          phx-value-status="converted"
                          class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300"
                          title="Convertir a cliente">
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
                          </svg>
                        </button>
                      <% end %>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <%= if @leads == [] do %>
          <div class="text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No hay prospectos</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              Comienza agregando tu primer prospecto.
            </p>
          </div>
        <% end %>
      </div>

      <!-- Pagination -->
      <%= if @total_pages > 1 do %>
        <div class="flex justify-center">
          <nav class="flex space-x-2">
            <%= for page <- 1..@total_pages do %>
              <button 
                phx-click="paginate" 
                phx-value-page={page}
                class={[
                  "px-3 py-2 text-sm font-medium rounded-md",
                  if page == @page do
                    "bg-blue-600 text-white"
                  else
                    "text-gray-500 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700"
                  end
                ]}>
                <%= page %>
              </button>
            <% end %>
          </nav>
        </div>
      <% end %>
    </div>

    <!-- Modal Form -->
    <%= if @show_form do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                <%= if @editing_lead.id, do: "Editar Prospecto", else: "Nuevo Prospecto" %>
              </h3>
              <button 
                phx-click="hide_form"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <form phx-submit="save_lead">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="md:col-span-2">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nombre Completo *
                  </label>
                  <input 
                    type="text" 
                    name="lead[name]" 
                    value={@editing_lead.name}
                    required
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Email
                  </label>
                  <input 
                    type="email" 
                    name="lead[email]" 
                    value={@editing_lead.email}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Teléfono
                  </label>
                  <input 
                    type="tel" 
                    name="lead[phone]" 
                    value={@editing_lead.phone}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Empresa
                  </label>
                  <input 
                    type="text" 
                    name="lead[company_name]" 
                    value={@editing_lead.company_name}
                    placeholder="Nombre de la empresa"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Estado
                  </label>
                  <select 
                    name="lead[status]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="new" selected={@editing_lead.status == "new"}>Nuevo</option>
                    <option value="contacted" selected={@editing_lead.status == "contacted"}>Contactado</option>
                    <option value="qualified" selected={@editing_lead.status == "qualified"}>Calificado</option>
                    <option value="converted" selected={@editing_lead.status == "converted"}>Convertido</option>
                    <option value="lost" selected={@editing_lead.status == "lost"}>Perdido</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fuente
                  </label>
                  <select 
                    name="lead[source]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar fuente</option>
                    <option value="website" selected={@editing_lead.source == "website"}>Sitio web</option>
                    <option value="referral" selected={@editing_lead.source == "referral"}>Referido</option>
                    <option value="event" selected={@editing_lead.source == "event"}>Evento</option>
                    <option value="social_media" selected={@editing_lead.source == "social_media"}>Redes sociales</option>
                    <option value="other" selected={@editing_lead.source == "other"}>Otro</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Prioridad
                  </label>
                  <select 
                    name="lead[priority]"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="low" selected={@editing_lead.priority == "low"}>Baja</option>
                    <option value="medium" selected={@editing_lead.priority == "medium"}>Media</option>
                    <option value="high" selected={@editing_lead.priority == "high"}>Alta</option>
                    <option value="urgent" selected={@editing_lead.priority == "urgent"}>Urgente</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Próximo Seguimiento
                  </label>
                  <input 
                    type="datetime-local" 
                    name="lead[next_follow_up]" 
                    value={@editing_lead.next_follow_up}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                </div>
              </div>

              <div class="mt-4">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Notas
                </label>
                <textarea 
                  name="lead[notes]" 
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"><%= @editing_lead.notes %></textarea>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button 
                  type="button"
                  phx-click="hide_form"
                  class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                  Cancelar
                </button>
                <button 
                  type="submit"
                  class="px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-md hover:bg-green-700">
                  Guardar Prospecto
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Delete Confirmation Modal -->
    <%= if @show_delete_confirm do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
          <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                Confirmar Eliminación
              </h3>
              <button 
                phx-click="hide_delete_confirm"
                class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <p class="text-sm text-gray-900 dark:text-white">
              ¿Estás seguro de que quieres eliminar el prospecto "<%= @delete_target.name %>"?
            </p>

            <div class="mt-6 flex justify-end space-x-3">
              <button 
                type="button"
                phx-click="hide_delete_confirm"
                class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                Cancelar
              </button>
              <button 
                type="button"
                phx-click="confirm_delete"
                class="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700">
                Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end 