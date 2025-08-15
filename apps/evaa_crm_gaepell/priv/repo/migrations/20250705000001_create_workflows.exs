defmodule EvaaCrmGaepell.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    # Tabla de workflows (plantillas de flujos)
    create table(:workflows) do
      add :name, :string, null: false
      add :description, :text
      add :workflow_type, :string, null: false  # "maintenance", "production", "events"
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :is_active, :boolean, default: true
      add :color, :string, default: "#3B82F6"
      
      timestamps()
    end

    # Tabla de estados de workflow
    create table(:workflow_states) do
      add :name, :string, null: false
      add :label, :string, null: false
      add :description, :text
      add :order_index, :integer, null: false
      add :color, :string, default: "#6B7280"
      add :icon, :string
      add :workflow_id, references(:workflows, on_delete: :delete_all), null: false
      add :is_final, :boolean, default: false
      add :is_initial, :boolean, default: false
      
      timestamps()
    end

    # Tabla de transiciones permitidas entre estados
    create table(:workflow_transitions) do
      add :from_state_id, references(:workflow_states, on_delete: :delete_all), null: false
      add :to_state_id, references(:workflow_states, on_delete: :delete_all), null: false
      add :workflow_id, references(:workflows, on_delete: :delete_all), null: false
      add :label, :string
      add :color, :string, default: "#3B82F6"
      add :requires_approval, :boolean, default: false
      
      timestamps()
    end

    # Tabla de asignaciones de workflow a elementos
    create table(:workflow_assignments) do
      add :workflow_id, references(:workflows, on_delete: :delete_all), null: false
      add :assignable_type, :string, null: false  # "activity", "maintenance_ticket", "lead"
      add :assignable_id, :integer, null: false
      add :current_state_id, references(:workflow_states, on_delete: :restrict)
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      
      timestamps()
    end

    # Tabla de historial de cambios de estado
    create table(:workflow_state_changes) do
      add :workflow_assignment_id, references(:workflow_assignments, on_delete: :delete_all), null: false
      add :from_state_id, references(:workflow_states, on_delete: :restrict)
      add :to_state_id, references(:workflow_states, on_delete: :restrict), null: false
      add :changed_by_id, references(:users, on_delete: :restrict), null: false
      add :notes, :text
      add :metadata, :map, default: %{}
      
      timestamps()
    end

    # Índices para optimizar consultas
    create index(:workflows, [:business_id, :workflow_type])
    create index(:workflow_states, [:workflow_id, :order_index])
    create index(:workflow_transitions, [:workflow_id])
    create index(:workflow_assignments, [:assignable_type, :assignable_id])
    create index(:workflow_assignments, [:workflow_id, :current_state_id])
    create index(:workflow_state_changes, [:workflow_assignment_id])
    create index(:workflow_state_changes, [:changed_by_id])
  end
end 