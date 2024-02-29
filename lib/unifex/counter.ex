defmodule Counter do
  @moduledoc false
  use Agent

  @spec start_link(integer()) ::
          {:error, {:already_started, pid()}} | {:error, String.t()} | {:ok, pid()}
  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @spec get_value() :: integer()
  def get_value do
    Agent.update(__MODULE__, &(&1 + 1))
    Agent.get(__MODULE__, & &1)
  end
end
