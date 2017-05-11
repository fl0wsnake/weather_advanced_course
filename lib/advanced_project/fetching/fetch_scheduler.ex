defmodule AdvancedProject.FetchScheduler do
  use GenServer, Timex

  def scheduled_time_utc, do: ~T[12:00:00]

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Timex.now()
    |> get_time_until_next_fetch
    |> schedule_fetch
    
    {:ok, state}
  end

  def handle_info(:fetch, state) do
    Timex.now()
    |> get_time_until_next_fetch
    |> schedule_fetch

    do_fetch()

    {:noreply, state}
  end

  def do_fetch() do
    IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetching..."

    # TODO: actual fetch

    IO.puts (Timex.now() |> Timex.format("{ISO:Extended}") |> elem(1)) <> " Fetched successfully."
  end

  def get_time_until_next_fetch(time_from) do    
    today_or_tomorrow = if time_from.hour - scheduled_time_utc().hour < 0, do: 0, else: 1

    scheduled_time = time_from
      |> Timex.beginning_of_day
      |> Timex.shift(days: today_or_tomorrow, hours: scheduled_time_utc().hour)

    Timex.diff(scheduled_time, time_from, :milliseconds)
  end

  defp schedule_fetch(time_after) do
    Process.send_after(self(), :fetch, time_after)
  end
end