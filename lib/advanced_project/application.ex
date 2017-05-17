defmodule AdvancedProject.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    mongo_config = [
        hostname: Application.get_env(:advanced_project, :db)[:hostname],
        port: Application.get_env(:advanced_project, :db)[:port],
        database: Application.get_env(:advanced_project, :db)[:database],
        username: Application.get_env(:advanced_project, :db)[:username],
        password: Application.get_env(:advanced_project, :db)[:password],
        name: :mongo
        ]

    children = [
      worker(Mongo, [mongo_config]),
      supervisor(AdvancedProject.Web.Endpoint, []),
      worker(AdvancedProject.Weather.Fetcher, []),
      worker(AdvancedProject.Weather.Cache, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdvancedProject.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
