defmodule AdvancedProject.Weather.FetchScheduler do
  use GenServer, Timex
  alias AdvancedProject.Weather.{Fetcher, Weather}
  import Weather, only: [cfg: 1]
  
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

    Fetcher.do_all_fetching()

    {:noreply, state}
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