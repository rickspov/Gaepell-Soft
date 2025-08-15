defmodule EvaaCrmGaepell.WorkflowState do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "workflow_states" do
    field :name, :string
    field :label, :string
    field :description, :string
    field :order_index, :integer
    field :color, :string, default: "#6B7280"
    field :icon, :string
    field :is_final, :boolean, default: false
    field :is_initial, :boolean, default: false
    
    belongs_to :workflow, EvaaCrmGaepell.Workflow
    has_many :workflow_transitions_from, EvaaCrmGaepell.WorkflowTransition, foreign_key: :from_state_id
    has_many :workflow_transitions_to, EvaaCrmGaepell.WorkflowTransition, foreign_key: :to_state_id
    has_many :workflow_assignments, EvaaCrmGaepell.WorkflowAssignment, foreign_key: :current_state_id
    
    timestamps()
  end

  @doc false
  def changeset(workflow_state, attrs) do
    workflow_state
    |> cast(attrs, [:name, :label, :description, :order_index, :color, :icon, :is_final, :is_initial, :workflow_id])
    |> validate_required([:name, :label, :order_index, :workflow_id])
    |> foreign_key_constraint(:workflow_id)
  end

  # Obtener estados de un workflow ordenados
  def get_states_for_workflow(workflow_id) do
    from(ws in __MODULE__,
      where: ws.workflow_id == ^workflow_id,
      order_by: ws.order_index
    )
  end

  # Obtener estados iniciales de un workflow
  def get_initial_states(workflow_id) do
    from(ws in __MODULE__,
      where: ws.workflow_id == ^workflow_id and ws.is_initial == true,
      order_by: ws.order_index
    )
  end

  # Obtener estados finales de un workflow
  def get_final_states(workflow_id) do
    from(ws in __MODULE__,
      where: ws.workflow_id == ^workflow_id and ws.is_final == true,
      order_by: ws.order_index
    )
  end
end 