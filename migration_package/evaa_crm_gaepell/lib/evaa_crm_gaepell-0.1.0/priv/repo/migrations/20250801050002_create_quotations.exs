defmodule EvaaCrmGaepell.Repo.Migrations.CreateQuotations do
  use Ecto.Migration

  def change do
    create table(:quotations) do
      add :quotation_number, :string, null: false
      add :client_name, :string, null: false
      add :client_email, :string
      add :client_phone, :string
      add :quantity, :integer, null: false
      add :special_requirements, :text
      add :status, :string, default: "draft", null: false
      add :total_cost, :decimal, precision: 12, scale: 2
      add :markup_percentage, :decimal, precision: 5, scale: 2, default: 30.0
      add :final_price, :decimal, precision: 12, scale: 2
      add :valid_until, :date
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    create index(:quotations, [:business_id])
    create index(:quotations, [:user_id])
    create index(:quotations, [:status])
    create index(:quotations, [:client_name])
    create unique_index(:quotations, [:quotation_number])
  end
end 