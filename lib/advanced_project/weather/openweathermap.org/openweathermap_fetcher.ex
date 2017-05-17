defmodule AdvancedProject.Weather.OpenweathermapFetcher do
    @forecast_history_collection "openweathermap_collection"

    def fetch_and_reduce() do
        todays = fetch(cfg(:services).openweathermap.url)
        todays_forecasts = todays["list"]

        todays_forecasts = Enum.map(todays_forecasts, fn it -> Map.put(it, "rain", (if it["rain"], do: 1, else: 0)) end)

        dt = todays_forecasts[0]["dt"]

        prev_forecasts = Mongo.find(:mongo, @forecast_history_collection, %{}, 
        sort: [{"list.0.dt", -1}],
        limit: cfg(:days_in_deviation) - 1,
        projection: "list") 
        |> Enum.to_list
        # |> Enum.map(fn x -> x["list"] end)
        |> Enum.filter(fn x -> dt - x[0]["dt"] <= (cfg(:days_in_deviation) - 1) * 86400 end)

        Mongo.insert_one(:mongo, @forecast_history_collection, todays_forecasts)

        get_reduced_deviation(prev_forecasts, todays_forecasts[0])
    end

    def fetch(url) do
        json = HTTPoison.get url
        todays_forecast = Poison.Parser.parse!(json)

        todays_forecast
    end

    def get_reduced_deviation(prev_forecasts, actual) do
        q = prev_forecasts |> Enum.reduce(0, fn(it, acc) -> 
                days_before = (actual["dt"] - it[0]["dt"]) / 86400
                acc + :math.pow(cfg(:q), days_before) 
            end)

        b = cfg(:series_sum) / q

        prev_forecasts |> Enum.reduce(0, fn(it, acc) -> 
            days_before = (actual["dt"] - it[0]["dt"]) / 86400
            :math.pow(acc + b * cfg(:q), days_before) * get_deviation(it[days_before], actual)
        end)
    end

    def get_deviation(forecast, actual) do
        abs(mean(actual["temp"]) - mean(forecast["temp"])) * cfg(:temp) +
        abs(actual["humidity"] - forecast["humidity"]) * cfg(:humidity) +
        abs(actual["pressure"] - forecast["pressure"]) * cfg(:pressure) +
        abs(actual["speed"] - forecast["speed"]) * cfg(:wind_mph) +
        abs(actual["clouds"] - forecast["clouds"]) * cfg(:clouds) +
        abs(actual["rain"] - forecast["rain"]) * cfg(:rain)
    end

    def mean(temp), do: (temp["morn"] + temp["day"] + temp["eve"] + temp["night"]) / 4

    def fill_devaition_list() do
        forecasts = Mongo.find(:mongo, @forecast_history_collection, %{}, 
            sort: [{"list.0.dt", -1}],
            projection: "list",
            limit: cfg(:deviations_in_sum) + cfg(:days_in_deviation) - 1) 
            |> Enum.to_list

        for i <- 0..cfg(:deviations_in_sum) + cfg(:days_in_deviation) - 3, 
        [x | xs] <- [Enum.slice(forecasts, i..i + cfg(:days_in_deviation))], 
        do: {x[0].dt, xget_reduced_deviation(xs, x[0])}    
    end

    def cfg(a), do: (Application.get_env(__MODULE__, a)
end