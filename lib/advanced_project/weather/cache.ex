defmodule AdvancedProject.Weather.Cache do
    use GenServer
    alias AdvancedProject.Weather.Weather
    import Weather, only: [cfg: 1]

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
    @spec init(%{}) :: {:ok, %{
        services: %{
            required(Atom) => %{
                deviations: [{Int, Float}],
                last_forecast: [%Weather{}],
                total_deviation: Float
            }
        },
        final_forecast: [%Weather{}]
    }}
    def init(state) do

        state = put_in(state[:services], cfg(:services)
        |> Enum.reduce(%{}, fn {service_name, service}, acc ->
            last_forecasts = service.weather.get_last_forecasts(
                cfg(:total_deviation_devs) + cfg(:daily_deviation_devs) - 1
            )

            deviation_list = Weather.get_deviation_list(last_forecasts)
            total_deviation = Weather.get_total_deviation(deviation_list)

            Map.put(acc, service_name, %{
                last_forecast: List.first(last_forecasts),
                deviations: deviation_list,
                total_deviation: total_deviation
            })
        end))

        state = update_final_forecast(state)

        {:ok, state}
    end

    def handle_cast({:put, service_name, forecast, dt_and_deviation}, state) do
        deviation_list = [dt_and_deviation | state[:services][service_name][:deviations]]
        total_deviation = Weather.get_total_deviation(deviation_list)

        state = put_in(state[:services][service_name], %{
            last_forecast: forecast,
            deviations: deviation_list,
            total_deviation: total_deviation
        })

        state = update_final_forecast(state)

        {:noreply, state}
    end

    def put(service, forecast, dt_and_deviation) do
        GenServer.cast(:cache, {:put, service, forecast, dt_and_deviation})
    end

    def update_final_forecast(state) do
        final_forecast = Weather.get_final_forecast(
            state[:services] |> Enum.map(fn {_, v} ->
                {v[:last_forecast], v[:total_deviation]}
            end)
        )

        put_in(state[:final_forecast], final_forecast)
    end


    def handle_call(:get, _from, state) do
      {:reply, state, state}
    end

    def get do
        GenServer.call(:cache, :get)
    end
end
