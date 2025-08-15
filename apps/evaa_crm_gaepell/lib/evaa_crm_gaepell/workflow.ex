defmodule EvaaCrmGaepell.Workflow do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "workflows" do
    field :name, :string
    field :description, :string
    field :workflow_type, :string
    field :is_active, :boolean, default: true
    field :color, :string, default: "#3B82F6"
    
    belongs_to :business, EvaaCrmGaepell.Business
    has_many :workflow_states, EvaaCrmGaepell.WorkflowState
    has_many :workflow_transitions, EvaaCrmGaepell.WorkflowTransition
    has_many :workflow_assignments, EvaaCrmGaepell.WorkflowAssignment
    
    timestamps()
  end

  @doc false
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:name, :description, :workflow_type, :is_active, :color, :business_id])
    |> validate_required([:name, :workflow_type, :business_id])
    |> validate_inclusion(:workflow_type, ["maintenance", "production", "events", "leads", "tickets"])
    |> foreign_key_constraint(:business_id)
  end

  # Obtener workflows por tipo y business
  def get_workflows_by_type(business_id, workflow_type) do
    from(w in __MODULE__,
      where: w.business_id == ^business_id and w.workflow_type == ^workflow_type and w.is_active == true,
      order_by: w.name
    )
  end

  # Crear workflow con estados predefinidos
  def create_with_states(attrs, states) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:workflow, changeset(%__MODULE__{}, attrs))
    |> Ecto.Multi.insert_all(:states, EvaaCrmGaepell.WorkflowState, states)
    |> EvaaCrmGaepell.Repo.transaction()
  end
end 