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

  config :evaa_crm_web_gaepell, EvaaCrmWebGaepell.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  database_url = System.get_env("DATABASE_URL")

  if is_nil(database_url) do
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """
  end

  pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :evaa_crm_gaepell, EvaaCrmGaepell.Repo,
    url: database_url,
    pool_size: pool_size,
    ssl: true
end