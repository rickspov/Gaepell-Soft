defmodule EvaaCrmGaepell.Repo.Migrations.AddEvaluationFieldsToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      # Campos para evaluación
      add :evaluation_type, :string, default: "maintenance"  # maintenance, collision, other
      add :evaluation_notes, :text
      add :estimated_repair_cost, :decimal, precision: 12, scale: 2
      add :insurance_claim_number, :string
      add :insurance_company, :string
    end

    # Índices para mejor rendimiento
    create index(:maintenance_tickets, [:evaluation_type])
    create index(:maintenance_tickets, [:insurance_company])
  end
end
