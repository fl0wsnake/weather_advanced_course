defmodule AdvancedProject.Weather.OpenweathermapFetcher do
    def fetch(config) do
        config = Map.merge(config, %{
            rain: 10,
            forecast_history_collection: "openweathermap_forecasts"
        })

        json = HTTPoison.get config.services.openweathermap.url
        todays = Poison.Parser.parse!(json)
        todays_forecasts = todays["list"]
        dt = todays_forecasts[0]["dt"]

        if (Mongo.find(:mongo, config.forecast_history_collection, %{}, sort: [{"list.0.dt", -1}], limit: 1)
        |> Enum.to_list)[0]["list"][0]["dt"] == dt do
            {:already_done}
        else
            prev_forecasts = Mongo.find(:mongo, config.forecast_history_collection, %{}, sort: [{"list.0.dt", -1}], limit: config.days - 1) 
            |> Enum.to_list
            |> Enum.map(fn x -> x["list"] end)
            |> Enum.filter(fn x -> dt - x[0]["dt"] <= (config.days - 1) * 86400 end)

            v = reduce_to_err_value(prev_forecasts, todays_forecasts[0], config)

            Mongo.insert_one(:mongo, config.forecast_history_collection, todays)

            {:ok, v}
        end
    end

    def reduce_to_err_value(prev_forecasts, actual, config) do
        q = prev_forecasts |> Enum.reduce(0, fn(it, acc) -> 
                days_before = (actual["dt"] - it[0]["dt"]) / 86400
                acc + config.q |> :math.pow(days_before) 
            end)

        b = config.sum / q

        prev_forecasts |> Enum.reduce(0, fn(it, acc) -> 
            days_before = (actual["dt"] - it[0]["dt"]) / 86400
            :math.pow(acc + b * config.q, days_before) * get_err(it[days_before], actual, config.coeffs)
        end)
    end

    def get_err(forecast, actual, coeffs) do
        abs(mean(actual["temp"]) - mean(forecast["temp"])) * coeffs.temp +
        abs(actual["humidity"] - forecast["humidity"]) * coeffs.humidity +
        abs(actual["pressure"] - forecast["pressure"]) * coeffs.pressure +
        abs(actual["speed"] - forecast["speed"]) * coeffs.wind_mph +
        abs(actual["clouds"] - forecast["clouds"]) * coeffs.clouds +
        abs(actual["rain"] - forecast["rain"]) * coeffs.rain
    end

    def mean(temp), do: (temp["morn"] + temp["day"] + temp["eve"] + temp["night"]) / 4
end