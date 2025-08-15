defmodule EvaaCrm.Repo.Migrations.CreateSpecialists do
  use Ecto.Migration

  def change do
    create table(:specialists) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :specialization, :string, null: false # masajista, terapeuta, psicologa, etc.
      add :is_active, :boolean, default: true, null: false
      add :business_id, references(:businesses, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:specialists, [:business_id])
    create index(:specialists, [:specialization])
    create index(:specialists, [:is_active])
    create unique_index(:specialists, [:email, :business_id])
  end
end
