defmodule EvaaCrm.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :website, :string
      add :phone, :string
      add :email, :string
      add :address, :text
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string
      add :industry, :string
      add :size, :string
      add :description, :text
      add :status, :string, default: "active"
      timestamps()
    end

    create index(:companies, [:business_id])
    create index(:companies, [:name])
    create index(:companies, [:status])
    create unique_index(:companies, [:business_id, :name])
  end
end
