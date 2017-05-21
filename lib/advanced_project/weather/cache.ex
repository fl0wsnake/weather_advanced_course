defmodule AdvancedProject.Weather.Cache do
    use GenServer
    alias AdvancedProject.Weather.Weather

    def start_link do
        GenServer.start_link(__MODULE__, %{
            services: %{},
            final_forecast: []
        }, name: :cache)
    end

    @doc """
        state basically looks like this:

        %{
            services: %{
                some_service: %{
                    deviations: [{dt, deviation}, {dt, deviation}],
                    last_forecast: [%Weather{}],
                    total_deviation: Float
                },
                another_service: ...
            },
            final_forecast: [%Weather{}]
        } 
    """
    def init(state) do

        cfg(:services)
        |> Enum.each(fn {service_name, service} ->
            last_forecasts = service.weather.get_last_forecasts(
                cfg(:total_deviation_devs) + cfg(:daily_deviation_devs) - 1
            )

            deviation_list = Weather.get_deviation_list(last_forecasts)
            total_deviation = Weather.get_total_deviation(deviation_list)

#            state = put_in(state[:services][service_name][:last_forecast], hd(last_forecasts))
#            state = put_in(state[:services][service_name][:deviations], deviation_list)
#            state = put_in(state[:services][service_name][:total_deviation], total_deviation)

            state = put_in(state[:services][service_name], %{
                last_forecast: hd(last_forecasts),
                deviations: deviation_list,
                total_deviation: total_deviation
            })
        end)

        final_forecast = Weather.get_final_forecast(
            state[:services] |> Enum.map(fn {k, v} ->
                {v[:last_forecast], v[:total_deviation]}
            end)
        )

        state = put_in(state[:final_forecast], final_forecast)

        {:ok, state}
    end

    def handle_cast({:put, service_name, forecast, dt_and_deviation}, state) do
        deviation_list = state[:services][service_name][:deviations]
        total_deviation = Weather.get_total_deviation(deviation_list)

        state = put_in(state[:services][service_name][:last_forecast], forecast)
        state = put_in(state[:services][service_name][:deviations], [dt_and_deviation | deviation_list])
        state = put_in(state[:services][service_name][:total_deviation], total_deviation)
        state = put_in(state[:final_forecast])

        {:noreply, state}
    end

    def put(service, forecast, dt_and_deviation) do
        GenServer.cast(:cache, {:put, service, forecast, dt_and_deviation})
    end

#    def handle_call({:lookup, name}, _from, names) do
#        {:reply, Map.fetch(names, name), names}
#    end

    def cfg(a), do: (Application.get_env(__MODULE__, a))
end