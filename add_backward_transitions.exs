Mix.Task.run("app.start")

alias EvaaCrmGaepell.{Repo, WorkflowTransition, WorkflowState}
import Ecto.Query

IO.puts("=== AGREGANDO TRANSICIONES HACIA ATRÁS PARA LEADS ===")

# Obtener el workflow de leads (ID 14 según los logs)
workflow_id = 14

# Obtener todos los estados del workflow de leads
states = Repo.all(from ws in WorkflowState, where: ws.workflow_id == ^workflow_id, order_by: ws.order_index)

IO.puts("\\n--- ESTADOS DEL WORKFLOW DE LEADS ---")
for state <- states do
  IO.puts("#{state.id}: #{state.name} (order: #{state.order_index})")
end

# Crear un mapa de estados por ID para fácil acceso
states_map = Map.new(states, fn state -> {state.id, state} end)

# Definir transiciones hacia atrás que queremos agregar (solo las que existen)
backward_transitions = [
  # De qualified a contacted
  {144, 143},  # qualified -> contacted
  # De converted a qualified  
  {146, 144},  # converted -> qualified
  # De converted a contacted
  {146, 143},  # converted -> contacted
]

IO.puts("\\n--- AGREGANDO TRANSICIONES HACIA ATRÁS ---")
for {from_state_id, to_state_id} <- backward_transitions do
  from_state = Map.get(states_map, from_state_id)
  to_state = Map.get(states_map, to_state_id)
  
  if from_state && to_state do
    # Verificar si la transición ya existe
    existing = Repo.one(from wt in WorkflowTransition,
      where: wt.workflow_id == ^workflow_id and 
             wt.from_state_id == ^from_state_id and 
             wt.to_state_id == ^to_state_id)
    
    if existing do
      IO.puts("✅ Transición #{from_state.name} -> #{to_state.name} ya existe")
    else
      # Crear la transición
      transition = %WorkflowTransition{
        workflow_id: workflow_id,
        from_state_id: from_state_id,
        to_state_id: to_state_id,
        label: "#{from_state.name} -> #{to_state.name}",
        color: "gray"
      }
      
      case Repo.insert(transition) do
        {:ok, _} ->
          IO.puts("✅ Agregada transición: #{from_state.name} -> #{to_state.name}")
        {:error, error} ->
          IO.puts("❌ Error agregando transición #{from_state.name} -> #{to_state.name}: #{inspect(error)}")
      end
    end
  else
    IO.puts("❌ Estado no encontrado: from_state_id=#{from_state_id}, to_state_id=#{to_state_id}")
  end
end

IO.puts("\\n--- VERIFICACIÓN FINAL ---")
# Mostrar todas las transiciones disponibles
all_transitions = Repo.all(from wt in WorkflowTransition,
  where: wt.workflow_id == ^workflow_id,
  order_by: [wt.from_state_id, wt.to_state_id])

IO.puts("Todas las transiciones del workflow de leads:")
for transition <- all_transitions do
  from_state = Map.get(states_map, transition.from_state_id)
  to_state = Map.get(states_map, transition.to_state_id)
  if from_state && to_state do
    IO.puts("  #{from_state.name} -> #{to_state.name}")
  end
end 