defmodule AdvancedProject.Weather.Weather do
    @enforce_keys [:dt, :temp, :humidity, :pressure, :wind, :clouds, :rain]
    defstruct [:dt, :temp, :humidity, :pressure, :wind, :clouds, :rain]

    @spec get_reduced_deviation([[Weather]], Weather) :: Float
    def get_reduced_deviation(prev_forecasts, actual) do
        qs = prev_forecasts |> Enum.reduce(0, fn(fc, acc) ->
            days_before = (actual.dt - hd(fc).dt) / 86400
            acc + :math.pow(cfg(:daily_deviation_q), days_before)
        end)

        if qs == 0 do
          9000000000
        else
            b = cfg(:daily_deviation_series) / qs
            prev_forecasts |> Enum.reduce(0, fn(fc, acc) ->
                days_before = (actual.dt - hd(fc).dt) / 86400
                acc +
                b *
                :math.pow(cfg(:daily_deviation_q), days_before) *
                get_deviation(Enum.at(fc, days_before), actual)
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

    @spec get_deviation_list([[Weather]]) :: [{Integer, Float}]
    def get_deviation_list(last_forecasts) do
        for i <- 0..cfg(:total_deviation_devs) + cfg(:daily_deviation_devs) - 3,
            [x | xs] <- [Enum.slice(forecasts, i..i + cfg(:daily_deviation_devs))],
            do: {
                x[0].dt,
                get_reduced_deviation(
                    xs |> Enum.filter(fn fc -> actual.dt - hd(fc).dt <= (cfg(:daily_deviation_devs) - 1) * 86400 end),
                    x[0]
                )
            }
    end

    @spec get_total_deviation([{Integer, Float}]) :: Float
    def get_total_deviation(deviation_list) do
        qs = deviation_list |> Enum.reduce(0, fn(dev, acc) ->
            days_before = (hd(deviation_list) |> elem(0) - dev |> elem(0)) / 86400
            acc + :math.pow(cfg(:total_deviation_q), days_before)
        end)

        if qs == 0 do
            9000000000
        else
            b = cfg(:total_deviation_series) / qs
            deviation_list |> Enum.reduce(0, fn(dev, acc) ->
                days_before = (hd(deviation_list) |> elem(0) - dev |> elem(0)) / 86400
                acc +
                b *
                dev |> elem(1)
                :math.pow(cfg(:total_deviation_q), days_before)
            end)
        end
    end

    @spec get_final_forecast([{[Weather], Float}]) :: [Weather]
    def get_final_forecast(forecasts_with_deviations) do
    starting_acc_fc = forecasts_with_deviations
    |> hd
    |> elem(0)
    |> Enum.map(fn w -> %Weather{dt: w.dt, temp: 0, humidity: 0, pressure: 0, wind: 0, clouds: 0, rain: 0} end)

    {fc_sum, dev_sum} = forecasts_with_deviations
    |> Enum.reduce({starting_acc_fc, 0}, fn {fc, dev}, {acc_fc, acc_dev} ->
        {acc_fc |> Enum.zip(fc |> Enum.map(fn w -> mul(w, 1/dev) end)) |> Enum.map(fn {w1, w2} -> plus(w1, w2) end), acc_dev + 1/dev}
    end)

    fc_sum |> Enum.map(fn w -> divide(w, dev_sum) end)
    end

    @spec plus(Weather, Weather) :: Weather
    def plus(w1, w2) do
        if w1.dt != w2.dt, do: raise "datetimes of summed weathers differ"
        %Weather{
            dt: w1.dt,
            temp: w1.temp + w2.temp,
            humidity: w1.humidity + w2.humidity,
            pressure: w1.pressure + w2.pressure,
            wind: w1.speed + w2.speed,
            clouds: w1.clouds + w2.clouds,
            rain: w1.rain + w2.rain
        }
    end

    @spec mul(Weather, Float) :: Weather
    def mul(w1, p) do
        %Weather{
            dt: w1.dt,
            temp: w1.temp * p,
            humidity: w1.humidity * p,
            pressure: w1.pressure * p,
            wind: w1.speed * p,
            clouds: w1.clouds * p,
            rain: w1.rain * p
        }
    end

    @spec divide(Weather, Float) :: Weather
    def divide(w1, p) do
        %Weather{
            dt: w1.dt,
            temp: w1.temp / p,
            humidity: w1.humidity / p,
            pressure: w1.pressure / p,
            wind: w1.speed / p,
            clouds: w1.clouds / p,
            rain: w1.rain / p
        }
    end

    def cfg(a), do: (Application.get_env(__MODULE__, a))
end