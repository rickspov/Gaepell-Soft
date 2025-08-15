defmodule EvaaCrmGaepell.Repo.Migrations.AddFieldsToTrucks do
  use Ecto.Migration

  def change do
    alter table(:trucks) do
      add :capacity, :string
      add :fuel_type, :string
      add :status, :string, default: "active"
      add :business_id, references(:businesses, on_delete: :delete_all)
    end

    create index(:trucks, [:business_id])
  end
end 