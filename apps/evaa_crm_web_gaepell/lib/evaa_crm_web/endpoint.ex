defmodule EvaaCrmWebGaepell.Endpoint do
  use Phoenix.Endpoint, otp_app: :evaa_crm_web_gaepell

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_evaa_crm_web_key",
    signing_salt: "ckq7IA9h",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve uploaded files at /uploads from priv/static/uploads directory
  plug Plug.Static,
    at: "/uploads",
    from: Path.expand("./priv/static/uploads"),
    gzip: false

  # Serve PDF files at /pdfs from sample_data directory
  plug Plug.Static,
    at: "/pdfs",
    from: Path.expand("./sample_data"),
    gzip: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :evaa_crm_web_gaepell,
    gzip: false,
    only: EvaaCrmWebGaepell.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    # plug Phoenix.Ecto.CheckRepoStatus, otp_app: :evaa_crm_web_gaepell
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug EvaaCrmWebGaepell.Router
end
