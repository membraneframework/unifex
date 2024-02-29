defmodule Counter do
  @moduledoc false
  use Agent

  @spec start_link() ::
          {:error, {:already_started, pid()}} | {:error, String.t()} | {:ok, pid()}
  def start_link() do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  @spec get_and_increment() :: integer()
  def get_and_increment do
    Agent.get_and_update(__MODULE__, fn state -> {state, state + 1} end)
  end
end
