defmodule EvaaCrmGaepell.Document do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "documents" do
    field :title, :string
    field :description, :string
    field :category, :string
    field :files, {:array, :map}, default: []
    field :tags, {:array, :string}, default: []
    field :total_files, :integer, default: 0
    field :total_size, :integer, default: 0

    belongs_to :business, EvaaCrmGaepell.Business
    belongs_to :created_by, EvaaCrmGaepell.User
    belongs_to :truck, EvaaCrmGaepell.Truck
    belongs_to :maintenance_ticket, EvaaCrmGaepell.MaintenanceTicket
    belongs_to :evaluation, EvaaCrmGaepell.Evaluation
    belongs_to :production_order, EvaaCrmGaepell.ProductionOrder

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:title, :description, :category, :files, :tags, :total_files, :total_size, :business_id, :created_by_id, :truck_id, :maintenance_ticket_id, :evaluation_id, :production_order_id])
    |> validate_required([:title, :category, :business_id])
    |> validate_inclusion(:category, [
      "truck-photos", "damage-photos", "purchase-orders", "quotes", 
      "invoices", "insurance", "permits", "maintenance", "others"
    ])
    |> validate_number(:total_files, greater_than_or_equal_to: 0)
    |> validate_number(:total_size, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:created_by_id)
    |> foreign_key_constraint(:truck_id)
    |> foreign_key_constraint(:maintenance_ticket_id)
    |> foreign_key_constraint(:evaluation_id)
    |> foreign_key_constraint(:production_order_id)
  end

  @doc """
  Crea un nuevo documento
  """
  def create_document(attrs, user_id) do
    %__MODULE__{}
    |> changeset(attrs)
    |> put_change(:created_by_id, user_id)
    |> EvaaCrmGaepell.Repo.insert()
  end

  @doc """
  Actualiza un documento existente
  """
  def update_document(%__MODULE__{} = document, attrs) do
    document
    |> changeset(attrs)
    |> EvaaCrmGaepell.Repo.update()
  end

  @doc """
  Elimina un documento
  """
  def delete_document(%__MODULE__{} = document) do
    EvaaCrmGaepell.Repo.delete(document)
  end

  @doc """
  Obtiene un documento por ID con preloads
  """
  def get_document!(id) do
    EvaaCrmGaepell.Repo.get!(__MODULE__, id)
    |> EvaaCrmGaepell.Repo.preload([
      :business, :created_by, :truck, :maintenance_ticket, :evaluation, :production_order
    ])
  end

  @doc """
  Lista documentos con filtros opcionales
  """
  def list_documents(business_id, opts \\ []) do
    __MODULE__
    |> where([d], d.business_id == ^business_id)
    |> filter_by_category(opts[:category])
    |> filter_by_truck(opts[:truck_id])
    |> filter_by_search(opts[:search])
    |> order_by([d], [desc: d.inserted_at])
    |> EvaaCrmGaepell.Repo.all()
    |> EvaaCrmGaepell.Repo.preload([
      :business, :created_by, :truck, :maintenance_ticket, :evaluation, :production_order
    ])
  end

  defp filter_by_category(query, nil), do: query
  defp filter_by_category(query, category) do
    where(query, [d], d.category == ^category)
  end

  defp filter_by_truck(query, nil), do: query
  defp filter_by_truck(query, truck_id) do
    where(query, [d], d.truck_id == ^truck_id)
  end

  defp filter_by_search(query, nil), do: query
  defp filter_by_search(query, search) when is_binary(search) and byte_size(search) > 0 do
    search_term = "%#{search}%"
    where(query, [d], 
      ilike(d.title, ^search_term) or 
      ilike(d.description, ^search_term) or
      fragment("? && ?", d.tags, ^[search])
    )
  end
  defp filter_by_search(query, _), do: query

  @doc """
  Obtiene estadísticas de documentos para un business
  """
  def get_document_stats(business_id) do
    query = from d in __MODULE__,
      where: d.business_id == ^business_id,
      select: %{
        total_documents: count(d.id),
        total_files: sum(d.total_files),
        total_size: sum(d.total_size),
        categories: fragment("jsonb_object_agg(?, count(*))", d.category)
      }

    case EvaaCrmGaepell.Repo.one(query) do
      %{total_documents: total, total_files: files, total_size: size, categories: categories} ->
        %{
          total_documents: total || 0,
          total_files: files || 0,
          total_size: size || 0,
          categories: categories || %{}
        }
      _ ->
        %{total_documents: 0, total_files: 0, total_size: 0, categories: %{}}
    end
  end

  @doc """
  Obtiene documentos asociados a un camión
  """
  def get_documents_by_truck(truck_id) do
    __MODULE__
    |> where([d], d.truck_id == ^truck_id)
    |> order_by([d], [desc: d.inserted_at])
    |> EvaaCrmGaepell.Repo.all()
    |> EvaaCrmGaepell.Repo.preload([:created_by])
  end

  @doc """
  Obtiene documentos asociados a un ticket de mantenimiento
  """
  def get_documents_by_maintenance_ticket(ticket_id) do
    __MODULE__
    |> where([d], d.maintenance_ticket_id == ^ticket_id)
    |> order_by([d], [desc: d.inserted_at])
    |> EvaaCrmGaepell.Repo.all()
    |> EvaaCrmGaepell.Repo.preload([:created_by])
  end

  @doc """
  Obtiene documentos asociados a una evaluación
  """
  def get_documents_by_evaluation(evaluation_id) do
    __MODULE__
    |> where([d], d.evaluation_id == ^evaluation_id)
    |> order_by([d], [desc: d.inserted_at])
    |> EvaaCrmGaepell.Repo.all()
    |> EvaaCrmGaepell.Repo.preload([:created_by])
  end
end
