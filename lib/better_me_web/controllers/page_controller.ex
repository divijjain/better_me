defmodule BetterMeWeb.PageController do
  use BetterMeWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/habits")
    else
      render(conn, :home)
    end
  end
end
