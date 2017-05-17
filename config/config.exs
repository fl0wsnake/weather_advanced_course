# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
# config :advanced_project,
#   ecto_repos: [:db]

# Configures the endpoint
config :advanced_project, AdvancedProject.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6maNqOLmVslQTb6cmRhztZqXra2UwN+MZGjplRrduFet1jTC9S5w7p0mmRpOqCbf",
  render_errors: [view: AdvancedProject.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AdvancedProject.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

cfg = [
  scheduled_time_utc: ~T[12:00:00],
  # cities: ~w(Kharkiv),
  services: %{
    openweathermap: %{
      url: "api.openweathermap.org/data/2.5/forecast/daily?APPID=d940bb0c241d25dacfac9456eae23e7a&id=706483&units=metric&cnt=10",
      weather: OpenweathermapWeather
    },
    # apixu: %{
    #   url: "http://api.apixu.com/v1/forecast.json?key=543e9179295647ddb97181714171105&q=Kharkiv&days=10",
    #   fetch_module: :"AdvancedProject.Weather.ApixuFetcher"
    # }
  },
  temp: 20,
  humidity: 20,
  pressure: 20,
  wind_kph: 10,
  wind_mph: 16, 
  clouds: 30,
  days_in_deviation: 10,
  deviations_in_sum: 30,
  q: 0.8,
  series_sum: 10.0,
  rain: 100
]

config AdvancedProject.Weather.FetchScheduler, cfg
config AdvancedProject.Weather.Cache, cfg
config AdvancedProject.Weather.Fetcher, cfg

#config AdvancedProject.Weather.OpenweathermapWeather, cfg
# config AdvancedProject.Weather.OpenweathermapFetcher, [
#   rain: 10
# ]


#config AdvancedProject.Weather.ApixuFetcher, cfg


