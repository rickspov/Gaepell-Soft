defmodule EvaaCrmGaepell.Repo.Migrations.CreateSymasoftImports do
  use Ecto.Migration

  def change do
    create table(:symasoft_imports) do
      add :filename, :string, null: false
      add :file_path, :string, null: false
      add :content_hash, :string, null: false
      add :import_status, :string, default: "pending"
      add :processed_at, :utc_datetime
      add :error_message, :text
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:symasoft_imports, [:business_id])
    create index(:symasoft_imports, [:user_id])
    create index(:symasoft_imports, [:import_status])
    create index(:symasoft_imports, [:content_hash])
  end
end
