defmodule EvaaCrmGaepell.Repo.Migrations.CreateQuotationOptions do
  use Ecto.Migration

  def change do
    create table(:quotation_options) do
      add :option_name, :string, null: false
      add :material_configuration, :map # JSONB for material configuration
      add :quality_level, :string, null: false
      add :production_cost, :decimal, precision: 12, scale: 2, null: false
      add :markup_percentage, :decimal, precision: 5, scale: 2, null: false
      add :final_price, :decimal, precision: 12, scale: 2, null: false
      add :delivery_time_days, :integer, default: 0
      add :is_recommended, :boolean, default: false
      add :quotation_id, references(:quotations, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:quotation_options, [:quotation_id])
    create index(:quotation_options, [:quality_level])
    create index(:quotation_options, [:is_recommended])
  end
end 