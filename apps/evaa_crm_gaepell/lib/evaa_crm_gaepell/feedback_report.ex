defmodule EvaaCrmGaepell.FeedbackReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feedback_reports" do
    field :reporter, :string
    field :description, :string
    field :severity, :string, default: "media"
    field :status, :string, default: "abierto"
    field :photos, {:array, :string}, default: []
    has_many :comments, EvaaCrmGaepell.FeedbackComment
    timestamps()
  end

  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:reporter, :description, :severity, :status, :photos])
    |> validate_required([:reporter, :description])
    |> validate_inclusion(:severity, ["baja", "media", "alta"])
    |> validate_inclusion(:status, ["abierto", "en_progreso", "cerrado"])
  end
end 