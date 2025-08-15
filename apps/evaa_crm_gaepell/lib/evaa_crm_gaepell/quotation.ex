defmodule EvaaCrmGaepell.Quotation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "quotations" do
    field :quotation_number, :string
    field :client_name, :string
    field :client_email, :string
    field :client_phone, :string
    field :quantity, :integer
    field :special_requirements, :string
    field :status, :string, default: "draft"
    field :total_cost, :decimal
    field :markup_percentage, :decimal, default: Decimal.new("30.0")
    field :final_price, :decimal
    field :valid_until, :date

    # Campos para evaluación de choque
    field :evaluation_type, :string, default: "collision"
    field :evaluation_date, :date
    field :evaluator_name, :string
    field :damage_description, :string
    field :estimated_repair_hours, :integer
    field :parts_cost, :decimal
    field :labor_cost, :decimal
    field :paint_cost, :decimal
    field :other_costs, :decimal
    field :total_evaluation_cost, :decimal
    field :pdf_file_path, :string
    field :pdf_uploaded_at, :utc_datetime
    field :extracted_data, :map
    field :evaluation_photos, {:array, :string}, default: []
    field :insurance_company, :string
    field :claim_number, :string
    field :policy_number, :string
    field :deductible_amount, :decimal
    field :approval_status, :string, default: "pending"
    field :approval_date, :date
    field :approved_by, :string
    field :approval_notes, :string

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :user, EvaaCrmGaepell.User
    belongs_to :truck, EvaaCrmGaepell.Truck
    has_many :quotation_options, EvaaCrmGaepell.QuotationOption

    timestamps()
  end

  @doc false
  def changeset(quotation, attrs) do
    quotation
    |> cast(attrs, [:quotation_number, :client_name, :client_email, :client_phone, :quantity,
                   :special_requirements, :status, :total_cost, :markup_percentage, :final_price,
                   :valid_until, :business_id, :user_id, :evaluation_type, :evaluation_date,
                   :evaluator_name, :damage_description, :estimated_repair_hours, :parts_cost,
                   :labor_cost, :paint_cost, :other_costs, :total_evaluation_cost, :pdf_file_path,
                   :pdf_uploaded_at, :extracted_data, :evaluation_photos, :insurance_company,
                   :claim_number, :policy_number, :deductible_amount, :approval_status,
                   :approval_date, :approved_by, :approval_notes, :truck_id])
    |> validate_required([:quotation_number, :client_name, :quantity, :business_id, :user_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:markup_percentage, greater_than_or_equal_to: 0)
    |> validate_format(:client_email, ~r/@/, allow_nil: true)
    |> validate_inclusion(:evaluation_type, ["collision", "maintenance", "other"], allow_nil: true)
    |> validate_inclusion(:approval_status, ["pending", "approved", "rejected"], allow_nil: true)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:truck_id)
    |> unique_constraint(:quotation_number)
  end

  # Helper functions
  def status_options do
    [
      {"Borrador", "draft"},
      {"Enviada", "sent"},
      {"Aprobada", "approved"},
      {"Rechazada", "rejected"},
      {"Completada", "completed"}
    ]
  end

  def status_label("draft"), do: "Borrador"
  def status_label("sent"), do: "Enviada"
  def status_label("approved"), do: "Aprobada"
  def status_label("rejected"), do: "Rechazada"
  def status_label("completed"), do: "Completada"
  def status_label(_), do: "Desconocido"

  def status_color("draft"), do: "gray"
  def status_color("sent"), do: "blue"
  def status_color("approved"), do: "green"
  def status_color("rejected"), do: "red"
  def status_color("completed"), do: "purple"
  def status_color(_), do: "gray"

  def generate_quotation_number(business_id) do
    today = Date.utc_today()
    year = today.year
    month = today.month |> Integer.to_string() |> String.pad_leading(2, "0")
    
    # Count quotations for this month
    count = EvaaCrmGaepell.Repo.one(
      from q in __MODULE__,
      where: q.business_id == ^business_id and fragment("EXTRACT(YEAR FROM ?)", q.inserted_at) == ^year and fragment("EXTRACT(MONTH FROM ?)", q.inserted_at) == ^today.month,
      select: count(q.id)
    ) || 0
    
    sequence = (count + 1) |> Integer.to_string() |> String.pad_leading(3, "0")
    "COT-#{year}#{month}-#{sequence}"
  end

  def get_by_business(business_id) do
    EvaaCrmGaepell.Repo.all(
      from q in __MODULE__,
      where: q.business_id == ^business_id,
      order_by: [desc: q.inserted_at],
      preload: [:quotation_options]
    )
  end

  def get_by_status(status, business_id) do
    EvaaCrmGaepell.Repo.all(
      from q in __MODULE__,
      where: q.status == ^status and q.business_id == ^business_id,
      order_by: [desc: q.inserted_at],
      preload: [:quotation_options]
    )
  end

  # Funciones helper para evaluaciones
  def evaluation_type_options do
    [
      {"Evaluación de Choque", "collision"},
      {"Evaluación de Mantenimiento", "maintenance"},
      {"Otro", "other"}
    ]
  end

  def evaluation_type_label("collision"), do: "Evaluación de Choque"
  def evaluation_type_label("maintenance"), do: "Evaluación de Mantenimiento"
  def evaluation_type_label("other"), do: "Otro"
  def evaluation_type_label(_), do: "Desconocido"

  def approval_status_options do
    [
      {"Pendiente", "pending"},
      {"Aprobada", "approved"},
      {"Rechazada", "rejected"}
    ]
  end

  def approval_status_label("pending"), do: "Pendiente"
  def approval_status_label("approved"), do: "Aprobada"
  def approval_status_label("rejected"), do: "Rechazada"
  def approval_status_label(_), do: "Desconocido"

  def approval_status_color("pending"), do: "yellow"
  def approval_status_color("approved"), do: "green"
  def approval_status_color("rejected"), do: "red"
  def approval_status_color(_), do: "gray"

  def calculate_final_price(total_cost, markup_percentage) do
    markup_decimal = Decimal.div(markup_percentage, Decimal.new("100"))
    markup_amount = Decimal.mult(total_cost, markup_decimal)
    Decimal.add(total_cost, markup_amount)
  end
end 