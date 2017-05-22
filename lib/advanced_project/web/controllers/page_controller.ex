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
    |> json(Cache.get() |> deal_with_unencoded_tuples())
  end

  def deal_with_unencoded_tuples(state) do
    state |> Map.put(:services, state.services |> Enum.map(fn {_, service} -> 
      service |> Map.put(:deviations, service.deviations |> Enum.map(fn {dt, dev} -> 
        %{dt: dt, dev: dev}
      end))  
    end))
  end
end
