defmodule AdvancedProject.Weather.OpenweathermapWeather do
    @forecast_history_collection "openweathermap_collection"
    alias AdvancedProject.Weather.Weather

    @doc """
        Maps forecast right out of json into [%Weather{}]
    """

    def of(forecast) do
        forecast["list"]
            |> Enum.map(fn b ->
                %Weather{
                    dt: b["dt"],
                    temp: mean(b["temp"]),
                    humidity: b["humidity"],
                    pressure: b["pressure"],
                    wind: b["speed"],
                    clouds: b["clouds"],
                    rain: if b["rain"], do: 1, else: 0
                }
            end)
    end

    def get_last_forecasts(count) do
      Mongo.find(:mongo, @forecast_history_collection, %{},
                           sort: [{"list.0.dt", -1}],
                           limit: count)
                           |> Enum.map(of)
                           |> Enum.to_list
    end

    def save(forecast) do
      Mongo.insert_one(:mongo, @forecast_history_collection, forecast)
    end

    def mean(temp), do: (temp["morn"] + temp["day"] + temp["eve"] + temp["night"]) / 4

    def cfg(a), do: (Application.get_env(__MODULE__, a))
end