defmodule EvaaCrmGaepell.WorkflowStateChange do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflow_state_changes" do
    field :notes, :string
    field :metadata, :map, default: %{}
    
    belongs_to :workflow_assignment, EvaaCrmGaepell.WorkflowAssignment
    belongs_to :from_state, EvaaCrmGaepell.WorkflowState
    belongs_to :to_state, EvaaCrmGaepell.WorkflowState
    belongs_to :changed_by, EvaaCrmGaepell.User
    
    timestamps()
  end

  @doc false
  def changeset(workflow_state_change, attrs) do
    workflow_state_change
    |> cast(attrs, [:workflow_assignment_id, :from_state_id, :to_state_id, :changed_by_id, :notes, :metadata])
    |> validate_required([:workflow_assignment_id, :to_state_id, :changed_by_id])
    |> foreign_key_constraint(:workflow_assignment_id)
    |> foreign_key_constraint(:from_state_id)
    |> foreign_key_constraint(:to_state_id)
    |> foreign_key_constraint(:changed_by_id)
  end
end 