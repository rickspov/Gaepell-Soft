defmodule EvaaCrmGaepell.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  # Tipos de eventos específicos para Gaepell
  @furcar_types ~w(maintenance repair delivery pickup inspection training)
  @blidomca_types ~w(armoring installation armor_maintenance armor_repair armor_inspection certification)
  @gaepell_types ~w(meeting billing reporting planning inventory coordination)
  @polimat_types ~w(manufacturing production quality_control shipping logistics)
  @general_types ~w(call email note task)
  
  @all_types @furcar_types ++ @blidomca_types ++ @gaepell_types ++ @polimat_types ++ @general_types
  @priorities ~w(low medium high urgent)
  @statuses ~w(pending in_progress completed cancelled)

  schema "activities" do
    field :type, :string
    field :title, :string
    field :description, :string
    field :due_date, :utc_datetime
    field :completed_at, :utc_datetime
    field :priority, :string, default: "medium"
    field :status, :string, default: "pending"
    field :duration_minutes, :integer, default: 60
    field :tags, {:array, :string}, default: []
    field :color, :string

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :user, EvaaCrmGaepell.User
    belongs_to :contact, EvaaCrmGaepell.Contact
    belongs_to :lead, EvaaCrmGaepell.Lead
    belongs_to :company, EvaaCrmGaepell.Company
    belongs_to :service, EvaaCrmGaepell.Service
    belongs_to :specialist, EvaaCrmGaepell.Specialist
    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket

    timestamps()
  end

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:type, :title, :description, :due_date, :completed_at, :priority,
                   :status, :duration_minutes, :tags, :business_id, :user_id, :contact_id, :lead_id, :company_id,
                   :service_id, :specialist_id, :truck_id, :maintenance_ticket_id, :color])
    |> validate_required([:type, :title, :business_id])
    |> validate_inclusion(:type, @all_types)
    |> validate_inclusion(:priority, @priorities)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 480)
    |> validate_length(:title, min: 1, max: 200)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:contact_id)
    |> foreign_key_constraint(:lead_id)
    |> foreign_key_constraint(:company_id)
    |> foreign_key_constraint(:service_id)
    |> foreign_key_constraint(:specialist_id)
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:maintenance_ticket_id)
  end

  # Funciones helper para obtener tipos por empresa
  def furcar_types, do: @furcar_types
  def blidomca_types, do: @blidomca_types
  def gaepell_types, do: @gaepell_types
  def polimat_types, do: @polimat_types
  def general_types, do: @general_types
  def all_types, do: @all_types

  # Función para obtener el color de la empresa
  def company_color("Gaepell"), do: "blue"
  def company_color("Furcar"), do: "yellow"
  def company_color("Blidomca"), do: "red"
  def company_color("Polimat"), do: "green"
  def company_color(_), do: "gray"

  # Función para obtener tipos disponibles por empresa
  def available_types_for_company("Gaepell"), do: @gaepell_types ++ @general_types
  def available_types_for_company("Furcar"), do: @furcar_types ++ @general_types
  def available_types_for_company("Blidomca"), do: @blidomca_types ++ @general_types
  def available_types_for_company("Polimat"), do: @polimat_types ++ @general_types
  def available_types_for_company(_), do: @all_types

  # Función para obtener el nombre legible del tipo
  def type_name("maintenance"), do: "Mantenimiento"
  def type_name("repair"), do: "Reparación"
  def type_name("delivery"), do: "Entrega"
  def type_name("pickup"), do: "Recogida"
  def type_name("inspection"), do: "Inspección"
  def type_name("training"), do: "Capacitación"
  def type_name("armoring"), do: "Blindaje"
  def type_name("installation"), do: "Instalación"
  def type_name("armor_maintenance"), do: "Mantenimiento de Blindaje"
  def type_name("armor_repair"), do: "Reparación de Blindaje"
  def type_name("armor_inspection"), do: "Inspección de Blindaje"
  def type_name("certification"), do: "Certificación"
  def type_name("meeting"), do: "Reunión"
  def type_name("billing"), do: "Facturación"
  def type_name("reporting"), do: "Reportes"
  def type_name("planning"), do: "Planificación"
  def type_name("inventory"), do: "Inventario"
  def type_name("coordination"), do: "Coordinación"
  def type_name("manufacturing"), do: "Manufactura"
  def type_name("production"), do: "Producción"
  def type_name("quality_control"), do: "Control de Calidad"
  def type_name("shipping"), do: "Envío"
  def type_name("logistics"), do: "Logística"
  def type_name("call"), do: "Llamada"
  def type_name("email"), do: "Email"
  def type_name("note"), do: "Nota"
  def type_name("task"), do: "Tarea"
  def type_name(type), do: String.capitalize(type)
end 