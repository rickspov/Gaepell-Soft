defmodule EvaaCrmGaepell.Repo.Migrations.CreateMaterials do
  use Ecto.Migration

  def change do
    create table(:materials) do
      add :name, :string, null: false
      add :description, :text
      add :unit, :string, null: false
      add :cost_per_unit, :decimal, precision: 10, scale: 2, null: false
      add :current_stock, :decimal, precision: 10, scale: 2, default: 0.0
      add :min_stock, :decimal, precision: 10, scale: 2, default: 0.0
      add :supplier, :string
      add :supplier_contact, :text
      add :lead_time_days, :integer, default: 0
      add :is_active, :boolean, default: true, null: false
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :category_id, references(:material_categories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:materials, [:business_id])
    create index(:materials, [:category_id])
    create index(:materials, [:name])
    create index(:materials, [:is_active])
    create index(:materials, [:supplier])
  end
end 