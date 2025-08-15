defmodule EvaaCrmGaepell.ActivityLog do
  @moduledoc """
  Sistema de logs de actividad para tracking de cambios en el sistema.
  Maneja logs para tickets, camiones, usuarios, etc.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EvaaCrmGaepell.{Repo, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :integer
  schema "activity_logs" do
    field :entity_type, :string  # "maintenance_ticket", "truck", "user", etc.
    field :entity_id, :integer   # ID del registro relacionado
    field :action, :string       # "created", "updated", "status_changed", "commented", etc.
    field :description, :string  # Descripción legible de la acción
    field :old_values, :map      # Valores anteriores (opcional)
    field :new_values, :map      # Valores nuevos (opcional)
    field :metadata, :map        # Datos adicionales (comentarios, archivos, etc.)
    
    belongs_to :user, User       # Usuario que realizó la acción
    belongs_to :business, EvaaCrmGaepell.Business

    timestamps()
  end

  @doc false
  def changeset(activity_log, attrs) do
    activity_log
    |> cast(attrs, [:entity_type, :entity_id, :action, :description, :old_values, :new_values, :metadata, :user_id, :business_id])
    |> validate_required([:entity_type, :entity_id, :action, :description, :user_id, :business_id])
    |> validate_inclusion(:action, ["created", "updated", "deleted", "status_changed", "commented", "assigned", "unassigned", "file_uploaded", "note_added"])
  end

  @doc """
  Crea un nuevo log de actividad
  """
  def create_log(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Obtiene logs de actividad para una entidad específica
  """
  def get_logs_for_entity(entity_type, entity_id, limit \\ 50) do
    from(log in __MODULE__,
      where: log.entity_type == ^entity_type and log.entity_id == ^entity_id,
      order_by: [desc: log.inserted_at],
      limit: ^limit,
      preload: [:user, :business]
    )
    |> Repo.all()
  end

  @doc """
  Obtiene logs de actividad para un usuario específico
  """
  def get_logs_for_user(user_id, limit \\ 50) do
    from(log in __MODULE__,
      where: log.user_id == ^user_id,
      order_by: [desc: log.inserted_at],
      limit: ^limit,
      preload: [:user, :business]
    )
    |> Repo.all()
  end

  @doc """
  Obtiene logs de actividad para un negocio específico
  """
  def get_logs_for_business(business_id, limit \\ 100) do
    from(log in __MODULE__,
      where: log.business_id == ^business_id,
      order_by: [desc: log.inserted_at],
      limit: ^limit,
      preload: [:user, :business]
    )
    |> Repo.all()
  end

  @doc """
  Formatea la descripción de un log para mostrar en la UI
  """
  def format_description(log) do
    case log.action do
      "created" -> "creó"
      "updated" -> "actualizó"
      "deleted" -> "eliminó"
      "status_changed" -> "cambió el estado de"
      "commented" -> "comentó en"
      "assigned" -> "asignó"
      "unassigned" -> "desasignó"
      "file_uploaded" -> "subió un archivo a"
      "note_added" -> "agregó una nota a"
      _ -> "realizó acción en"
    end
  end

  @doc """
  Obtiene el nombre legible de la entidad
  """
  def get_entity_name(entity_type) do
    case entity_type do
      "maintenance_ticket" -> "ticket de mantenimiento"
      "truck" -> "camión"
      "user" -> "usuario"
      "activity" -> "actividad"
      "production_order" -> "orden de producción"
      _ -> entity_type
    end
  end

  @doc """
  Crea un log automático para cambios de estado
  """
  def log_status_change(entity_type, entity_id, old_status, new_status, user_id, business_id) do
    description = "Estado cambiado de '#{old_status}' a '#{new_status}'"
    
    create_log(%{
      entity_type: entity_type,
      entity_id: entity_id,
      action: "status_changed",
      description: description,
      old_values: %{status: old_status},
      new_values: %{status: new_status},
      user_id: user_id,
      business_id: business_id
    })
  end

  @doc """
  Crea un log automático para creación de entidades
  """
  def log_creation(entity_type, entity_id, entity_name, user_id, business_id) do
    description = "creó #{get_entity_name(entity_type)} '#{entity_name}'"
    
    create_log(%{
      entity_type: entity_type,
      entity_id: entity_id,
      action: "created",
      description: description,
      user_id: user_id,
      business_id: business_id
    })
  end

  @doc """
  Crea un log automático para comentarios
  """
  def log_comment(entity_type, entity_id, comment, user_id, business_id) do
    create_log(%{
      entity_type: entity_type,
      entity_id: entity_id,
      action: "commented",
      description: "agregó un comentario",
      metadata: %{comment: comment},
      user_id: user_id,
      business_id: business_id
    })
  end
end 