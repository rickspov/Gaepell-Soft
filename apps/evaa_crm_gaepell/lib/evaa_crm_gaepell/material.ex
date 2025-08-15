defmodule EvaaCrmGaepell.Material do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "materials" do
    field :name, :string
    field :description, :string
    field :unit, :string # metros, kg, unidades, etc.
    field :cost_per_unit, :decimal
    field :current_stock, :decimal, default: Decimal.new("0")
    field :min_stock, :decimal, default: Decimal.new("0")
    field :supplier, :string
    field :supplier_contact, :string
    field :lead_time_days, :integer, default: 0
    field :is_active, :boolean, default: true

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :category, EvaaCrmGaepell.MaterialCategory, foreign_key: :category_id

    timestamps()
  end

  @doc false
  def changeset(material, attrs) do
    material
    |> cast(attrs, [:name, :description, :unit, :cost_per_unit, :current_stock, :min_stock, 
                   :supplier, :supplier_contact, :lead_time_days, :is_active, :business_id, :category_id])
    |> validate_required([:name, :unit, :cost_per_unit, :business_id, :category_id])
    |> validate_number(:cost_per_unit, greater_than: 0)
    |> validate_number(:current_stock, greater_than_or_equal_to: 0)
    |> validate_number(:min_stock, greater_than_or_equal_to: 0)
    |> validate_number(:lead_time_days, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:category_id)
  end

  # Helper functions
  def unit_options do
    [
      {"Metros", "metros"},
      {"Kilogramos", "kg"},
      {"Unidades", "unidades"},
      {"Litros", "litros"},
      {"Metros cuadrados", "m2"},
      {"Metros cúbicos", "m3"}
    ]
  end

  def get_by_category(category_id, business_id) do
    EvaaCrmGaepell.Repo.all(
      from m in __MODULE__,
      where: m.category_id == ^category_id and m.business_id == ^business_id and m.is_active == true
    )
  end

  def get_low_stock(business_id) do
    EvaaCrmGaepell.Repo.all(
      from m in __MODULE__,
      where: m.business_id == ^business_id and m.current_stock <= m.min_stock and m.is_active == true
    )
  end

  def calculate_total_value(material) do
    Decimal.mult(material.cost_per_unit, material.current_stock)
  end
end 