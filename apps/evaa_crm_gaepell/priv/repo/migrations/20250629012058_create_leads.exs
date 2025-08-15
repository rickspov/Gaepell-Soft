defmodule EvaaCrm.Repo.Migrations.CreateLeads do
  use Ecto.Migration

  def change do
    create table(:leads) do
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :company_id, references(:companies, on_delete: :nilify_all)
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string
      add :phone, :string
      add :company_name, :string
      add :job_title, :string
      add :source, :string
      add :status, :string, default: "new"
      add :priority, :string, default: "medium"
      add :notes, :text
      add :expected_value, :decimal, precision: 10, scale: 2
      add :expected_close_date, :date
      add :assigned_to_id, references(:users, on_delete: :nilify_all)
      add :tags, {:array, :string}, default: []
      timestamps()
    end

    create index(:leads, [:business_id])
    create index(:leads, [:company_id])
    create index(:leads, [:assigned_to_id])
    create index(:leads, [:status])
    create index(:leads, [:priority])
    create index(:leads, [:first_name, :last_name])
  end
end
