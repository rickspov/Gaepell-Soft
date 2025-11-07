defmodule EvaaCrmGaepell.Repo.Migrations.AddExitDateToProductionOrders do
  use Ecto.Migration

  def change do
    alter table(:production_orders) do
      add :exit_date, :utc_datetime
    end
  end
end


