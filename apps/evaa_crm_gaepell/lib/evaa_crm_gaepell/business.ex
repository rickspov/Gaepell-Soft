defmodule EvaaCrmGaepell.Business do
  use Ecto.Schema
  import Ecto.Changeset

  schema "businesses" do
    field :name, :string
    has_many :users, EvaaCrmGaepell.User
    has_many :companies, EvaaCrmGaepell.Company
    has_many :contacts, EvaaCrmGaepell.Contact
    has_many :leads, EvaaCrmGaepell.Lead
    has_many :activities, EvaaCrmGaepell.Activity
    timestamps()
  end

  def changeset(business, attrs) do
    business
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end 