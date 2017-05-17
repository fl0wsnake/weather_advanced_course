defmodule AdvancedProject.Weather.FetchScheduler do
  use GenServer, Timex
  
  def start_link do

    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do

    Timex.now()
    |> get_time_until_next_fetch(cfg(:scheduled_time_utc))
    |> schedule_fetch
    
    {:ok, state}
  end

  def handle_info(:fetch, state) do
    Timex.now()
    |> get_time_until_next_fetch(cfg(:scheduled_time_utc))
    |> schedule_fetch

    do_all_fetching()

    {:noreply, state}
  end

  def do_all_fetching() do
    IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetching..."

    cfg(:services) |> Enum.each(fn {k, v} -> 
      deviation = v.fetch_module.fetch_and_reduce()

      v.cache_deviation(deviation)
    end)

    IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetched successfully."
  end

  def get_time_until_next_fetch(time_from, scheduled_time) do    
    today_or_tomorrow = if time_from.hour - scheduled_time.hour < 0, do: 0, else: 1

    scheduled_time = time_from
      |> Timex.beginning_of_day
      |> Timex.shift(days: today_or_tomorrow, hours: scheduled_time.hour)

    Timex.diff(scheduled_time, time_from, :milliseconds)
  end

  def schedule_fetch(time_after) do
    Process.send_after(self(), :fetch, time_after)
  end
end