defmodule EvaaCrmWebGaepell.HealthController do
  use EvaaCrmWebGaepell, :controller

  def check(conn, _params) do
    # Simple health check endpoint for Railway
    # Returns 200 OK if the server is running
    # This endpoint doesn't require database connection
    try do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{status: "ok", service: "evaa_crm"}))
    rescue
      _ ->
        # Fallback to plain text if JSON encoding fails
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "ok")
    end
  end
end

