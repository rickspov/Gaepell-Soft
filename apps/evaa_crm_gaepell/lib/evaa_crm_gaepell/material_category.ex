defmodule EvaaCrmGaepell.MaterialCategory do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "material_categories" do
    field :name, :string
    field :description, :string
    field :color, :string, default: "#3b82f6"

    belongs_to :business, EvaaCrmGaepell.Business
    has_many :materials, EvaaCrmGaepell.Material, foreign_key: :category_id

    timestamps()
  end

  @doc false
  def changeset(material_category, attrs) do
    material_category
    |> cast(attrs, [:name, :description, :color, :business_id])
    |> validate_required([:name, :business_id])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:business_id)
  end

  # Helper functions
  def get_by_business(business_id) do
    EvaaCrmGaepell.Repo.all(
      from mc in __MODULE__,
      where: mc.business_id == ^business_id,
      preload: [:materials]
    )
  end

  def get_with_materials(category_id, business_id) do
    EvaaCrmGaepell.Repo.one(
      from mc in __MODULE__,
      where: mc.id == ^category_id and mc.business_id == ^business_id,
      preload: [:materials]
    )
    |> case do
      nil -> nil
      category -> 
        active_materials = Enum.filter(category.materials, fn m -> m.is_active end)
        Map.put(category, :materials, active_materials)
    end
  end
end 