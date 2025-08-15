defmodule EvaaCrmGaepell.Repo.Migrations.AddEvaluationFieldsToQuotations do
  use Ecto.Migration

  def change do
    alter table(:quotations) do
      # Campos para evaluación de choque
      add :evaluation_type, :string, default: "collision"  # collision, maintenance, other
      add :truck_id, references(:trucks, on_delete: :nilify_all)
      add :evaluation_date, :date
      add :evaluator_name, :string
      add :damage_description, :text
      add :estimated_repair_hours, :integer
      add :parts_cost, :decimal, precision: 12, scale: 2
      add :labor_cost, :decimal, precision: 12, scale: 2
      add :paint_cost, :decimal, precision: 12, scale: 2
      add :other_costs, :decimal, precision: 12, scale: 2
      add :total_evaluation_cost, :decimal, precision: 12, scale: 2
      add :pdf_file_path, :string
      add :pdf_uploaded_at, :utc_datetime
      add :extracted_data, :map  # Para almacenar datos extraídos del PDF
      add :evaluation_photos, {:array, :string}, default: []
      add :insurance_company, :string
      add :claim_number, :string
      add :policy_number, :string
      add :deductible_amount, :decimal, precision: 12, scale: 2
      add :approval_status, :string, default: "pending"  # pending, approved, rejected
      add :approval_date, :date
      add :approved_by, :string
      add :approval_notes, :text
    end

    # Índices para mejor rendimiento
    create index(:quotations, [:evaluation_type])
    create index(:quotations, [:truck_id])
    create index(:quotations, [:evaluation_date])
    create index(:quotations, [:approval_status])
    create index(:quotations, [:insurance_company])
  end
end
