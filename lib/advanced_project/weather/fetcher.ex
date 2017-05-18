defmodule AdvancedProject.Weather.Fetcher do
    alias AdvancedProject.Weather.{Weather, Cache}

    def do_all_fetching() do
        IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetching..."

        cfg(:services) |> Enum.each(fn {service_name, service} ->
            response = fetch(service.url)

            forecast = service.weather.of(response)
            actual = hd(forecast)

            prev_forecasts = service.weather.get_last_forecasts(cfg(:days_in_deviation) - 1)
            |> Enum.filter(fn fc -> actual.dt - hd(fc).dt <= (cfg(:days_in_deviation) - 1) * 86400 end)


            deviation = get_reduced_deviation(prev_forecasts, actual)
            Cache.put(service_name, actual, {actual.dt, deviation})

            service.weather.save(response)
        end)

        IO.puts (Tmex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetched successfully."
    end

    def fetch(url) do
        json = HTTPoison.get url
        Poison.Parser.parse!(json)
    end

    @spec get_reduced_deviation([[Weather]], Weather) :: Float
    def get_reduced_deviation(prev_forecasts, actual) do
        q = prev_forecasts |> Enum.reduce(0, fn(fc, acc) ->
            days_before = (actual.dt - hd(fc).dt) / 86400
            acc + :math.pow(cfg(:q), days_before)
        end)

        if q == 0 do
          9000000000
        else
            b = cfg(:series_sum) / q
            prev_forecasts |> Enum.reduce(0, fn(fc, acc) ->
                days_before = (actual.dt - hd(fc).dt) / 86400
                acc + b * :math.pow(cfg(:q), days_before) * get_deviation(Enum.at(fc, days_before), actual)
            end)
        end
    end

    @spec get_deviation(Weather, Weather) :: Float
     def get_deviation(forecast, actual) do
         abs(actual.temp - forecast.temp) * cfg(:temp) +
         abs(actual.humidity - forecast.humidity) * cfg(:humidity) +
         abs(actual.pressure - forecast.pressure) * cfg(:pressure) +
         abs(actual.wind - forecast.wind) * cfg(:wind_mph) +
         abs(actual.clouds - forecast.clouds) * cfg(:clouds) +
         abs(actual.rain - forecast.rain) * cfg(:rain)
     end

#     def fill_devaition_list() do
#         forecasts = Mongo.find(:mongo, @forecast_history_collection, %{},
#             sort: [{"list.0.dt", -1}],
#             projection: "list",
#             limit: cfg(:deviations_in_sum) + cfg(:days_in_deviation) - 1)
#             |> Enum.to_list
#
#         for i <- 0..cfg(:deviations_in_sum) + cfg(:days_in_deviation) - 3,
#         [x | xs] <- [Enum.slice(forecasts, i..i + cfg(:days_in_deviation))],
#         do: {x[0].dt, get_reduced_deviation(xs, x[0])}
#     end

    def cfg(a), do: (Application.get_env(__MODULE__, a))
end