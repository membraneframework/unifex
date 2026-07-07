defmodule LoggerTestTest do
  use ExUnit.Case

  @tag :logger
  test "log_debug sends debug message" do
    assert {:ok} = LoggerTest.log_debug("Debug test message")
  end

  @tag :logger
  test "log_info sends info message" do
    assert {:ok} = LoggerTest.log_info("Info test message")
  end

  @tag :logger
  test "log_warning sends warning message" do
    assert {:ok} = LoggerTest.log_warning("Warning test message")
  end

  @tag :logger
  test "log_error sends error message" do
    assert {:ok} = LoggerTest.log_error("Error test message")
  end

  @tag :logger
  test "log_with_tags sends message with custom tags" do
    tags = ["custom1", "custom2"]
    assert {:ok} = LoggerTest.log_with_tags("Message with tags", tags)
  end

  @tag :logger
  test "log_with_timestamp sends message" do
    timestamp = 1700000000000000
    assert {:ok} = LoggerTest.log_with_timestamp("Timed message", timestamp)
  end

  @tag :logger
  test "log_many_messages handles bulk logging" do
    # Log a reasonable number of messages to test queue handling
    assert {:ok} = LoggerTest.log_many_messages(10)
  end

  @tag :logger
  test "test_queue_overflow handles queue overflow gracefully" do
    # This tests that the logger can handle more messages than the queue size
    # It should trigger overflow warnings but not crash
    assert {:ok} = LoggerTest.test_queue_overflow()
  end


end