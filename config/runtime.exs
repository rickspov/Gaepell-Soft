import Config

# Runtime configuration reads environment variables.
# This file is executed for all environments, including
# during releases. It is executed after compilation and
# before the system starts, so it is typically used to load
# production configuration and secrets from environment
# variables or elsewhere. Do not define any constructors
# in this file, as it won't be loaded.

# The block below contains prod specific runtime configuration.
if System.get_env("PHX_SERVER") do
  port = String.to_integer(System.get_env("PORT") || "4000")
  host = System.get_env("PHX_HOST") || "localhost"
  secret_key_base = System.get_env("SECRET_KEY_BASE")

  if is_nil(secret_key_base) do
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """
  end

  # Configurar check_origin para permitir conexiones desde el dominio de Railway
  # Usamos una función que verifica dinámicamente si el origen es válido
  check_origin_fn = fn origin ->
    case URI.parse(origin) do
      %URI{host: origin_host, scheme: scheme} when scheme in ["https", "http"] ->
        # Permitir el host configurado
        origin_host == host or
        # Permitir cualquier subdominio de railway.app
        String.ends_with?(origin_host, ".railway.app") or
        String.ends_with?(origin_host, ".up.railway.app")
      _ ->
        false
    end
  end
  
  config :evaa_crm_web_gaepell, EvaaCrmWebGaepell.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    check_origin: check_origin_fn

  # Railway puede usar DATABASE_URL o DATABASE_PUBLIC_URL
  # DATABASE_URL usa conexión privada (puerto 5432)
  # DATABASE_PUBLIC_URL usa TCP proxy (puerto dinámico)
  database_url = System.get_env("DATABASE_URL") || System.get_env("DATABASE_PUBLIC_URL")

  if is_nil(database_url) do
    raise """
    environment variable DATABASE_URL is missing.
    Railway should provide this automatically when PostgreSQL is connected.
    For example: postgresql://USER:PASS@HOST:PORT/DATABASE
    """
  end

  # Normalizar la URL: Railway puede usar postgresql:// o postgres://
  # Ecto acepta ambos, pero normalizamos para consistencia
  normalized_url = 
    database_url
    |> String.replace(~r/^postgres:\/\//, "postgresql://")
    |> String.replace(~r/^ecto:\/\//, "postgresql://")

  pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :evaa_crm_gaepell, EvaaCrmGaepell.Repo,
    url: normalized_url,
    pool_size: pool_size,
    # Railway maneja SSL internamente, pero lo habilitamos por seguridad
    ssl: true,
    # Timeouts más largos para conexiones iniciales
    timeout: 15_000,
    connect_timeout: 10_000,
    # Configuración de queue para evitar errores de pool
    queue_target: 5_000,
    queue_interval: 1_000,
    # Deshabilitar migration lock para Railway
    migration_lock: nil
end