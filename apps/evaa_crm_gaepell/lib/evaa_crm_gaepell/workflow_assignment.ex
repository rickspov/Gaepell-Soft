defmodule EvaaCrmGaepell.WorkflowAssignment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "workflow_assignments" do
    field :assignable_type, :string
    field :assignable_id, :integer
    
    belongs_to :workflow, EvaaCrmGaepell.Workflow
    belongs_to :current_state, EvaaCrmGaepell.WorkflowState
    belongs_to :business, EvaaCrmGaepell.Business
    has_many :workflow_state_changes, EvaaCrmGaepell.WorkflowStateChange
    
    timestamps()
  end

  @doc false
  def changeset(workflow_assignment, attrs) do
    workflow_assignment
    |> cast(attrs, [:workflow_id, :assignable_type, :assignable_id, :current_state_id, :business_id])
    |> validate_required([:workflow_id, :assignable_type, :assignable_id, :business_id])
    |> validate_inclusion(:assignable_type, ["activity", "maintenance_ticket", "lead"])
    |> foreign_key_constraint(:workflow_id)
    |> foreign_key_constraint(:current_state_id)
    |> foreign_key_constraint(:business_id)
  end

  # Obtener asignación por tipo y ID
  def get_assignment(assignable_type, assignable_id) do
    from(wa in __MODULE__,
      where: wa.assignable_type == ^assignable_type and wa.assignable_id == ^assignable_id,
      preload: [:workflow, :current_state, :business]
    )
  end

  # Obtener todas las asignaciones de un workflow
  def get_assignments_for_workflow(workflow_id) do
    from(wa in __MODULE__,
      where: wa.workflow_id == ^workflow_id,
      preload: [:workflow, :current_state, :business]
    )
  end

  # Obtener asignaciones por estado
  def get_assignments_by_state(state_id) do
    from(wa in __MODULE__,
      where: wa.current_state_id == ^state_id,
      preload: [:workflow, :current_state, :business]
    )
  end
end 