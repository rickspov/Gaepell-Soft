defmodule EvaaCrmGaepell.Repo.Migrations.AddLegalProtectionFieldsToMaintenanceTickets do
  use Ecto.Migration

  def change do
    alter table(:maintenance_tickets) do
      # Información personal del entregador
      add :deliverer_name, :string
      add :document_type, :string
      add :document_number, :string
      add :deliverer_phone, :string
      add :deliverer_email, :string
      add :deliverer_address, :text
      
      # Información laboral/institucional
      add :company_name, :string
      add :position, :string
      add :employee_number, :string
      add :authorization_type, :string
      
      # Condiciones especiales
      add :special_conditions, :text
    end
  end
end
