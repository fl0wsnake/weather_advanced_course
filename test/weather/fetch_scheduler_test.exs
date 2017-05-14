defmodule AdvancedProject.ScheduleTest do
  # use AdvancedProject.UnitCase
  use ExUnit.Case


  test "schedule next fetch" do
    import AdvancedProject.FetchScheduler
    
    now = Timex.now()
    
    ms_remaining = get_time_until_next_fetch(now)

    assert ms_remaining >= 0
    assert ms_remaining <= 1000 * 3600 * 24
    assert Timex.shift(now, milliseconds: ms_remaining).hour == scheduled_time_utc().hour
    assert Timex.shift(now, milliseconds: ms_remaining).minute == scheduled_time_utc().minute
    assert Timex.shift(now, milliseconds: ms_remaining).second == scheduled_time_utc().second
  end
end
