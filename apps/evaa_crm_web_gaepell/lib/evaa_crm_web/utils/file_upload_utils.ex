defmodule EvaaCrmWebGaepell.Utils.FileUploadUtils do
  @moduledoc """
  Utilidades universales para manejo de archivos en toda la aplicación.
  """

  @doc """
  Procesa archivos subidos y los guarda en el directorio correspondiente.
  
  ## Parámetros:
  - socket: El socket de LiveView
  - upload_name: Nombre del upload (ej: :ticket_attachments)
  - entity_type: Tipo de entidad (ej: "truck", "maintenance_ticket")
  - entity_id: ID de la entidad
  - file_descriptions: Map con descripciones de archivos
  
  ## Retorna:
  - Lista de archivos procesados con metadatos
  """
  def process_uploaded_files(socket, upload_name, entity_type, entity_id, file_descriptions \\ %{}) do
    Phoenix.LiveView.consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
      # Crear directorio para archivos si no existe
      upload_dir = Path.join(["priv", "static", "uploads", entity_type, to_string(entity_id)])
      File.mkdir_p!(upload_dir)
      
      # Generar nombre único para el archivo usando timestamp y nombre original
      timestamp = System.system_time(:millisecond)
      unique_filename = "#{timestamp}_#{entry.client_name}"
      dest_path = Path.join(upload_dir, unique_filename)
      
      # Copiar archivo
      File.cp!(path, dest_path)
      
      # Obtener descripción del archivo
      description = Map.get(file_descriptions, entry.ref, "")
      
      file_info = %{
        original_name: entry.client_name,
        filename: unique_filename,
        path: "/uploads/#{entity_type}/#{entity_id}/#{unique_filename}",
        size: entry.client_size,
        content_type: entry.client_type,
        description: description
      }
      
      {:ok, file_info}
    end)
  end

  @doc """
  Actualiza los archivos de una entidad en la base de datos.
  
  ## Parámetros:
  - entity: La entidad a actualizar
  - uploaded_files: Lista de archivos procesados
  - field_name: Nombre del campo en la base de datos (ej: :damage_photos, :photos)
  
  ## Retorna:
  - {:ok, updated_entity} o {:error, changeset}
  """
  def update_entity_files(entity, uploaded_files, field_name) do
    # Obtener archivos existentes
    existing_files = Map.get(entity, field_name, [])
    
    # Crear lista de nuevos archivos con descripciones
    new_files = Enum.map(uploaded_files, fn file ->
      if file.description && file.description != "" do
        # Si hay descripción, crear un objeto JSON
        Jason.encode!(%{
          path: file.path,
          description: file.description,
          original_name: file.original_name,
          size: file.size,
          content_type: file.content_type
        })
      else
        # Si no hay descripción, mantener solo la ruta (compatibilidad)
        file.path
      end
    end)
    
    # Combinar archivos existentes con nuevos
    all_files = existing_files ++ new_files
    
    # Actualizar la entidad
    entity
    |> Ecto.Changeset.change(%{field_name => all_files})
    |> EvaaCrmGaepell.Repo.update()
  end

  @doc """
  Elimina un archivo de una entidad.
  
  ## Parámetros:
  - entity: La entidad
  - file_index: Índice del archivo a eliminar
  - field_name: Nombre del campo en la base de datos
  
  ## Retorna:
  - {:ok, updated_entity} o {:error, changeset}
  """
  def delete_entity_file(entity, file_index, field_name) do
    files = Map.get(entity, field_name, [])
    
    if file_index >= 0 and file_index < length(files) do
      file_to_delete = Enum.at(files, file_index)
      file_info = parse_file_info(file_to_delete)
      
      # Eliminar archivo físico
      file_path = Path.join([File.cwd!(), "priv", "static", file_info.path])
      if File.exists?(file_path) do
        File.rm!(file_path)
      end
      
      # Remover de la lista
      updated_files = List.delete_at(files, file_index)
      
      # Actualizar la entidad
      entity
      |> Ecto.Changeset.change(%{field_name => updated_files})
      |> EvaaCrmGaepell.Repo.update()
    else
      {:error, :file_not_found}
    end
  end

  @doc """
  Parsea información de archivo desde JSON o string.
  
  ## Parámetros:
  - file_info: String con JSON o ruta del archivo
  
  ## Retorna:
  - Map con información del archivo
  """
  def parse_file_info(file_info) when is_binary(file_info) do
    case Jason.decode(file_info) do
      {:ok, parsed} -> 
        # Es un archivo con descripción
        %{
          path: parsed["path"] || file_info,
          description: parsed["description"],
          original_name: parsed["original_name"] || Path.basename(parsed["path"] || file_info),
          size: parsed["size"],
          content_type: parsed["content_type"]
        }
      {:error, _} -> 
        # Es un archivo sin descripción (solo ruta)
        %{
          path: file_info,
          description: nil,
          original_name: Path.basename(file_info),
          size: nil,
          content_type: nil
        }
    end
  end
  
  def parse_file_info(file_info) do
    # Fallback para cualquier otro tipo de dato
    %{
      path: to_string(file_info),
      description: nil,
      original_name: "archivo",
      size: nil,
      content_type: nil
    }
  end

  @doc """
  Obtiene el label del tipo de archivo.
  
  ## Parámetros:
  - path: Ruta del archivo
  
  ## Retorna:
  - String con el tipo de archivo
  """
  def get_file_type_label(path) do
    cond do
      String.ends_with?(String.downcase(path), [".jpg", ".jpeg", ".png", ".gif"]) ->
        "Imagen"
      String.ends_with?(String.downcase(path), ".pdf") ->
        "Documento PDF"
      String.ends_with?(String.downcase(path), [".doc", ".docx"]) ->
        "Documento Word"
      String.ends_with?(String.downcase(path), [".xls", ".xlsx"]) ->
        "Hoja de cálculo"
      true ->
        "Archivo"
    end
  end

  @doc """
  Convierte errores de upload a strings legibles.
  
  ## Parámetros:
  - error: Error de upload
  
  ## Retorna:
  - String con el mensaje de error
  """
  def error_to_string(:too_large), do: "El archivo es demasiado grande"
  def error_to_string(:too_many_files), do: "Demasiados archivos"
  def error_to_string(:not_accepted), do: "Tipo de archivo no aceptado"
  def error_to_string(_), do: "Error al subir el archivo"

  @doc """
  Configura los uploads para una entidad específica.
  
  ## Parámetros:
  - entity_type: Tipo de entidad
  - entity_id: ID de la entidad
  - upload_name: Nombre del upload
  - opts: Opciones adicionales
  
  ## Retorna:
  - Configuración de upload
  """
  def configure_uploads(_entity_type, _entity_id, upload_name, opts \\ []) do
    max_entries = Keyword.get(opts, :max_entries, 10)
    max_file_size = Keyword.get(opts, :max_file_size, 10_000_000)
    accept = Keyword.get(opts, :accept, ".jpg,.jpeg,.png,.gif,.pdf,.doc,.docx,.txt,.xlsx,.xls")
    
    %{
      upload_name => %Phoenix.LiveView.UploadConfig{
        accept: accept,
        max_entries: max_entries,
        max_file_size: max_file_size
      }
    }
  end

  @doc """
  Obtiene archivos de una entidad según el tipo.
  
  ## Parámetros:
  - entity: La entidad
  - entity_type: Tipo de entidad
  - field_mapping: Map con mapeo de tipos a campos
  
  ## Retorna:
  - Lista de archivos
  """
  def get_entity_files(entity, entity_type, field_mapping) do
    field_name = Map.get(field_mapping, entity_type)
    if field_name do
      Map.get(entity, field_name, [])
    else
      []
    end
  end

  @doc """
  Mapeo estándar de tipos de entidad a campos de archivos.
  """
  def standard_field_mapping do
    %{
      "maintenance_ticket" => :damage_photos,
      "evaluation" => :photos,
      "truck" => :profile_photo,
      "quotation" => :attachments,
      "production_order" => :documents
    }
  end
end
