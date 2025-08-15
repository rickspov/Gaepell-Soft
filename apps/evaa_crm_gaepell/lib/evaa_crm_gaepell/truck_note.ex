defmodule EvaaCrmGaepell.TruckNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "truck_notes" do
    field :content, :string
    field :note_type, :string, default: "general"

    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket
    belongs_to :production_order, EvaaCrmGaepell.ProductionOrder
    belongs_to :user, EvaaCrmGaepell.User
    belongs_to :business, EvaaCrmGaepell.Business

    timestamps()
  end

  @doc false
  def changeset(truck_note, attrs) do
    truck_note
    |> cast(attrs, [:content, :note_type, :truck_id, :maintenance_ticket_id, :production_order_id, :user_id, :business_id])
    |> validate_required([:content, :truck_id, :user_id, :business_id])
    |> validate_inclusion(:note_type, ["general", "maintenance", "production", "warning", "info"])
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:maintenance_ticket_id)
    |> foreign_key_constraint(:production_order_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:business_id)
  end

  def note_type_label("general"), do: "General"
  def note_type_label("maintenance"), do: "Mantenimiento"
  def note_type_label("production"), do: "Producción"
  def note_type_label("warning"), do: "Advertencia"
  def note_type_label("info"), do: "Información"
  def note_type_label(_), do: "General"

  def note_type_color("general"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  def note_type_color("maintenance"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  def note_type_color("production"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  def note_type_color("warning"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  def note_type_color("info"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  def note_type_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
end 