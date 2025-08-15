import Ecto.Query
alias EvaaCrmGaepell.{Repo, Workflow, WorkflowState, WorkflowTransition}

IO.puts("=== ARREGLANDO TRANSICIONES DEL WORKFLOW DE LEADS ===")

# Obtener todos los workflows de leads
workflows = Repo.all(from w in Workflow, where: w.workflow_type == "leads")

Enum.each(workflows, fn workflow ->
  IO.puts("\nProcesando workflow: #{workflow.name} (ID: #{workflow.id})")
  
  # Obtener estados del workflow ordenados
  states = Repo.all(from s in WorkflowState, where: s.workflow_id == ^workflow.id, order_by: s.order_index)
  IO.puts("Estados encontrados: #{length(states)}")
  
  # Crear transiciones secuenciales
  states
  |> Enum.chunk_every(2, 1, :discard)
  |> Enum.each(fn [from_state, to_state] ->
    # Verificar si la transición ya existe
    existing_transition = Repo.one(from t in WorkflowTransition,
      where: t.workflow_id == ^workflow.id and t.from_state_id == ^from_state.id and t.to_state_id == ^to_state.id)
    
    if is_nil(existing_transition) do
      # Crear la transición
      transition = %WorkflowTransition{
        workflow_id: workflow.id,
        from_state_id: from_state.id,
        to_state_id: to_state.id,
        label: "Avanzar a #{to_state.label}",
        color: to_state.color
      }
      
      case Repo.insert(transition) do
        {:ok, created_transition} ->
          IO.puts("  ✅ Transición creada: #{from_state.name} → #{to_state.name}")
        
        {:error, error} ->
          IO.puts("  ❌ Error al crear transición: #{inspect(error)}")
      end
    else
      IO.puts("  ⏭️ Transición ya existe: #{from_state.name} → #{to_state.name}")
    end
  end)
  
  # También crear transiciones de "lost" a "new" (para reactivar leads perdidos)
  lost_state = Enum.find(states, fn s -> s.name == "lost" end)
  new_state = Enum.find(states, fn s -> s.name == "new" end)
  
  if lost_state && new_state do
    existing_transition = Repo.one(from t in WorkflowTransition,
      where: t.workflow_id == ^workflow.id and t.from_state_id == ^lost_state.id and t.to_state_id == ^new_state.id)
    
    if is_nil(existing_transition) do
      transition = %WorkflowTransition{
        workflow_id: workflow.id,
        from_state_id: lost_state.id,
        to_state_id: new_state.id,
        label: "Reactivar lead",
        color: new_state.color
      }
      
      case Repo.insert(transition) do
        {:ok, _} ->
          IO.puts("  ✅ Transición de reactivación creada: lost → new")
        
        {:error, error} ->
          IO.puts("  ❌ Error al crear transición de reactivación: #{inspect(error)}")
      end
    else
      IO.puts("  ⏭️ Transición de reactivación ya existe: lost → new")
    end
  end
end)

IO.puts("\n=== TRANSICIONES ARREGLADAS ===") 