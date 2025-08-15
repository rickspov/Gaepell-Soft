defmodule EvaaCrmWebGaepell.AuthPlug do
  import Plug.Conn
  alias EvaaCrmGaepell.{Repo, User}

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = if user_id, do: Repo.get(User, user_id), else: nil
    if user do
      assign(conn, :current_user, user)
    else
      conn
      |> Phoenix.Controller.redirect(to: "/login")
      |> halt()
    end
  end
end 