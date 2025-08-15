defmodule EvaaCrmGaepell.Repo.Migrations.CreateFeedbackComments do
  use Ecto.Migration

  def change do
    create table(:feedback_comments) do
      add :feedback_report_id, references(:feedback_reports, on_delete: :delete_all), null: false
      add :author, :string, null: false
      add :body, :text, null: false
      timestamps()
    end
    create index(:feedback_comments, [:feedback_report_id])
  end
end 