defmodule AdvancedProject.Weather.Cache do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, %{}, name: :cache)
    end

    @doc """
        state looks like this:

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
            last_forecasts = service.weather.get_last_forecasts(cfg(:deviations_in_sum) + cfg(:days_in_deviation) - 1)

            for i <- 0..cfg(:deviations_in_sum) + cfg(:days_in_deviation) - 3,
            [x | xs] <- [Enum.slice(forecasts, i..i + cfg(:days_in_deviation))],
            do: {x[0].dt, get_reduced_deviation(xs, x[0])}

            state = put_in(state[:services][k][:deviations], deviation_list)
        end)

        {:ok, state}
    end

    # def handle_call({:lookup, name}, _from, names) do
    #     {:reply, Map.fetch(names, name), names}
    # end

    def handle_cast({:put, service, forecast, dt_and_deviation}, state) do
        deviation_list = state[:services][service][:deviations]

        state = put_in(state[:services][service][:last_forecast], forecast)
        state = put_in(state[:services][service][:deviations], [dt_and_deviation | deviation_list])

        {:noreply, state}
    end

    def put(service, forecast, dt_and_deviation) do
      GenServer.cast(:cache, {:put, service, dt_and_deviation})
    end

#    def handle_call({:get}, _from, state) do
#
#    end

    def cfg(a), do: (Application.get_env(__MODULE__, a))
end