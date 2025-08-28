defmodule EvaaCrmWebGaepell.RedirectController do
  use EvaaCrmWebGaepell, :controller

  def to_evaluations_tab(conn, _params) do
    redirect(conn, to: "/tickets?tab=evaluation")
  end
end
