defmodule EvaaCrm.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :role, :string, null: false
      timestamps()
    end
    create unique_index(:users, [:email])
    create index(:users, [:business_id])
  end
end
