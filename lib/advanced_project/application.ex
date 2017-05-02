defmodule AdvancedProject.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      worker(Mongo, [[
        hostname: Application.get_env(:advanced_project, :db)[:hostname],
        port: Application.get_env(:advanced_project, :db)[:port],
        database: Application.get_env(:advanced_project, :db)[:database],
        username: Application.get_env(:advanced_project, :db)[:username],
        password: Application.get_env(:advanced_project, :db)[:password],
        name: :mongo
        ]]),
      # Start the endpoint when the application starts
      supervisor(AdvancedProject.Web.Endpoint, []),
      # Start your own worker by calling: AdvancedProject.Worker.start_link(arg1, arg2, arg3)
      # worker(AdvancedProject.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdvancedProject.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
