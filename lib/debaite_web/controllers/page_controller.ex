defmodule DebaiteWeb.PageController do
  use DebaiteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
