defmodule EvaaCrm.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :contact_id, references(:contacts, on_delete: :delete_all)
      add :lead_id, references(:leads, on_delete: :delete_all)
      add :company_id, references(:companies, on_delete: :delete_all)
      add :type, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :due_date, :utc_datetime
      add :completed_at, :utc_datetime
      add :priority, :string, default: "medium"
      add :status, :string, default: "pending"
      add :tags, {:array, :string}, default: []
      timestamps()
    end

    create index(:activities, [:business_id])
    create index(:activities, [:user_id])
    create index(:activities, [:contact_id])
    create index(:activities, [:lead_id])
    create index(:activities, [:company_id])
    create index(:activities, [:type])
    create index(:activities, [:status])
    create index(:activities, [:due_date])
  end
end
