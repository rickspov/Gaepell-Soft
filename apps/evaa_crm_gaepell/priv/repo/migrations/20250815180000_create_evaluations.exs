defmodule EvaaCrmGaepell.Repo.Migrations.CreateEvaluations do
  use Ecto.Migration

  def change do
    create table(:evaluations) do
      add :title, :string, null: false
      add :description, :text
      add :evaluation_type, :string, default: "otro"
      add :evaluation_date, :utc_datetime
      add :evaluated_by, :string
      add :driver_cedula, :string
      add :location, :string
      add :damage_areas, {:array, :string}, default: []
      add :severity_level, :string, default: "medium"
      add :estimated_cost, :decimal, precision: 10, scale: 2
      add :notes, :text
      add :photos, {:array, :string}, default: []
      add :status, :string, default: "pending"
      add :converted_to_maintenance, :boolean, default: false
      add :maintenance_ticket_id, :integer
      
      # Campos para conversión a mantenimiento
      add :priority, :string, default: "medium"
      add :entry_date, :utc_datetime
      add :mileage, :integer
      add :fuel_level, :string
      add :visible_damage, :text
      add :responsible_signature, :text
      add :signature_url, :string
      add :exit_date, :utc_datetime
      add :exit_notes, :text
      add :color, :string
      
      # Campos de protección legal
      add :deliverer_name, :string
      add :document_type, :string
      add :document_number, :string
      add :deliverer_phone, :string
      add :company_name, :string
      add :position, :string
      add :employee_number, :string
      add :authorization_type, :string
      add :special_conditions, :text

      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :truck_id, references(:trucks, on_delete: :delete_all), null: false
      add :specialist_id, references(:specialists, on_delete: :nilify_all)

      timestamps()
    end

    create index(:evaluations, [:business_id])
    create index(:evaluations, [:truck_id])
    create index(:evaluations, [:status])
    create index(:evaluations, [:evaluation_type])
    create index(:evaluations, [:converted_to_maintenance])
  end
end
