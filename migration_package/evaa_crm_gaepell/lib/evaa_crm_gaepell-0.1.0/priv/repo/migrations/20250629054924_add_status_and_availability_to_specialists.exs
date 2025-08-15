defmodule EvaaCrm.Repo.Migrations.AddStatusAndAvailabilityToSpecialists do
  use Ecto.Migration

  def change do
    alter table(:specialists) do
      add :status, :string, default: "active", null: false
      add :availability, :string
    end

    create index(:specialists, [:status])
  end
end
