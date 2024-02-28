defmodule Counter do
    use Agent

    def start_link(initial_value) do
      Agent.start_link(fn -> initial_value end, name: __MODULE__)
    end

    def get_value do
      Agent.update(__MODULE__, &(&1 + 1))
      Agent.get(__MODULE__, & &1)
    end
  end
