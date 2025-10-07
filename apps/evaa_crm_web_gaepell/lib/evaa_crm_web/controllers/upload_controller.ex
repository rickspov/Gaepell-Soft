defmodule EvaaCrmWebGaepell.UploadController do
  use EvaaCrmWebGaepell, :controller

  def evaluation_photo(conn, %{"path" => path}) do
    # Usar la ruta absoluta correcta para el proyecto
    file_path = Path.join([File.cwd!(), "priv", "static", "uploads", "evaluations", path])
    
    if File.exists?(file_path) do
      conn
      |> put_resp_content_type(get_content_type(file_path))
      |> send_file(200, file_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end

  def ticket_attachment(conn, %{"path" => path}) do
    # El path viene como lista, necesitamos unirlo correctamente
    path_string = if is_list(path), do: Enum.join(path, "/"), else: path
    
    # Usar la ruta absoluta correcta para el proyecto
    file_path = Path.join([File.cwd!(), "priv", "static", "uploads", "tickets", path_string])
    
    # Debug logging
    IO.inspect("Requested path: #{inspect(path)}", label: "[DEBUG]")
    IO.inspect("Path string: #{path_string}", label: "[DEBUG]")
    IO.inspect("Full file path: #{file_path}", label: "[DEBUG]")
    IO.inspect("File exists: #{File.exists?(file_path)}", label: "[DEBUG]")
    
    if File.exists?(file_path) do
      conn
      |> put_resp_content_type(get_content_type(file_path))
      |> send_file(200, file_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end

  def maintenance_photo(conn, %{"path" => path}) do
    # El path viene como lista, necesitamos unirlo correctamente
    path_string = if is_list(path), do: Enum.join(path, "/"), else: path
    
    # Usar la ruta absoluta correcta para el proyecto
    file_path = Path.join([File.cwd!(), "priv", "static", "uploads", "maintenance", path_string])
    
    # Debug logging
    IO.inspect("Requested path: #{inspect(path)}", label: "[DEBUG]")
    IO.inspect("Path string: #{path_string}", label: "[DEBUG]")
    IO.inspect("Full file path: #{file_path}", label: "[DEBUG]")
    IO.inspect("File exists: #{File.exists?(file_path)}", label: "[DEBUG]")
    
    if File.exists?(file_path) do
      conn
      |> put_resp_content_type(get_content_type(file_path))
      |> send_file(200, file_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end

  def document_file(conn, %{"path" => path}) do
    # El path viene como lista, necesitamos unirlo correctamente
    path_string = if is_list(path), do: Enum.join(path, "/"), else: path
    
    # Usar la ruta absoluta correcta para el proyecto
    file_path = Path.join([File.cwd!(), "priv", "static", "uploads", "documents", path_string])
    
    # Debug logging
    IO.inspect("Requested path: #{inspect(path)}", label: "[DEBUG]")
    IO.inspect("Path string: #{path_string}", label: "[DEBUG]")
    IO.inspect("Full file path: #{file_path}", label: "[DEBUG]")
    IO.inspect("File exists: #{File.exists?(file_path)}", label: "[DEBUG]")
    
    if File.exists?(file_path) do
      conn
      |> put_resp_content_type(get_content_type(file_path))
      |> send_file(200, file_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end

  def wizard_file(conn, %{"path" => path}) do
    # El path viene como lista, necesitamos unirlo correctamente
    path_string = if is_list(path), do: Enum.join(path, "/"), else: path
    
    # Usar la ruta absoluta correcta para el proyecto
    file_path = Path.join([File.cwd!(), "priv", "static", "uploads", "wizard", path_string])
    
    # Debug logging
    IO.inspect("Requested wizard path: #{inspect(path)}", label: "[DEBUG]")
    IO.inspect("Path string: #{path_string}", label: "[DEBUG]")
    IO.inspect("Full file path: #{file_path}", label: "[DEBUG]")
    IO.inspect("File exists: #{File.exists?(file_path)}", label: "[DEBUG]")
    
    if File.exists?(file_path) do
      conn
      |> put_resp_content_type(get_content_type(file_path))
      |> send_file(200, file_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end

  defp get_content_type(file_path) do
    case Path.extname(file_path) do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".pdf" -> "application/pdf"
      ".doc" -> "application/msword"
      ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ".txt" -> "text/plain"
      ".xls" -> "application/vnd.ms-excel"
      ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      _ -> "application/octet-stream"
    end
  end
end
