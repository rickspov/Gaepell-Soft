defmodule EvaaCrmGaepell.Repo do
  use Ecto.Repo,
    otp_app: :evaa_crm_gaepell,
    adapter: Ecto.Adapters.Postgres
end
