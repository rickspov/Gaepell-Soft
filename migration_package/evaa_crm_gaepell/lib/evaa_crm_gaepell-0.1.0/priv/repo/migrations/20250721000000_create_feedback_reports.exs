defmodule EvaaCrmGaepell.Repo.Migrations.CreateFeedbackReports do
  use Ecto.Migration

  def change do
    create table(:feedback_reports) do
      add :reporter, :string, null: false
      add :description, :text, null: false
      add :severity, :string, default: "media"
      add :status, :string, default: "abierto"
      add :photos, {:array, :string}, default: []
      timestamps()
    end
  end
end 