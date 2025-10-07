defmodule EvaaCrmGaepell.Evaluation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EvaaCrmGaepell.ActivityLog

  schema "evaluations" do
    field :title, :string
    field :description, :string
    field :evaluation_type, :string, default: "other"
    field :evaluation_date, :utc_datetime
    field :evaluated_by, :string
    field :driver_cedula, :string
    field :location, :string
    field :damage_areas, {:array, :string}, default: []
    field :severity_level, :string, default: "medium"
    field :estimated_cost, :decimal
    field :notes, :string
    field :photos, {:array, :string}, default: []
    field :status, :string, default: "pending"
    field :converted_to_maintenance, :boolean, default: false
    field :maintenance_ticket_id, :integer
    
    # Campos para conversión a mantenimiento
    field :priority, :string, default: "medium"
    field :entry_date, :utc_datetime
    field :mileage, :integer
    field :fuel_level, :string
    field :visible_damage, :string
    field :responsible_signature, :string
    field :signature_url, :string
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
    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :specialist, EvaaCrmGaepell.Specialist

    timestamps()
  end

  def changeset(evaluation, attrs) do
    evaluation
    |> cast(attrs, [:title, :description, :evaluation_type, :evaluation_date, :evaluated_by, :driver_cedula, :location, :damage_areas, :severity_level, :estimated_cost, :notes, :photos, :status, :converted_to_maintenance, :maintenance_ticket_id, :priority, :entry_date, :mileage, :fuel_level, :visible_damage, :responsible_signature, :signature_url, :exit_date, :exit_notes, :color, :deliverer_name, :document_type, :document_number, :deliverer_phone, :company_name, :position, :employee_number, :authorization_type, :special_conditions, :truck_id, :business_id, :specialist_id, :ticket_code])
    |> validate_required([:title, :truck_id, :business_id, :evaluation_type])
    |> validate_inclusion(:evaluation_type, ["garantia", "colision", "desgaste", "otro"])
    |> validate_inclusion(:severity_level, ["low", "medium", "high", "critical"])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed", "cancelled", "converted"])
    |> validate_inclusion(:priority, ["low", "medium", "high", "urgent"])
    |> validate_inclusion(:fuel_level, ["empty", "quarter", "half", "three_quarters", "full"], allow_nil: true)
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:specialist_id)
  end

  @doc """
  Crea una evaluación y registra la actividad
  """
  def create_evaluation(attrs, user_id) do
    # Generar código de ticket si no se proporciona uno
    attrs_with_code = if Map.has_key?(attrs, "ticket_code") and not is_nil(attrs["ticket_code"]) do
      attrs
    else
      Map.put(attrs, "ticket_code", EvaaCrmGaepell.TicketCodeGenerator.generate_ticket_code(:evaluation))
    end

    # Debug logging
    IO.inspect(attrs_with_code, label: "[DEBUG] Evaluation.create_evaluation attrs")
    IO.inspect(attrs_with_code["damage_areas"], label: "[DEBUG] damage_areas in attrs")
    IO.inspect(attrs_with_code["description"], label: "[DEBUG] description in attrs")
    IO.inspect(attrs_with_code["severity_level"], label: "[DEBUG] severity_level in attrs")
    IO.inspect(attrs_with_code["estimated_cost"], label: "[DEBUG] estimated_cost in attrs")
    
    case %__MODULE__{}
         |> changeset(attrs_with_code)
         |> EvaaCrmGaepell.Repo.insert() do
      {:ok, evaluation} ->
        # Debug logging for created evaluation
        IO.inspect(evaluation, label: "[DEBUG] Created evaluation")
        IO.inspect(evaluation.damage_areas, label: "[DEBUG] damage_areas in created evaluation")
        IO.inspect(evaluation.description, label: "[DEBUG] description in created evaluation")
        
        # Registrar log de creación
        ActivityLog.log_creation("evaluation", evaluation.id, evaluation.title, user_id, evaluation.business_id)
        {:ok, evaluation}
      
      {:error, changeset} ->
        IO.inspect(changeset, label: "[DEBUG] Evaluation creation error")
        {:error, changeset}
    end
  end

  @doc """
  Actualiza una evaluación y registra cambios de estado
  """
  def update_evaluation(evaluation, attrs, user_id) do
    old_status = evaluation.status
    
    case evaluation
         |> changeset(attrs)
         |> EvaaCrmGaepell.Repo.update() do
      {:ok, updated_evaluation} ->
        # Registrar cambio de estado si ocurrió
        if old_status != updated_evaluation.status do
          ActivityLog.log_status_change("evaluation", evaluation.id, old_status, updated_evaluation.status, user_id, evaluation.business_id)
        end
        {:ok, updated_evaluation}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Convierte una evaluación a ticket de mantenimiento
  """
  def convert_to_maintenance_ticket(evaluation, user_id) do
    convert_to_maintenance_ticket_with_data(evaluation, %{}, user_id)
  end

  @doc """
  Convierte una evaluación a ticket de mantenimiento con datos adicionales
  """
  def convert_to_maintenance_ticket_with_data(evaluation, conversion_data, user_id) do
    # Mapear severidad a prioridad
    priority = case evaluation.severity_level do
      "critical" -> "urgent"
      "high" -> "high"
      "medium" -> "medium"
      "low" -> "low"
      _ -> "medium"
    end

    # Crear ticket de mantenimiento basado en la evaluación
    maintenance_attrs = %{
      "title" => evaluation.title,
      "description" => evaluation.description,
      "truck_id" => evaluation.truck_id,
      "business_id" => evaluation.business_id,
      "entry_date" => evaluation.entry_date || DateTime.utc_now(),
      "status" => "check_in",
      "priority" => priority,
      "mileage" => evaluation.mileage,
      "fuel_level" => evaluation.fuel_level,
      "visible_damage" => evaluation.visible_damage,
      "damage_photos" => evaluation.photos,
      "responsible_signature" => evaluation.responsible_signature,
      "signature_url" => evaluation.signature_url,
      "color" => "#8b5cf6", # Purple color for evaluations
      "deliverer_name" => evaluation.deliverer_name,
      "document_type" => evaluation.document_type,
      "document_number" => evaluation.document_number,
      "deliverer_phone" => evaluation.deliverer_phone,
      "company_name" => evaluation.company_name,
      "position" => evaluation.position,
      "employee_number" => evaluation.employee_number,
      "authorization_type" => evaluation.authorization_type,
      "special_conditions" => evaluation.special_conditions,
      # Campos adicionales de la conversión
      "evaluation_type" => conversion_data["evaluation_type"] || "maintenance",
      "estimated_repair_cost" => conversion_data["estimated_repair_cost"] || evaluation.estimated_cost,
      "evaluation_notes" => conversion_data["evaluation_notes"] || evaluation.notes,
      "insurance_claim_number" => conversion_data["insurance_claim_number"],
      "insurance_company" => conversion_data["insurance_company"],
      "warranty_details" => conversion_data["warranty_details"]
    }

    case EvaaCrmGaepell.MaintenanceTicket.create_ticket(maintenance_attrs, user_id) do
      {:ok, maintenance_ticket} ->
        # Actualizar evaluación como convertida
        update_evaluation(evaluation, %{
          "converted_to_maintenance" => true,
          "maintenance_ticket_id" => maintenance_ticket.id,
          "status" => "converted"
        }, user_id)
        
        {:ok, maintenance_ticket}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Obtiene todas las evaluaciones de un negocio
  """
  def get_evaluations_by_business(business_id) do
    EvaaCrmGaepell.Repo.all(
      from e in __MODULE__,
      where: e.business_id == ^business_id,
      order_by: [desc: e.inserted_at],
      preload: [:truck, :specialist]
    )
  end

  @doc """
  Obtiene evaluaciones por estado
  """
  def get_evaluations_by_status(business_id, status) do
    EvaaCrmGaepell.Repo.all(
      from e in __MODULE__,
      where: e.business_id == ^business_id and e.status == ^status,
      order_by: [desc: e.inserted_at],
      preload: [:truck, :specialist]
    )
  end

  @doc """
  Obtiene estadísticas de evaluaciones
  """
  def get_evaluation_stats(business_id) do
    total =
      from(e in __MODULE__,
        where: e.business_id == ^business_id,
        select: count(e.id)
      )
      |> EvaaCrmGaepell.Repo.one()

    pending =
      from(e in __MODULE__,
        where: e.business_id == ^business_id and e.status == "pending",
        select: count(e.id)
      )
      |> EvaaCrmGaepell.Repo.one()

    converted =
      from(e in __MODULE__,
        where: e.business_id == ^business_id and e.converted_to_maintenance == true,
        select: count(e.id)
      )
      |> EvaaCrmGaepell.Repo.one()

    %{
      total: total,
      pending: pending,
      converted: converted
    }
  end
end
