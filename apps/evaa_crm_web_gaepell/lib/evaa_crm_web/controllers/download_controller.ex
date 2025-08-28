defmodule EvaaCrmWebGaepell.DownloadController do
  use EvaaCrmWebGaepell, :controller

  def document_zip(conn, %{"document_id" => document_id, "filename" => filename}) do
    # Construir la ruta del archivo ZIP
    zip_path = Path.join([System.tmp_dir!(), "document_zip_#{document_id}", filename])
    
    if File.exists?(zip_path) do
      # Enviar el archivo ZIP como descarga
      conn
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> put_resp_content_type("application/zip")
      |> send_file(200, zip_path)
    else
      conn
      |> put_status(404)
      |> text("Archivo no encontrado")
    end
  end
end


