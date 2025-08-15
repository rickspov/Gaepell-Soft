defmodule EvaaCrmGaepell.User do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(admin manager specialist employee)

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :role, :string
    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :company, EvaaCrmGaepell.Company
    belongs_to :specialist, EvaaCrmGaepell.Specialist
    has_many :leads, EvaaCrmGaepell.Lead, foreign_key: :assigned_to
    has_many :activities, EvaaCrmGaepell.Activity
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :password_hash, :role, :business_id, :company_id, :specialist_id])
    |> validate_required([:email, :role, :business_id])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email)
    |> validate_password()
    |> put_password_hash()
  end

  defp validate_password(changeset) do
    password = get_change(changeset, :password)
    password_confirmation = get_change(changeset, :password_confirmation)
    cond do
      is_nil(password) -> changeset
      password != password_confirmation ->
        add_error(changeset, :password_confirmation, "no coincide con la contraseña")
      String.length(password) < 6 ->
        add_error(changeset, :password, "debe tener al menos 6 caracteres")
      true -> changeset
    end
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end 