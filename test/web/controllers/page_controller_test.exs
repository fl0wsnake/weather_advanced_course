defmodule AdvancedProject.Web.PageControllerTest do
  use AdvancedProject.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    # assert html_response(conn, 200) =~ "Welcome to Phoenix!"
    response(conn, 200)
  end
end
