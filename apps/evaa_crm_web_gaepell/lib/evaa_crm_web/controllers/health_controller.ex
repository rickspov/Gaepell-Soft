defmodule EvaaCrmWebGaepell.HealthController do
  use EvaaCrmWebGaepell, :controller

  def check(conn, _params) do
    # Simple health check endpoint for Railway
    # Returns 200 OK if the server is running
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", service: "evaa_crm"}))
  end
end

