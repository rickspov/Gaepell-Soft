defmodule EvaaCrmGaepell.Repo.Migrations.UpdateLeadsTable do
  use Ecto.Migration

  def change do
    alter table(:leads) do
      # Renombrar campos existentes
      remove :first_name
      remove :last_name
      remove :job_title
      remove :expected_value
      remove :expected_close_date
      remove :tags
      remove :assigned_to_id
      
      # Agregar nuevos campos
      add :name, :string
      add :assigned_to, :integer
      add :next_follow_up, :utc_datetime
      add :conversion_date, :utc_datetime
      add :user_id, references(:users)
      
      # Modificar campos existentes
      modify :status, :string, default: "new"
      modify :priority, :string, default: "medium"
    end
    
    # Crear índices solo si no existen
    # Nota: Los índices business_id y status ya existen, así que no los creamos
  end
end
