defmodule LoggerTestTest do
  use ExUnit.Case

  defmodule LogCollector do
    @moduledoc false
    @behaviour :logger_handler

    @impl :logger_handler
    def log(log_event, %{config: %{test_pid: pid}}) do
      send(pid, {:unifex_log_event, log_event})
    end
  end

  setup do
    handler_id = :"logger_test_collector_#{System.unique_integer([:positive])}"

    :ok =
      :logger.add_handler(handler_id, LogCollector, %{
        level: :debug,
        config: %{test_pid: self()}
      })

    on_exit(fn -> :logger.remove_handler(handler_id) end)

    :ok
  end

  defp message_text({:string, chardata}), do: IO.chardata_to_string(chardata)

  defp assert_logged(level, message_substring, tags_subset) do
    assert_receive {:unifex_log_event, %{level: ^level, msg: msg, meta: meta} = event}, 1000

    assert message_text(msg) =~ message_substring
    assert meta[:unifex_nif] == true
    assert Enum.all?(tags_subset, &(&1 in meta[:tags]))

    event
  end

  # Waits until no more `:unifex_log_event` messages arrive for `idle_timeout`.
  # Used after bursts so a test doesn't exit (and remove its handler) while
  # the native worker thread is still draining messages meant for it - those
  # stragglers would otherwise be picked up by whichever handler the next
  # test happens to install.
  defp drain_unifex_log_events(acc \\ [], idle_timeout \\ 500) do
    receive do
      {:unifex_log_event, event} -> drain_unifex_log_events([event | acc], idle_timeout)
    after
      idle_timeout -> Enum.reverse(acc)
    end
  end

  @tag :logger
  test "log_debug sends debug message" do
    assert {:ok} = LoggerTest.log_debug("Debug test message")
    assert_logged(:debug, "Debug test message", ["test", "debug"])
  end

  @tag :logger
  test "log_info sends info message" do
    assert {:ok} = LoggerTest.log_info("Info test message")
    assert_logged(:info, "Info test message", ["test", "info"])
  end

  @tag :logger
  test "log_warning sends warning message" do
    assert {:ok} = LoggerTest.log_warning("Warning test message")
    assert_logged(:warning, "Warning test message", ["test", "warning"])
  end

  @tag :logger
  test "log_error sends error message" do
    assert {:ok} = LoggerTest.log_error("Error test message")
    assert_logged(:error, "Error test message", ["test", "error"])
  end

  @tag :logger
  test "log_with_tags sends message with custom tags" do
    tags = ["custom1", "custom2"]
    assert {:ok} = LoggerTest.log_with_tags("Message with tags", tags)
    assert_logged(:info, "Message with tags", tags)
  end

  @tag :logger
  test "log_with_timestamp sends message" do
    timestamp = 1_700_000_000_000_000
    assert {:ok} = LoggerTest.log_with_timestamp("Timed message", timestamp)

    event = assert_logged(:info, "Timed message", ["test", "timestamp"])
    assert is_integer(event.meta[:timestamp])
  end

  @tag :logger
  test "log_many_messages handles bulk logging" do
    # Log a reasonable number of messages to test queue handling
    assert {:ok} = LoggerTest.log_many_messages(10)

    for i <- 0..9 do
      assert_logged(:info, "Message #{i}", ["test", "bulk"])
    end
  end

  @tag :logger
  test "test_queue_overflow handles queue overflow gracefully" do
    # This sends more messages than the queue can hold at once. Whether the
    # queue actually overflows depends on how fast the worker thread is
    # scheduled relative to the producer, so we don't assert on the drop
    # warning itself - only that logging keeps working and messages that do
    # get through are genuine log entries.
    assert {:ok} = LoggerTest.test_queue_overflow()

    # Drain everything the burst produces so the test doesn't return (and tear
    # down its handler) while messages are still in flight.
    events = drain_unifex_log_events()

    assert Enum.any?(events, fn %{level: level, msg: msg} ->
             level == :info and message_text(msg) =~ "Overflow test message"
           end)
  end
end
