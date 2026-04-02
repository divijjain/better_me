defmodule BetterMeWeb.PageController do
  use BetterMeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
