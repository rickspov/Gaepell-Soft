defmodule EvaaCrmGaepell.TruckDocument do
  use Ecto.Schema
  import Ecto.Changeset

  schema "truck_documents" do
    field :file_path, :string
    field :title, :string
    field :description, :string
    field :document_type, :string, default: "pdf"
    field :uploaded_at, :utc_datetime

    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket
    belongs_to :user, EvaaCrmGaepell.User

    timestamps()
  end

  @doc false
  def changeset(truck_document, attrs) do
    truck_document
    |> cast(attrs, [:file_path, :title, :description, :document_type, :truck_id, :maintenance_ticket_id, :user_id, :uploaded_at])
    |> validate_required([:file_path, :title, :truck_id])
    |> validate_inclusion(:document_type, ["pdf", "photo"])
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:maintenance_ticket_id)
    |> foreign_key_constraint(:user_id)
  end

  def document_type_label("pdf"), do: "PDF"
  def document_type_label("photo"), do: "Foto"
  def document_type_label(_), do: "Documento"

  def document_type_color("pdf"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  def document_type_color("photo"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  def document_type_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
end
