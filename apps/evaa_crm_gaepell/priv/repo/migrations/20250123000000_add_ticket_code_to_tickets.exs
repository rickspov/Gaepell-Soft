defmodule EvaaCrmGaepell.Repo.Migrations.AddTicketCodeToTickets do
  use Ecto.Migration

  def change do
    # Agregar ticket_code a maintenance_tickets
    alter table(:maintenance_tickets) do
      add :ticket_code, :string
    end

    # Agregar ticket_code a evaluations
    alter table(:evaluations) do
      add :ticket_code, :string
    end

    # Agregar ticket_code a production_orders
    alter table(:production_orders) do
      add :ticket_code, :string
    end

    # Crear índices para mejorar el rendimiento de búsquedas
    create index(:maintenance_tickets, [:ticket_code])
    create index(:evaluations, [:ticket_code])
    create index(:production_orders, [:ticket_code])
  end
end

