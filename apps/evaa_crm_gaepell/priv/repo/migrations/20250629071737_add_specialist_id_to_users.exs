defmodule EvaaCrm.Repo.Migrations.AddSpecialistIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :specialist_id, references(:specialists, on_delete: :nilify_all)
    end
    
    create index(:users, [:specialist_id])
  end
end
