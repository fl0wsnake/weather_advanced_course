defmodule AdvancedProject.Web.PageController do
  use AdvancedProject.Web, :controller
  alias AdvancedProject.Weather.Cache

  def index(conn, _params) do
    conn 
    |> put_layout(false)
    |> render("index.html")
  end

  def data(conn, _params) do
    conn
    |> json(Cache.get())
  end
end
