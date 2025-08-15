defmodule EvaaCrmGaepell.Specialist do
  use Ecto.Schema
  import Ecto.Changeset

  @specializations [
    "Mecánico",
    "Eléctrico",
    "Técnico",
    "Chofer",
    "Supervisor",
    "Otra"
  ]

  schema "specialists" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :specialization, :string # mecánico, técnico, chofer, etc.
    field :is_active, :boolean, default: true
    field :status, :string, default: "active"
    field :availability, :string

    belongs_to :business, EvaaCrmGaepell.Business
    has_many :activities, EvaaCrmGaepell.Activity

    timestamps()
  end

  @doc false
  def changeset(specialist, attrs) do
    specialist
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :specialization, :is_active, :status, :availability, :business_id])
    |> validate_required([:first_name, :last_name, :email, :specialization, :business_id])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:specialization, @specializations)
    |> validate_inclusion(:status, ["active", "inactive", "vacation"])
    |> unique_constraint([:email, :business_id])
    |> foreign_key_constraint(:business_id)
  end

  def full_name(specialist) do
    "#{specialist.first_name} #{specialist.last_name}"
  end
end 