defmodule EvaaCrmGaepell.ChangeLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "change_logs" do
    field :entity_type, :string
    field :entity_id, :integer
    field :field, :string
    field :old_value, :string
    field :new_value, :string
    belongs_to :user, EvaaCrmGaepell.User
    timestamps()
  end

  def changeset(changelog, attrs) do
    changelog
    |> cast(attrs, [:entity_type, :entity_id, :field, :old_value, :new_value, :user_id])
    |> validate_required([:entity_type, :entity_id, :field, :user_id])
  end
end 