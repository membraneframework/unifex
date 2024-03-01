defmodule Unifex.Counter do
  @moduledoc false
  use Agent

  @spec start_link(any) :: Agent.on_start()
  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  @spec get_and_increment() :: integer()
  def get_and_increment do
    Agent.get_and_update(__MODULE__, fn state -> {state, state + 1} end)
  end
end
