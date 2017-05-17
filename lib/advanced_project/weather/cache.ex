defmodule AdvancedProject.Weather.Cache do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, %{})
    end

    @doc """
        state looks like this:

        %{
            services: %{
                some_service: %{
                    deviations: [{dt, deviation}, {dt, deviation}],
                    last_forecast: %Weather{},
                    total_deviation: Float
                    }, 
                another_service: ...
            },
            final_forecast: %Weather{}
        } 
    """
    def init(state) do
        cfg(:services) 
        |> Enum.each(fn {k, v} -> 
            # state = Map.put(state, k, v.fetch_module.fill_devaition_list())

            {last_forecast, deviation_list} = v.fetch_module.fill_devaition_list()

            total_deviation = # ...

            state = put_in(state[:services][k][:deviations], deviation_list)
        end)

        {:ok, state}
    end

    # def handle_call({:lookup, name}, _from, names) do
    #     {:reply, Map.fetch(names, name), names}
    # end

    def handle_cast({:put, service, dt_and_deviation}, state) do
        deviation_list = state[service]

        {:noreply, Map.put(state, service, [dt_and_deviation | deviation_list])}
    end

    def handle_cast() do
        
    end

    def cfg(a), do: (Application.get_env(__MODULE__, a)
end