defmodule EvaaCrmGaepell.Repo.Migrations.CreateTruckModels do
  use Ecto.Migration

  def change do
    create table(:truck_models) do
      add :brand, :string, null: false
      add :model, :string, null: false
      add :year, :integer
      add :capacity, :string
      add :fuel_type, :string
      add :dimensions, :string
      add :weight, :string
      add :engine, :string
      add :transmission, :string
      add :usage_count, :integer, default: 1
      add :last_used_at, :utc_datetime
      add :business_id, references(:businesses, on_delete: :delete_all), null: false

      timestamps()
    end

    # Índices para optimizar búsquedas
    create index(:truck_models, [:business_id])
    create index(:truck_models, [:brand])
    create index(:truck_models, [:model])
    create index(:truck_models, [:usage_count])
    create index(:truck_models, [:last_used_at])
    
    # Índice único para evitar duplicados
    create unique_index(:truck_models, [:brand, :model, :year, :business_id], name: :truck_models_brand_model_year_business_index)
  end
end
