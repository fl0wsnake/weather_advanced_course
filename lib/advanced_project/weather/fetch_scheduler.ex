defmodule AdvancedProject.Weather.FetchScheduler do
  use GenServer, Timex
  
  def start_link do
    config = %{
      scheduled_time_utc: ~T[12:00:00],
      # cities: ~w(Kharkiv),
      services: %{
        openweathermap: %{
          url: "api.openweathermap.org/data/2.5/forecast/daily?APPID=d940bb0c241d25dacfac9456eae23e7a&id=706483&units=metric&cnt=10",
          fetch_module: OpenweathermapFetcher,
          forecast_history_collection: "openweathermap_forecasts",
          
        },
        # apixu: %{
        #   url: "http://api.apixu.com/v1/forecast.json?key=543e9179295647ddb97181714171105&q=Kharkiv&days=10",
        #   fetch_module: :"AdvancedProject.Weather.ApixuFetcher"
        # }
      },
      coeffs: %{
        temp: 20,
        humidity: 20,
        pressure: 20,
        wind_kph: 10,
        wind_mph: 16, 
        clouds: 30
      },
      # sum = b + bq + bq^2 + .. + bq^(days - 1)
      days: 10,
      q: 0.8,
      sum: 1024.0
    }

    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    Timex.now()
    |> get_time_until_next_fetch(config.scheduled_time_utc)
    |> schedule_fetch
    
    {:ok, config}
  end

  def handle_info(:fetch, config) do
    Timex.now()
    |> get_time_until_next_fetch(config.scheduled_time_utc)
    |> schedule_fetch

    do_fetch(config)

    {:noreply, config}
  end

  def do_fetch(config) do
    IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetching..."

    config.services |> Enum.each(fn {k, v} -> 
      error_value = v.fetch_module.fetch_and_reduce(config)
    end)

    IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetched successfully."
  end

  def get_time_until_next_fetch(time_from, scheduled_time) do    
    today_or_tomorrow = if time_from.hour - scheduled_time.hour < 0, do: 0, else: 1

    scheduled_time = time_from
      |> Timex.beginning_of_day
      |> Timex.shift(days: today_or_tomorrow, hours: scheduled_time.hour)

    Timex.diff(scheduled_time, time_from, :milliseconds)
  end

  def schedule_fetch(time_after) do
    Process.send_after(self(), :fetch, time_after)
  end
end