defmodule EvaaCrmGaepell.WorkflowService do
  import Ecto.Query
  alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, WorkflowAssignment, WorkflowTransition, WorkflowStateChange, Lead}

  @doc """
  Crea workflows predefinidos para un business
  """
  def create_default_workflows(business_id) do
    workflows = [
      # 1. FURCAR - Mantenimiento (Empresa principal)
      %{
        name: "Mantenimiento Furcar",
        description: "Flujo de mantenimiento de camiones en Furcar",
        workflow_type: "maintenance",
        business_id: business_id,
        color: "#F59E0B",
        states: [
          %{name: "check_in", label: "Check In", order_index: 1, color: "#10B981", icon: "check-circle", is_initial: true},
          %{name: "in_workshop", label: "En Taller/Reparación", order_index: 2, color: "#3B82F6", icon: "wrench"},
          %{name: "final_review", label: "Revisión Final", order_index: 3, color: "#8B5CF6", icon: "clipboard-check"},
          %{name: "car_wash", label: "Car Wash", order_index: 4, color: "#06B6D4", icon: "droplets"},
          %{name: "check_out", label: "Check Out", order_index: 5, color: "#059669", icon: "check-square", is_final: true}
        ]
      },
      # 2. FURCAR - Producción (Empresa principal)
      %{
        name: "Producción Cajas Furcar",
        description: "Flujo de producción de cajas para camiones en Furcar",
        workflow_type: "production",
        business_id: business_id,
        color: "#8B5CF6",
        states: [
          %{name: "lead", label: "Lead", order_index: 1, color: "#6B7280", icon: "user", is_initial: true},
          %{name: "quotation", label: "Cotización", order_index: 2, color: "#F59E0B", icon: "file-text"},
          %{name: "approved", label: "Aprobación", order_index: 3, color: "#10B981", icon: "check"},
          %{name: "reception", label: "Recepción", order_index: 4, color: "#3B82F6", icon: "truck"},
          %{name: "assembly", label: "Montaje", order_index: 5, color: "#EF4444", icon: "settings"},
          %{name: "final_check", label: "Final Check", order_index: 6, color: "#8B5CF6", icon: "shield-check"},
          %{name: "check_out", label: "Check Out", order_index: 7, color: "#059669", icon: "package", is_final: true}
        ]
      },
      # 3. BLIDOMCA - Producción (Empresa secundaria)
      %{
        name: "Producción Blidomca",
        description: "Flujo de producción de cajas para camiones en Blidomca",
        workflow_type: "production",
        business_id: business_id,
        color: "#F59E0B",
        states: [
          %{name: "lead", label: "Lead", order_index: 1, color: "#6B7280", icon: "user", is_initial: true},
          %{name: "quotation", label: "Cotización", order_index: 2, color: "#F59E0B", icon: "file-text"},
          %{name: "approved", label: "Aprobación", order_index: 3, color: "#10B981", icon: "check"},
          %{name: "reception", label: "Recepción", order_index: 4, color: "#3B82F6", icon: "truck"},
          %{name: "assembly", label: "Montaje", order_index: 5, color: "#EF4444", icon: "settings"},
          %{name: "final_check", label: "Final Check", order_index: 6, color: "#8B5CF6", icon: "shield-check"},
          %{name: "check_out", label: "Check Out", order_index: 7, color: "#059669", icon: "package", is_final: true}
        ]
      },
      # 4. POLIMAT - Eventos (Empresa terciaria)
      %{
        name: "Eventos Polimat",
        description: "Flujo para eventos, reuniones y seminarios en Polimat",
        workflow_type: "events",
        business_id: business_id,
        color: "#3B82F6",
        states: [
          %{name: "pending", label: "Pendiente", order_index: 1, color: "#6B7280", icon: "clock", is_initial: true},
          %{name: "confirmed", label: "Confirmado", order_index: 2, color: "#10B981", icon: "check-circle"},
          %{name: "in_progress", label: "En Progreso", order_index: 3, color: "#F59E0B", icon: "play"},
          %{name: "completed", label: "Completado", order_index: 4, color: "#059669", icon: "check-square", is_final: true}
        ]
      },
      # 5. TICKETS SIMPLES (Universal - Open/Closed)
      %{
        name: "Tickets Simples",
        description: "Sistema simple de tickets para cualquier empresa",
        workflow_type: "tickets",
        business_id: business_id,
        color: "#6B7280",
        states: [
          %{name: "open", label: "Abierto", order_index: 1, color: "#EF4444", icon: "alert-circle", is_initial: true},
          %{name: "closed", label: "Cerrado", order_index: 2, color: "#10B981", icon: "check-circle", is_final: true}
        ]
      },
      # 6. LEADS (Universal - Pipeline de ventas)
      %{
        name: "Pipeline de Leads",
        description: "Flujo de gestión de leads y prospectos",
        workflow_type: "leads",
        business_id: business_id,
        color: "#10B981",
        states: [
          %{name: "new", label: "Nuevo", order_index: 1, color: "#6B7280", icon: "user-plus", is_initial: true},
          %{name: "contacted", label: "Contactado", order_index: 2, color: "#3B82F6", icon: "phone"},
          %{name: "qualified", label: "Calificado", order_index: 3, color: "#F59E0B", icon: "star"},
          %{name: "converted", label: "Convertido", order_index: 4, color: "#10B981", icon: "check-circle", is_final: true},
          %{name: "lost", label: "Perdido", order_index: 5, color: "#EF4444", icon: "x-circle", is_final: true}
        ]
      }
    ]

    Enum.each(workflows, fn workflow_data ->
      create_workflow_with_states(workflow_data)
    end)
  end

  @doc """
  Crea un workflow con sus estados
  """
  def create_workflow_with_states(%{states: states} = workflow_data) do
    Repo.transaction(fn ->
      # Crear workflow
      workflow = Repo.insert!(Workflow.changeset(%Workflow{}, Map.drop(workflow_data, [:states])))
      
      # Crear estados
      states_with_workflow = Enum.map(states, fn state -> Map.put(state, :workflow_id, workflow.id) end)
      created_states = Enum.map(states_with_workflow, fn state -> Repo.insert!(WorkflowState.changeset(%WorkflowState{}, state)) end)
      
      # Crear transiciones automáticas (secuenciales)
      create_sequential_transitions(workflow.id, created_states)
      
      workflow
    end)
  end

  @doc """
  Crea transiciones secuenciales entre estados
  """
  def create_sequential_transitions(workflow_id, states) do
    states
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [from_state, to_state] ->
      Repo.insert!(%WorkflowTransition{
        workflow_id: workflow_id,
        from_state_id: from_state.id,
        to_state_id: to_state.id,
        label: "Avanzar a #{to_state.label}",
        color: to_state.color
      })
    end)
  end

  @doc """
  Asigna un workflow a un elemento
  """
  def assign_workflow(workflow_id, assignable_type, assignable_id, business_id) do
    # Obtener el estado inicial del workflow
    initial_state = Repo.one(from ws in WorkflowState, 
      where: ws.workflow_id == ^workflow_id and ws.is_initial == true,
      limit: 1)

    if initial_state do
      Repo.insert!(WorkflowAssignment.changeset(%WorkflowAssignment{}, %{
        workflow_id: workflow_id,
        assignable_type: assignable_type,
        assignable_id: assignable_id,
        current_state_id: initial_state.id,
        business_id: business_id
      }))
    else
      {:error, "No se encontró estado inicial para el workflow"}
    end
  end

  @doc """
  Cambia el estado de una asignación
  """
  def change_state(assignment_id, new_state_id, user_id, notes \\ nil) do
    Repo.transaction(fn ->
      assignment = Repo.get!(WorkflowAssignment, assignment_id)
      new_state = Repo.get!(WorkflowState, new_state_id)
      
      # Verificar que la transición es válida
      transition = Repo.one(from wt in WorkflowTransition,
        where: wt.workflow_id == ^assignment.workflow_id and 
               wt.from_state_id == ^assignment.current_state_id and 
               wt.to_state_id == ^new_state_id)

      if transition do
        # Actualizar asignación
        updated_assignment = Repo.update!(WorkflowAssignment.changeset(assignment, %{
          current_state_id: new_state_id
        }))

        # Si es lead, actualizar el status
        if assignment.assignable_type == "lead" do
          lead = Repo.get!(Lead, assignment.assignable_id)
          Repo.update!(Lead.changeset(lead, %{status: new_state.name}))
        end

        # Registrar cambio
        Repo.insert!(%WorkflowStateChange{
          workflow_assignment_id: assignment_id,
          from_state_id: assignment.current_state_id,
          to_state_id: new_state_id,
          changed_by_id: user_id,
          notes: notes
        })

        updated_assignment
      else
        Repo.rollback("Transición no válida")
      end
    end)
  end

  @doc """
  Obtiene las transiciones disponibles para una asignación
  """
  def get_available_transitions(assignment_id) do
    assignment = Repo.get!(WorkflowAssignment, assignment_id)
    
    Repo.all(from wt in WorkflowTransition,
      where: wt.workflow_id == ^assignment.workflow_id and wt.from_state_id == ^assignment.current_state_id,
      preload: [:from_state, :to_state])
  end

  @doc """
  Obtiene el estado actual de un elemento
  """
  def get_current_state(assignable_type, assignable_id) do
    Repo.one(from wa in WorkflowAssignment,
      where: wa.assignable_type == ^assignable_type and wa.assignable_id == ^assignable_id,
      preload: [:current_state, :workflow])
  end

  @doc """
  Obtiene workflows por empresa y tipo
  """
  def get_workflows_by_company_and_type(business_id, workflow_type) do
    Repo.all(from w in Workflow,
      where: w.business_id == ^business_id and w.workflow_type == ^workflow_type and w.is_active == true,
      preload: [workflow_states: ^(from ws in WorkflowState, order_by: ws.order_index)])
  end

  @doc """
  Obtiene el workflow recomendado para un tipo de elemento
  """
  def get_recommended_workflow(business_id, assignable_type, company_name) do
    case {assignable_type, company_name} do
      {"maintenance_ticket", "Furcar"} -> 
        get_workflow_by_name(business_id, "Mantenimiento Furcar")
      {"activity", "Furcar"} when company_name == "Furcar" -> 
        get_workflow_by_name(business_id, "Producción Cajas Furcar")
      {"activity", "Blidomca"} -> 
        get_workflow_by_name(business_id, "Producción Blidomca")
      {"activity", "Polimat"} -> 
        get_workflow_by_name(business_id, "Eventos Polimat")
      _ -> 
        get_workflow_by_name(business_id, "Tickets Simples")
    end
  end

  defp get_workflow_by_name(business_id, name) do
    Repo.one(from w in Workflow,
      where: w.business_id == ^business_id and w.name == ^name and w.is_active == true,
      preload: [workflow_states: ^(from ws in WorkflowState, order_by: ws.order_index)])
  end
end 