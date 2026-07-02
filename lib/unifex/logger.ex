defmodule Unifex.Logger do
  @moduledoc """
  Generic logger for handling log messages from C NIFs via Unifex.

  This process receives log messages from C code and forwards them to Elixir's Logger.
  It can be used by any NIF library that needs to log messages to the BEAM.
  """

  use GenServer
  require Logger

  @router_name :"Elixir.Unifex.Logger"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: @router_name)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_info({:unifex_logger, level, message, time, tags}, state) do
    metadata = [tags: tags, unifex_nif: true, timestamp: time]
    formatted_message = format_message(message, tags, time)
    Logger.log(level, formatted_message, metadata)
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unifex.Logger received unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp format_message(message, tags, time) do
    tags_str = Enum.map(tags, &"[#{&1}]") |> Enum.join(" ")
    "#{time} #{tags_str} #{message}"
  end
end
