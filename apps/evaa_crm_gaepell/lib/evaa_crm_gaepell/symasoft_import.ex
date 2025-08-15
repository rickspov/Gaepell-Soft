defmodule EvaaCrmGaepell.SymasoftImport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "symasoft_imports" do
    field :filename, :string
    field :file_path, :string
    field :content_hash, :string
    field :import_status, :string, default: "pending"
    field :processed_at, :utc_datetime
    field :error_message, :string

    # Nuevos campos para cotizaciones
    field :quotation_number, :string
    field :quotation_date, :date
    field :quotation_amount, :decimal
    field :quotation_status, :string, default: "pending"
    field :quotation_notes, :string

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :user, EvaaCrmGaepell.User
    
    # Nuevas asociaciones
    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket
    belongs_to :production_order, EvaaCrmGaepell.ProductionOrder

    timestamps()
  end

  @doc false
  def changeset(symasoft_import, attrs) do
    symasoft_import
    |> cast(attrs, [
      :filename, :file_path, :content_hash, :import_status, :processed_at, :error_message, 
      :business_id, :user_id, :truck_id, :maintenance_ticket_id, :production_order_id,
      :quotation_number, :quotation_date, :quotation_amount, :quotation_status, :quotation_notes
    ])
    |> validate_required([:filename, :file_path, :content_hash, :business_id, :user_id])
    |> validate_inclusion(:import_status, ["pending", "processing", "completed", "failed"])
    |> validate_inclusion(:quotation_status, ["pending", "approved", "rejected", "completed"])
  end
end 