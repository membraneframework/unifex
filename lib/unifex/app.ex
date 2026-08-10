defmodule Unifex.App do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [Unifex.Counter] ++ if(logger_enabled?(), do: [Unifex.Logger], else: [])
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  # The native logger queue/worker thread (see c_src/unifex/unifex/logger.c)
  # is compiled into every unifex consumer, but only projects that actually
  # call unifex_log() need this GenServer running to receive its messages.
  defp logger_enabled?, do: Application.get_env(:unifex, :enable_logger, false)
end
