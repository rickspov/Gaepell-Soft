defmodule EvaaCrm.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :company_id, references(:companies, on_delete: :nilify_all)
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string
      add :phone, :string
      add :mobile, :string
      add :job_title, :string
      add :department, :string
      add :address, :text
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string
      add :birth_date, :date
      add :notes, :text
      add :status, :string, default: "active"
      add :source, :string
      add :tags, {:array, :string}, default: []
      timestamps()
    end

    create index(:contacts, [:business_id])
    create index(:contacts, [:company_id])
    create index(:contacts, [:email])
    create index(:contacts, [:status])
    create index(:contacts, [:first_name, :last_name])
  end
end
