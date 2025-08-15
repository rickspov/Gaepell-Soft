defmodule EvaaCrmWebGaepell.UserHelper do
  alias EvaaCrmGaepell.{Repo, User}

  def get_current_user(conn) do
    user_id = Plug.Conn.get_session(conn, :user_id)
    if user_id, do: Repo.get(User, user_id), else: nil
  end

  def get_current_user_from_assigns(assigns) do
    assigns[:current_user]
  end
end 