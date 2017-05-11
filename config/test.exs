use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :advanced_project, AdvancedProject.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
# config :advanced_project, AdvancedProject.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "advanced_project_test",
#   hostname: "localhost",
#   pool: Ecto.Adapters.SQL.Sandbox

config :advanced_project, :db,
  database: System.get_env("MONGODB_DATABASE"),
  username: System.get_env("MONGODB_USER"),
  password: System.get_env("MONGODB_PASS"),
  hostname: System.get_env("MONGODB_URL"),
  # database: "weatherdb",
  # username: "root",
  # password: "pass1234",
  # hostname: "localhost",
  port: 27017
