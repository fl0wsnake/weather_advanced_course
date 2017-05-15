defmodule AdvancedProject.Weather.OpenweathermapFetcher do
    def fetch_and_reduce(config) do
        config = Map.merge(config, %{
            rain: 10
        })

        todays = fetch(config)
        todays_forecasts = elem(todays, 1)["list"]
        dt = todays_forecasts[0]["dt"]

        prev_forecasts = Mongo.find(:mongo, config.services.openweathermap.forecast_history_collection, %{}, 
        sort: [{"list.0.dt", -1}],
        limit: config.days - 1,
        skip: 1) 
        |> Enum.to_list
        |> Enum.map(fn x -> x["list"] end)
        |> Enum.filter(fn x -> dt - x[0]["dt"] <= (config.days - 1) * 86400 end)

        reduce_to_err_value(prev_forecasts, todays_forecasts[0], config)
    end

    def fetch(config) do
        last_forecast = Enum.to_list(
            Mongo.find(:mongo, config.services.openweathermap.forecast_history_collection, %{}, sort: [{"list.0.dt", -1}], limit: 1)
            )[0]
        
        last_dt = last_forecast["list"][0]["dt"]

        if Timex.from_unix(last_dt).day == Timex.today().day do
            
            {:already_done, last_forecast}
        else
            json = HTTPoison.get config.services.openweathermap.url
            todays_forecast = Poison.Parser.parse!(json)
            Mongo.insert_one(:mongo, config.services.openweathermap.forecast_history_collection, todays_forecast)

            {:ok, todays_forecast}
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