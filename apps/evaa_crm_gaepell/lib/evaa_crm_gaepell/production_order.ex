defmodule EvaaCrmGaepell.ProductionOrder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "production_orders" do
    field :client_name, :string
    field :truck_brand, :string
    field :truck_model, :string
    field :license_plate, :string
    field :box_type, :string
    field :specifications, :string
    field :estimated_delivery, :date
    field :status, :string, default: "new_order"
    field :notes, :string
    field :actual_delivery_date, :date
    field :total_cost, :decimal
    field :materials_used, :string
    field :quality_check_notes, :string
    field :customer_signature, :string
    field :photos, {:array, :string}

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :specialist, EvaaCrmGaepell.Specialist
    belongs_to :workflow, EvaaCrmGaepell.Workflow
    belongs_to :workflow_state, EvaaCrmGaepell.WorkflowState
    belongs_to :contact, EvaaCrmGaepell.Contact

    timestamps()
  end

  @doc false
  def changeset(production_order, attrs) do
    production_order
    |> cast(attrs, [:client_name, :truck_brand, :truck_model, :license_plate, :box_type, 
                    :specifications, :estimated_delivery, :status, :notes, :actual_delivery_date,
                    :total_cost, :materials_used, :quality_check_notes, :customer_signature, :photos,
                    :business_id, :specialist_id, :workflow_id, :workflow_state_id, :contact_id])
    |> validate_required([:client_name, :truck_brand, :truck_model, :license_plate, :box_type, 
                         :estimated_delivery, :business_id])
    |> validate_inclusion(:box_type, ["dry_box", "refrigerated", "flatbed", "tanker", "dump", "custom"])
    |> validate_inclusion(:status, ["new_order", "reception", "assembly", "mounting", "final_check", "check_out"])
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:specialist_id)
    |> foreign_key_constraint(:workflow_id)
    |> foreign_key_constraint(:workflow_state_id)
    |> foreign_key_constraint(:contact_id)
  end

  def box_types do
    [
      {"Caja Seca", "dry_box"},
      {"Caja Refrigerada", "refrigerated"},
      {"Plataforma", "flatbed"},
      {"Cisterna", "tanker"},
      {"Volquete", "dump"},
      {"Personalizada", "custom"}
    ]
  end

  def box_type_label(box_type) do
    case box_type do
      "dry_box" -> "Caja Seca"
      "refrigerated" -> "Caja Refrigerada"
      "flatbed" -> "Plataforma"
      "tanker" -> "Cisterna"
      "dump" -> "Volquete"
      "custom" -> "Personalizada"
      _ -> box_type || "No especificado"
    end
  end

  def status_labels do
    [
      {"Nueva Orden", "new_order"},
      {"Recepción", "reception"},
      {"Ensamblaje", "assembly"},
      {"Montaje", "mounting"},
      {"Final Check", "final_check"},
      {"Check Out", "check_out"}
    ]
  end

  def status_colors do
    %{
      "new_order" => "bg-gray-100 text-gray-800",
      "reception" => "bg-yellow-100 text-yellow-800",
      "assembly" => "bg-blue-100 text-blue-800",
      "mounting" => "bg-purple-100 text-purple-800",
      "final_check" => "bg-green-100 text-green-800",
      "check_out" => "bg-emerald-100 text-emerald-800"
    }
  end
end 