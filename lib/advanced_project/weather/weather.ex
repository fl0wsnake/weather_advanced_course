defmodule AdvancedProject.Weather.Weather do
    @enforce_keys [:temp, :humidity, :pressure, :wind, :clouds, :rain]
    defstruct [:temp, :humidity, :pressure, :wind, :clouds, :rain]
end