defmodule EvaaCrmGaepell.TruckPhoto do
  use Ecto.Schema
  import Ecto.Changeset

  schema "truck_photos" do
    field :photo_path, :string
    field :description, :string
    field :photo_type, :string, default: "general"
    field :uploaded_at, :utc_datetime

    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket
    belongs_to :user, EvaaCrmGaepell.User

    timestamps()
  end

  @doc false
  def changeset(truck_photo, attrs) do
    truck_photo
    |> cast(attrs, [:photo_path, :description, :photo_type, :truck_id, :maintenance_ticket_id, :user_id, :uploaded_at])
    |> validate_required([:photo_path, :truck_id])
    |> validate_inclusion(:photo_type, ["general", "damage", "maintenance", "evaluation", "before", "after"])
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:maintenance_ticket_id)
    |> foreign_key_constraint(:user_id)
  end

  def photo_type_label("general"), do: "General"
  def photo_type_label("damage"), do: "Daño"
  def photo_type_label("maintenance"), do: "Mantenimiento"
  def photo_type_label("evaluation"), do: "Evaluación"
  def photo_type_label("before"), do: "Antes"
  def photo_type_label("after"), do: "Después"
  def photo_type_label(_), do: "General"

  def photo_type_color("general"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  def photo_type_color("damage"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  def photo_type_color("maintenance"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  def photo_type_color("evaluation"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  def photo_type_color("before"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  def photo_type_color("after"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  def photo_type_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
end 