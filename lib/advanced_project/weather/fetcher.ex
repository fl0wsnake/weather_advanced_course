defmodule AdvancedProject.Weather.Fetcher do
    alias AdvancedProject.Weather.{Weather, Cache}

    def do_all_fetching() do
        IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetching..."

        cfg(:services) |> Enum.each(fn {service_name, service} ->
            response = fetch(service.url)

            forecast = service.weather.of(response)
            actual = hd(forecast)

            prev_forecasts = service.weather.get_last_forecasts(cfg(:daily_deviation_devs) - 1)
            |> Enum.filter(fn fc -> actual.dt - hd(fc).dt <= (cfg(:daily_deviation_devs) - 1) * 86400 end)


            deviation = Weather.get_reduced_deviation(prev_forecasts, actual)
            Cache.put(service_name, forecast, {actual.dt, deviation})

            service.weather.save(response)
        end)

        IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetched successfully."
    end

    def fetch(url) do
        json = HTTPoison.get url
        Poison.Parser.parse!(json)
    end

    def cfg(a), do: (Application.get_env(__MODULE__, a))
end