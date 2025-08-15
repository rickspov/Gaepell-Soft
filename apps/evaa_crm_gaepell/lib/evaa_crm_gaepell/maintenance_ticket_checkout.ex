defmodule EvaaCrmGaepell.MaintenanceTicketCheckout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance_ticket_checkouts" do
    field :delivered_to_name, :string
    field :delivered_to_id_number, :string
    field :delivered_to_phone, :string
    field :delivered_at, :naive_datetime
    field :photos, {:array, :string}, default: []
    field :signature, :string
    field :notes, :string
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket
    timestamps()
  end

  def changeset(checkout, attrs) do
    checkout
    |> cast(attrs, [:maintenance_ticket_id, :delivered_to_name, :delivered_to_id_number, :delivered_to_phone, :delivered_at, :photos, :signature, :notes])
    |> validate_required([:maintenance_ticket_id, :delivered_to_name, :delivered_at])
  end
end 