defmodule EvaaCrmGaepell.WorkflowTransition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflow_transitions" do
    field :label, :string
    field :color, :string, default: "#3B82F6"
    field :requires_approval, :boolean, default: false
    
    belongs_to :workflow, EvaaCrmGaepell.Workflow
    belongs_to :from_state, EvaaCrmGaepell.WorkflowState
    belongs_to :to_state, EvaaCrmGaepell.WorkflowState
    
    timestamps()
  end

  @doc false
  def changeset(workflow_transition, attrs) do
    workflow_transition
    |> cast(attrs, [:workflow_id, :from_state_id, :to_state_id, :label, :color, :requires_approval])
    |> validate_required([:workflow_id, :from_state_id, :to_state_id])
    |> foreign_key_constraint(:workflow_id)
    |> foreign_key_constraint(:from_state_id)
    |> foreign_key_constraint(:to_state_id)
  end
end 