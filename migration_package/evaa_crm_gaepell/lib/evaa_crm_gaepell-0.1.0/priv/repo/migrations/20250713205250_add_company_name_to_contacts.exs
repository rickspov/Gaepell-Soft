defmodule EvaaCrmGaepell.Repo.Migrations.AddCompanyNameToContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :company_name, :string
    end
  end
end
