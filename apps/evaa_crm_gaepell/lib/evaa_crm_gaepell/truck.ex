defmodule EvaaCrmGaepell.Truck do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trucks" do
    field :brand, :string
    field :model, :string
    field :license_plate, :string
    field :chassis_number, :string
    field :vin, :string
    field :color, :string
    field :year, :integer
    field :capacity, :string
    field :fuel_type, :string
    field :status, :string, default: "active"
    field :owner, :string
    field :ficha, :string
    field :general_notes, :string
    field :profile_photo, :string
    field :kilometraje, :integer, default: 0

    belongs_to :business, EvaaCrmGaepell.Business
    has_many :maintenance_tickets, EvaaCrmGaepell.MaintenanceTicket
    has_many :activities, EvaaCrmGaepell.Activity
    has_many :truck_photos, EvaaCrmGaepell.TruckPhoto
    has_many :truck_notes, EvaaCrmGaepell.TruckNote

    timestamps()
  end

  def changeset(truck, attrs) do
    truck
    |> cast(attrs, [:brand, :model, :license_plate, :chassis_number, :vin, :color, :year, :capacity, :fuel_type, :status, :owner, :ficha, :general_notes, :profile_photo, :kilometraje, :business_id])
    |> validate_required([:brand, :model, :license_plate, :business_id])
    |> validate_inclusion(:status, ["active", "maintenance", "inactive"])
    |> validate_inclusion(:fuel_type, ["diesel", "gasoline", "electric", "hybrid"])
    |> validate_number(:kilometraje, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:business_id)
  end

  @doc """
  Crea un nuevo camión
  """
  def create_truck(attrs, user_id) do
    case %__MODULE__{}
         |> changeset(attrs)
         |> EvaaCrmGaepell.Repo.insert() do
      {:ok, truck} ->
        # Registrar log de creación
        EvaaCrmGaepell.ActivityLog.log_creation("truck", truck.id, "#{truck.brand} #{truck.model} (#{truck.license_plate})", user_id, truck.business_id)
        {:ok, truck}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end 