defmodule EvaaCrmGaepell.Company do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(active inactive prospect)
  @sizes ~w(small medium large enterprise)

  schema "companies" do
    field :name, :string
    field :website, :string
    field :phone, :string
    field :email, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :industry, :string
    field :size, :string
    field :description, :string
    field :status, :string, default: "active"

    belongs_to :business, EvaaCrmGaepell.Business
    has_many :contacts, EvaaCrmGaepell.Contact
    has_many :leads, EvaaCrmGaepell.Lead
    has_many :activities, EvaaCrmGaepell.Activity

    timestamps()
  end

  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :website, :phone, :email, :address, :city, :state, 
                   :country, :postal_code, :industry, :size, :description, :status, :business_id])
    |> validate_required([:name, :business_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:size, @sizes)
    |> validate_format(:email, ~r/@/, message: "must be a valid email")
    |> validate_format(:website, ~r/^https?:\/\/.+/, message: "must be a valid URL")
    |> unique_constraint([:business_id, :name])
    |> foreign_key_constraint(:business_id)
  end
end 