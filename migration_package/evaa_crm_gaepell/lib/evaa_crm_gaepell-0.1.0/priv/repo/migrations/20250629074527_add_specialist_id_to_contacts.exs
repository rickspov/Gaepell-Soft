defmodule EvaaCrm.Repo.Migrations.AddSpecialistIdToContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :specialist_id, references(:specialists, on_delete: :nilify_all)
    end

    create index(:contacts, [:specialist_id])
  end
end
