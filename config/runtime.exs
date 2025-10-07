import Config

if System.get_env("PHX_SERVER") do
  config :evaa_crm_gaepell, EvaaCrmWebGaepell.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "example.com", port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  config :evaa_crm_gaepell, EvaaCrmGaepell.Repo,
    url: System.get_env("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end