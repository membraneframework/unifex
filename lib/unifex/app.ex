defmodule Unifex.App do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [Unifex.Counter]
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
