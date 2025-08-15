defmodule EvaaCrmGaepell.Repo.Migrations.AddContactIdToProductionOrders do
  use Ecto.Migration

  def change do
    alter table(:production_orders) do
      add :contact_id, references(:contacts, on_delete: :nilify_all)
    end

    create index(:production_orders, [:contact_id])
  end
end 