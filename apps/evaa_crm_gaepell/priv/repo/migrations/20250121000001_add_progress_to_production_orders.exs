defmodule EvaaCrmGaepell.Repo.Migrations.AddProgressToProductionOrders do
  use Ecto.Migration

  def change do
    alter table(:production_orders) do
      add :progress, :integer, default: 0
    end
  end
end

