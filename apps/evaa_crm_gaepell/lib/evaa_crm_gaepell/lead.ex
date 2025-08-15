defmodule EvaaCrmGaepell.Lead do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @statuses ~w(new contacted qualified converted lost)

  schema "leads" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :company_name, :string
    field :source, :string  # website, referral, cold_call, etc.
    field :status, :string, default: "new"  # new, contacted, qualified, proposal, converted, lost
    field :notes, :string
    field :priority, :string, default: "medium"  # low, medium, high, urgent
    field :assigned_to, :integer
    field :next_follow_up, :utc_datetime
    field :conversion_date, :utc_datetime
    field :business_id, :integer
    
    belongs_to :company, EvaaCrmGaepell.Company
    belongs_to :user, EvaaCrmGaepell.User
    
    timestamps()
  end

  def changeset(lead, attrs) do
    lead
    |> cast(attrs, [:name, :email, :phone, :company_name, :source, :status, :notes, :priority, :assigned_to, :next_follow_up, :conversion_date, :business_id, :company_id, :user_id])
    |> validate_required([:name, :email, :business_id])
    |> validate_email(:email)
    |> validate_priority()
    |> validate_inclusion(:status, @statuses)
  end

  defp validate_email(changeset, field) do
    validate_change(changeset, field, fn :email, email ->
      cond do
        email == nil -> [email: "cannot be nil"]
        !String.contains?(email, "@") -> [email: "must contain @"]
        true -> []
      end
    end)
  end

  defp validate_priority(changeset) do
    validate_inclusion(changeset, :priority, ["low", "medium", "high", "urgent"])
  end

  # Queries
  def by_business(business_id) do
    from(l in __MODULE__, where: l.business_id == ^business_id)
  end

  def by_status(status) do
    from(l in __MODULE__, where: l.status == ^status)
  end

  def with_company do
    from(l in __MODULE__, preload: [:company, :user])
  end

  # Status transitions
  def can_transition_to?(current_status, new_status) do
    transitions = %{
      "new" => ["contacted", "lost"],
      "contacted" => ["qualified", "lost"],
      "qualified" => ["converted", "lost"],
      "converted" => [],
      "lost" => ["new"]
    }
    
    Map.get(transitions, current_status, []) |> Enum.member?(new_status)
  end

  def status_colors do
    %{
      "new" => "bg-gray-100 text-gray-800",
      "contacted" => "bg-blue-100 text-blue-800", 
      "qualified" => "bg-yellow-100 text-yellow-800",
      "converted" => "bg-green-100 text-green-800",
      "lost" => "bg-red-100 text-red-800"
    }
  end

  def priority_colors do
    %{
      "low" => "bg-gray-100 text-gray-600",
      "medium" => "bg-blue-100 text-blue-600", 
      "high" => "bg-orange-100 text-orange-600",
      "urgent" => "bg-red-100 text-red-600"
    }
  end

  def full_name(%{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end
end 