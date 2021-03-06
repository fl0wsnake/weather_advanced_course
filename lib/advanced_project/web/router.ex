defmodule AdvancedProject.Web.Router do
  use AdvancedProject.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AdvancedProject.Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", AdvancedProject.Web do
    pipe_through :api

    get "/", ApiController, :data
  end
end
