defmodule AdvancedProject.Weather.Weather do
    @enforce_keys [:dt, :temp, :humidity, :pressure, :wind, :clouds, :rain]
    defstruct [:dt, :temp, :humidity, :pressure, :wind, :clouds, :rain]
end