defmodule EvaaCrm.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :name, :string, null: false
      add :description, :text
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :duration_minutes, :integer, null: false, default: 60
      add :service_type, :string, null: false # individual, package
      add :category, :string, null: false # masaje, terapia, cabina, psicologia, limpieza, laser
      add :is_active, :boolean, default: true, null: false
      add :business_id, references(:businesses, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:services, [:business_id])
    create index(:services, [:service_type])
    create index(:services, [:category])
    create index(:services, [:is_active])
  end
end
