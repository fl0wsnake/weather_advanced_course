defmodule AdvancedProject.Web.PageController do
  use AdvancedProject.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
