defmodule AdvancedProject.Weather.Fetcher do
    alias AdvancedProject.Weather.{Weather, Cache}
    import Weather, only: [cfg: 1]

    def do_all_fetching() do
        IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetching..."

        cfg(:services) |> Enum.each(fn {service_name, service} ->
            response_body = fetch(service.url)

            forecast = service.weather.of(response_body)
            actual_weather = hd(forecast)

            prev_forecasts = service.weather.get_last_forecasts(cfg(:daily_deviation_devs) - 1)
            |> Enum.filter(fn fc -> actual_weather.dt - hd(fc).dt <= (cfg(:daily_deviation_devs) - 1) * 86400 end)


            deviation = Weather.get_reduced_deviation(prev_forecasts, actual_weather)
            Cache.put(service_name, forecast, {actual_weather.dt, deviation})

            service.weather.save(response_body)
        end)

        IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetched successfully."
    end

    def fetch(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get url
        {:ok, parsed} = Poison.Parser.parse(body)
        parsed
    end
end