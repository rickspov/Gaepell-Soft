defmodule EvaaCrm.Repo.Migrations.AddServiceFieldsToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :service_id, references(:services, on_delete: :restrict)
      add :specialist_id, references(:specialists, on_delete: :restrict)
      # package_assignment_id removido - la tabla package_assignments no existe
      # add :package_assignment_id, references(:package_assignments, on_delete: :restrict)
      add :service_number, :integer # número del servicio dentro del paquete (1, 2, 3...)
      add :is_package_service, :boolean, default: false
    end

    create index(:activities, [:service_id])
    create index(:activities, [:specialist_id])
    # create index(:activities, [:package_assignment_id]) # Removido - tabla no existe
    create index(:activities, [:is_package_service])
  end
end
