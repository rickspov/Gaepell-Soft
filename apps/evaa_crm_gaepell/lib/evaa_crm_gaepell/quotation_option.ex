defmodule EvaaCrmGaepell.QuotationOption do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotation_options" do
    field :option_name, :string
    field :material_configuration, :map # JSONB for material configuration
    field :quality_level, :string # premium, standard, economy
    field :production_cost, :decimal
    field :markup_percentage, :decimal
    field :final_price, :decimal
    field :delivery_time_days, :integer
    field :is_recommended, :boolean, default: false

    belongs_to :quotation, EvaaCrmGaepell.Quotation

    timestamps()
  end

  @doc false
  def changeset(quotation_option, attrs) do
    quotation_option
    |> cast(attrs, [:option_name, :material_configuration, :quality_level, :production_cost,
                   :markup_percentage, :final_price, :delivery_time_days, :is_recommended, :quotation_id])
    |> validate_required([:option_name, :quality_level, :production_cost, :markup_percentage, :final_price, :quotation_id])
    |> validate_number(:production_cost, greater_than: 0)
    |> validate_number(:markup_percentage, greater_than_or_equal_to: 0)
    |> validate_number(:final_price, greater_than: 0)
    |> validate_number(:delivery_time_days, greater_than_or_equal_to: 0)
    |> validate_inclusion(:quality_level, ["premium", "standard", "economy"])
    |> foreign_key_constraint(:quotation_id)
  end

  # Helper functions
  def quality_level_options do
    [
      {"Premium", "premium"},
      {"Estándar", "standard"},
      {"Económica", "economy"}
    ]
  end

  def quality_level_label("premium"), do: "Premium"
  def quality_level_label("standard"), do: "Estándar"
  def quality_level_label("economy"), do: "Económica"
  def quality_level_label(_), do: "Desconocido"

  def quality_level_color("premium"), do: "purple"
  def quality_level_color("standard"), do: "blue"
  def quality_level_color("economy"), do: "green"
  def quality_level_color(_), do: "gray"

  def calculate_final_price(production_cost, markup_percentage) do
    markup_decimal = Decimal.div(Decimal.new(markup_percentage), Decimal.new("100"))
    markup_amount = Decimal.mult(production_cost, markup_decimal)
    Decimal.add(production_cost, markup_amount)
  end
end 