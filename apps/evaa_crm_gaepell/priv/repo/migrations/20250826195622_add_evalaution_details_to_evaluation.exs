defmodule EvaaCrmGaepell.Repo.Migrations.AddEvalautionDetailsToEvaluation do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE evaluations ADD COLUMN IF NOT EXISTS evaluation_details TEXT"
  end

  def down do
    execute "ALTER TABLE evaluations DROP COLUMN IF EXISTS evaluation_details"
  end
end
