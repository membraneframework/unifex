defmodule Unifex.Logger do
  @moduledoc false

  use GenServer
  require Logger

  @valid_levels ~w(emergency alert critical error warning notice info debug)a

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  @spec handle_info({:unifex_logger, atom(), String.t(), integer(), list(atom())}, map()) ::
          {:noreply, map()}
  def handle_info({:unifex_logger, level, message, timestamp, tags}, state) do
    metadata = [tags: tags, unifex_nif: true, timestamp: timestamp]

    Logger.log(
      normalize_level(level),
      fn -> format_message(message, tags, timestamp) end,
      metadata
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unifex.Logger received unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  @doc false
  @spec normalize_level(atom()) :: atom()
  def normalize_level(level) when level in @valid_levels, do: level

  @doc false
  @spec normalize_level(any()) :: atom()
  def normalize_level(level) do
    Logger.warning(
      "Unifex.Logger received unknown log level #{inspect(level)}, defaulting to :info"
    )

    :info
  end

  @doc false
  @spec format_message(String.t(), list(atom()), integer()) :: String.t()
  def format_message(message, tags, timestamp) do
    tag_parts = Enum.map(tags, &"[#{&1}]")
    Enum.join(["[#{format_timestamp(timestamp)}]"] ++ tag_parts ++ [message], " ")
  end

  @doc false
  @spec format_timestamp(integer()) :: String.t()
  def format_timestamp(timestamp) do
    timestamp
    |> DateTime.from_unix!(:microsecond)
    |> DateTime.to_iso8601()
  end
end
