defmodule EvaaCrmGaepell.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(active inactive prospect)
  @sources ~w(website referral cold_call social_media event other)

  schema "contacts" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :mobile, :string
    field :job_title, :string
    field :department, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :birth_date, :date
    field :notes, :string
    field :status, :string, default: "active"
    field :source, :string
    field :tags, {:array, :string}, default: []
    field :company_name, :string

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :company, EvaaCrmGaepell.Company
    belongs_to :specialist, EvaaCrmGaepell.Specialist
    has_many :activities, EvaaCrmGaepell.Activity

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :mobile, :job_title, 
                   :department, :address, :city, :state, :country, :postal_code, 
                   :birth_date, :notes, :status, :source, :tags, :business_id, :company_id, :specialist_id, :company_name])
    |> validate_required([:first_name, :last_name, :business_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:source, @sources)
    |> validate_format(:email, ~r/@/, message: "must be a valid email")
    |> validate_length(:first_name, min: 1, max: 100)
    |> validate_length(:last_name, min: 1, max: 100)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:company_id)
    |> foreign_key_constraint(:specialist_id)
  end

  def full_name(%{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end
end 