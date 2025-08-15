defmodule EvaaCrmGaepell.Service do
  use Ecto.Schema
  import Ecto.Changeset

  schema "services" do
    field :name, :string
    field :description, :string
    field :price, :decimal
    field :duration_minutes, :integer, default: 60
    field :service_type, :string # individual, fleet, emergency
    field :category, :string # mantenimiento, reparacion, diagnostico, emergencia
    field :is_active, :boolean, default: true

    belongs_to :business, EvaaCrmGaepell.Business
    has_many :activities, EvaaCrmGaepell.Activity

    timestamps()
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :description, :price, :duration_minutes, :service_type, :category, :is_active, :business_id])
    |> validate_required([:name, :price, :service_type, :category, :business_id])
    |> validate_inclusion(:service_type, ["individual", "fleet", "emergency"])
    |> validate_inclusion(:category, ["mantenimiento", "reparacion", "diagnostico", "emergencia"])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:duration_minutes, greater_than: 0)
    |> foreign_key_constraint(:business_id)
  end
end 