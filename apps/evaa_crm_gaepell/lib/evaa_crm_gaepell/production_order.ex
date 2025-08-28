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
    field :progress, :integer, default: 0

    # Campos de check-out (temporalmente comentados hasta que se resuelva el problema de migración)
    # field :checkout_driver_cedula, :string
    # field :checkout_driver_name, :string
    # field :checkout_details, :string
    # field :checkout_photos, {:array, :string}, default: []
    # field :checkout_signature, :string
    # field :checkout_signature_url, :string
    # field :checkout_date, :utc_datetime
    # field :checkout_notes, :string

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
                    :progress, :business_id, :specialist_id, :workflow_id, :workflow_state_id, :contact_id])
    |> validate_required([:client_name, :truck_brand, :truck_model, :license_plate, :box_type, 
                         :estimated_delivery, :business_id])
    |> validate_inclusion(:box_type, ["refrigerada", "seca"])
    |> validate_inclusion(:status, ["new_order", "reception", "assembly", "mounting", "final_check", "check_out"])
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:specialist_id)
    |> foreign_key_constraint(:workflow_id)
    |> foreign_key_constraint(:workflow_state_id)
    |> foreign_key_constraint(:contact_id)
  end

  def box_types do
    [
      {"Caja Seca", "seca"},
      {"Caja Refrigerada", "refrigerada"}
    ]
  end

  def box_type_label(box_type) do
    case box_type do
      "refrigerada" -> "🧊 Caja Refrigerada"
      "seca" -> "📦 Caja Seca"
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
      "new_order" => "bg-yellow-100 text-yellow-800",
      "reception" => "bg-blue-100 text-blue-800",
      "assembly" => "bg-purple-100 text-purple-800",
      "mounting" => "bg-indigo-100 text-indigo-800",
      "final_check" => "bg-green-100 text-green-800",
      "check_out" => "bg-emerald-100 text-emerald-800"
    }
  end

  @doc """
  Crea una nueva orden de producción
  """
  def create_production_order(attrs) do
    case %__MODULE__{}
         |> changeset(attrs)
         |> EvaaCrmGaepell.Repo.insert() do
      {:ok, order} ->
        {:ok, order}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Actualiza una orden de producción
  """
  def update_production_order(order, attrs, user_id) do
    case order
         |> changeset(attrs)
         |> EvaaCrmGaepell.Repo.update() do
      {:ok, updated_order} ->
        # Crear log de actividad
        EvaaCrmGaepell.ActivityLog.create_log(%{
          "action" => "updated",
          "description" => "actualizó la orden de producción",
          "user_id" => user_id,
          "business_id" => order.business_id,
          "entity_id" => order.id,
          "entity_type" => "production_order"
        })
        {:ok, updated_order}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end 