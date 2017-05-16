defmodule AdvancedProject.Weather.OpenweathermapFetcher do
    @forecast_history_collection "openweathermap_collection"
    # @forecast_deviation_collection "openweathermap_deviations"

    def fetch_and_reduce(config) do
        todays = fetch(config.services.openweathermap.url)
        todays_forecasts = todays["list"]
        dt = todays_forecasts[0]["dt"]

        prev_forecasts = Mongo.find(:mongo, @forecast_history_collection, %{}, 
        sort: [{"list.0.dt", -1}],
        limit: config.days_in_deviation - 1,
        projection: "list") 
        |> Enum.to_list
        # |> Enum.map(fn x -> x["list"] end)
        |> Enum.filter(fn x -> dt - x[0]["dt"] <= (config.days_in_deviation - 1) * 86400 end)

        Mongo.insert_one(:mongo, @forecast_history_collection, todays_forecasts)

        get_reduced_deviation(prev_forecasts, todays_forecasts[0], config)
    end

    def fetch(url) do
        json = HTTPoison.get url
        todays_forecast = Poison.Parser.parse!(json)

        todays_forecast
    end

    def get_reduced_deviation(prev_forecasts, actual, config) do
        q = prev_forecasts |> Enum.reduce(0, fn(it, acc) -> 
                days_before = (actual["dt"] - it[0]["dt"]) / 86400
                acc + config.q |> :math.pow(days_before) 
            end)

        b = config.sum / q

        prev_forecasts |> Enum.reduce(0, fn(it, acc) -> 
            days_before = (actual["dt"] - it[0]["dt"]) / 86400
            :math.pow(acc + b * config.q, days_before) * get_deviation(it[days_before], actual, config.coeffs)
        end)
    end

    def get_deviation(forecast, actual, coeffs) do
        abs(mean(actual["temp"]) - mean(forecast["temp"])) * coeffs.temp +
        abs(actual["humidity"] - forecast["humidity"]) * coeffs.humidity +
        abs(actual["pressure"] - forecast["pressure"]) * coeffs.pressure +
        abs(actual["speed"] - forecast["speed"]) * coeffs.wind_mph +
        abs(actual["clouds"] - forecast["clouds"]) * coeffs.clouds +
        abs(actual["rain"] - forecast["rain"]) * coeffs.rain
    end

    def mean(temp), do: (temp["morn"] + temp["day"] + temp["eve"] + temp["night"]) / 4

    # def cache_deviation(deviation) do
    #     Mongo.insert_one!(:mongo, @forecast_deviation_collection, %{"deviation" => deviation})
    # end

    def fill_devaition_list(config) do
        forecasts = Mongo.find(:mongo, config.forecast_history_collection, %{}, 
            sort: [{"list.0.dt", -1}],
            projection: "list",
            limit: config.deviations_in_sum + config.days_in_deviation - 1) 
            |> Enum.to_list
        
    end
end