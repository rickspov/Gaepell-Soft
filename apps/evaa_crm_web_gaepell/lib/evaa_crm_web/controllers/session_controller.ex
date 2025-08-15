defmodule EvaaCrmWebGaepell.SessionController do
  use EvaaCrmWebGaepell, :controller
  alias EvaaCrmGaepell.{Repo, User}
  alias Bcrypt
  import Plug.Conn
  import Ecto.Query

  def new(conn, _params) do
    current_user = get_session(conn, :user_id) && Repo.get(User, get_session(conn, :user_id))
    render(conn, "new.html", error: nil, current_user: current_user)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: email)
    if user && check_password(user, password) do
      conn
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> redirect(to: "/agenda")
    else
      render(conn, "new.html", error: "Email o contraseña incorrectos", current_user: nil)
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/login")
  end

  defp check_password(user, password) do
    Bcrypt.verify_pass(password, user.password_hash)
  end
end 