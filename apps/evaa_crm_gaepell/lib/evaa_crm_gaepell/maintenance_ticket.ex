defmodule EvaaCrmGaepell.MaintenanceTicket do
  use Ecto.Schema
  import Ecto.Changeset
  alias EvaaCrmGaepell.ActivityLog

  schema "maintenance_tickets" do
    field :title, :string
    field :description, :string
    field :priority, :string, default: "medium"
    field :entry_date, :utc_datetime
    field :mileage, :integer
    field :fuel_level, :string
    field :visible_damage, :string
    field :damage_photos, {:array, :string}, default: []
    field :responsible_signature, :string
    field :signature_url, :string
    field :status, :string, default: "check_in"
    field :exit_date, :utc_datetime
    field :exit_notes, :string
    field :color, :string
    
    # Campos de protección legal
    field :deliverer_name, :string
    field :document_type, :string
    field :document_number, :string
    field :deliverer_phone, :string
    field :company_name, :string
    field :position, :string
    field :employee_number, :string
    field :authorization_type, :string
    field :special_conditions, :string
    
    # Campos para diferenciar entre mantenimiento y órdenes de producción
    field :entry_type, :string, default: "maintenance"
    field :production_status, :string, default: "pending_quote"
    field :box_type, :string
    field :estimated_delivery, :date

    # Campos para evaluación
    field :evaluation_type, :string, default: "maintenance"
    field :evaluation_notes, :string
    field :estimated_repair_cost, :decimal
    field :insurance_claim_number, :string
    field :insurance_company, :string
    field :warranty_details, :string
    field :progress, :integer, default: 0
    field :ticket_code, :string

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
    belongs_to :quotation, EvaaCrmGaepell.Quotation
    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :specialist, EvaaCrmGaepell.Specialist
    has_many :activities, EvaaCrmGaepell.Activity

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :description, :priority, :truck_id, :specialist_id, :entry_date, :mileage, :fuel_level, :visible_damage, :damage_photos, :responsible_signature, :signature_url, :status, :exit_date, :exit_notes, :business_id, :color, :deliverer_name, :document_type, :document_number, :deliverer_phone, :company_name, :position, :employee_number, :authorization_type, :special_conditions, :entry_type, :production_status, :quotation_id, :box_type, :estimated_delivery, :evaluation_type, :evaluation_notes, :estimated_repair_cost, :insurance_claim_number, :insurance_company, :warranty_details, :progress, :ticket_code])
    |> validate_required([:title, :truck_id, :business_id])
    |> validate_inclusion(:priority, ["low", "medium", "high", "urgent"])
    |> validate_inclusion(:status, ["check_in", "in_workshop", "final_review", "car_wash", "check_out", "cancelled", "recepcion"])
    |> validate_inclusion(:fuel_level, ["empty", "quarter", "half", "three_quarters", "full"])
    |> validate_inclusion(:entry_type, ["maintenance", "production"])
    |> validate_inclusion(:production_status, ["pending_quote", "quoted", "approved", "in_production", "completed"])
    |> validate_inclusion(:box_type, ["plataforma", "caja_seca", "caja_refrigerada", "caja_termica", "caja_especializada", "otro"], allow_nil: true)
    |> validate_inclusion(:evaluation_type, ["maintenance", "collision", "warranty", "other"], allow_nil: true)
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:specialist_id)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:quotation_id)
  end

  @doc """
  Crea un ticket de mantenimiento y registra la actividad
  """
  def create_ticket(attrs, user_id) do
    # Generar código de ticket si no se proporciona uno
    attrs_with_code = if Map.has_key?(attrs, "ticket_code") and not is_nil(attrs["ticket_code"]) do
      attrs
    else
      Map.put(attrs, "ticket_code", EvaaCrmGaepell.TicketCodeGenerator.generate_ticket_code(:maintenance))
    end

    case %__MODULE__{}
         |> changeset(attrs_with_code)
         |> EvaaCrmGaepell.Repo.insert() do
      {:ok, ticket} ->
        # Registrar log de creación
        ActivityLog.log_creation("maintenance_ticket", ticket.id, ticket.title, user_id, ticket.business_id)
        {:ok, ticket}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Actualiza un ticket de mantenimiento y registra cambios de estado
  """
  def update_ticket(ticket, attrs, user_id) do
    old_status = ticket.status
    
    case ticket
         |> changeset(attrs)
         |> EvaaCrmGaepell.Repo.update() do
      {:ok, updated_ticket} ->
        # Registrar cambio de estado si ocurrió
        if updated_ticket.status != old_status do
          ActivityLog.log_status_change("maintenance_ticket", ticket.id, old_status, updated_ticket.status, user_id, ticket.business_id)
        end
        {:ok, updated_ticket}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Funciones para mostrar labels de evaluation_type
  def evaluation_type_label("collision"), do: "Evaluación de Choque"
  def evaluation_type_label("maintenance"), do: "Evaluación de Mantenimiento"
  def evaluation_type_label("warranty"), do: "Garantía"
  def evaluation_type_label("other"), do: "Otro"
  def evaluation_type_label(_), do: "Desconocido"

  def evaluation_type_color("collision"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  def evaluation_type_color("maintenance"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  def evaluation_type_color("warranty"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  def evaluation_type_color("other"), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
  def evaluation_type_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
end 