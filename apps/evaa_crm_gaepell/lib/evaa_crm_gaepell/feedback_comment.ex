defmodule EvaaCrmGaepell.FeedbackComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feedback_comments" do
    field :author, :string
    field :body, :string
    belongs_to :feedback_report, EvaaCrmGaepell.FeedbackReport
    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:author, :body, :feedback_report_id])
    |> validate_required([:author, :body, :feedback_report_id])
  end
end 