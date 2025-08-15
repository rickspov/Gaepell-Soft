defmodule EvaaCrmGaepell.TruckModel do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "truck_models" do
    field :brand, :string
    field :model, :string
    field :year, :integer
    field :capacity, :string
    field :fuel_type, :string
    field :dimensions, :string
    field :weight, :string
    field :engine, :string
    field :transmission, :string
    field :usage_count, :integer, default: 1
    field :last_used_at, :utc_datetime

    belongs_to :business, EvaaCrmGaepell.Business

    timestamps()
  end

  def changeset(truck_model, attrs) do
    truck_model
    |> cast(attrs, [:brand, :model, :year, :capacity, :fuel_type, :dimensions, :weight, :engine, :transmission, :usage_count, :last_used_at, :business_id])
    |> validate_required([:brand, :model, :business_id])
    |> validate_inclusion(:fuel_type, ["diesel", "gasoline", "electric", "hybrid"])
    |> validate_number(:usage_count, greater_than: 0)
    |> validate_number(:year, greater_than: 1900, less_than: 2030)
    |> foreign_key_constraint(:business_id)
  end

  @doc """
  Busca marcas que coincidan con el query
  """
  def search_brands(query, business_id) do
    EvaaCrmGaepell.Repo.all(
      from tm in __MODULE__,
      where: tm.business_id == ^business_id and ilike(tm.brand, ^"%#{query}%"),
      select: tm.brand,
      distinct: true,
      order_by: [desc: tm.usage_count, asc: tm.brand],
      limit: 10
    )
  end

  @doc """
  Busca modelos de una marca específica
  """
  def search_models(brand, query, business_id) do
    EvaaCrmGaepell.Repo.all(
      from tm in __MODULE__,
      where: tm.business_id == ^business_id and tm.brand == ^brand and ilike(tm.model, ^"%#{query}%"),
      order_by: [desc: tm.usage_count, asc: tm.model],
      limit: 10
    )
  end

  @doc """
  Obtiene un modelo específico por marca, modelo y año
  """
  def get_model(brand, model, year, business_id) do
    EvaaCrmGaepell.Repo.get_by(__MODULE__, 
      brand: brand, 
      model: model, 
      year: year, 
      business_id: business_id
    )
  end

  @doc """
  Actualiza o crea un modelo basado en un camión
  """
  def update_or_create_from_truck(truck) do
    truck_model_attrs = %{
      brand: truck.brand,
      model: truck.model,
      year: truck.year,
      capacity: truck.capacity,
      fuel_type: truck.fuel_type,
      business_id: truck.business_id,
      last_used_at: DateTime.utc_now()
    }

    case get_model(truck.brand, truck.model, truck.year, truck.business_id) do
      nil ->
        # Crear nuevo modelo
        %__MODULE__{}
        |> changeset(truck_model_attrs)
        |> EvaaCrmGaepell.Repo.insert()
      
      existing_model ->
        # Incrementar uso
        existing_model
        |> changeset(%{
          usage_count: existing_model.usage_count + 1,
          last_used_at: DateTime.utc_now()
        })
        |> EvaaCrmGaepell.Repo.update()
    end
  end

  @doc """
  Obtiene todos los modelos de una empresa ordenados por uso
  """
  def get_models_for_business(business_id, limit \\ 50) do
    EvaaCrmGaepell.Repo.all(
      from tm in __MODULE__,
      where: tm.business_id == ^business_id,
      order_by: [desc: tm.usage_count, desc: tm.last_used_at],
      limit: ^limit
    )
  end

  @doc """
  Obtiene las marcas disponibles para una empresa
  """
  def get_available_brands(business_id) do
    EvaaCrmGaepell.Repo.all(
      from tm in __MODULE__,
      where: tm.business_id == ^business_id,
      select: tm.brand,
      distinct: true,
      order_by: [asc: tm.brand]
    )
  end
end 