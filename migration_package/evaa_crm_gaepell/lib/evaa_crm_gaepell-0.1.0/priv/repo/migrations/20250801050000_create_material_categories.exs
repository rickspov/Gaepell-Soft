defmodule EvaaCrmGaepell.Repo.Migrations.CreateMaterialCategories do
  use Ecto.Migration

  def change do
    create table(:material_categories) do
      add :name, :string, null: false
      add :description, :text
      add :color, :string, default: "#3b82f6"
      add :business_id, references(:businesses, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:material_categories, [:business_id])
    create index(:material_categories, [:name])
  end
end 