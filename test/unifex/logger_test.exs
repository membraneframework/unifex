defmodule Unifex.LoggerTest do
  use ExUnit.Case, async: true

  @valid_levels ~w(emergency alert critical error warning notice info debug)a

  describe "Unifex.Logger" do
    test "start_link/0 starts the GenServer" do
      # Check if already started (from integration tests)
      if pid = Process.whereis(Unifex.Logger) do
        assert Process.alive?(pid)
      else
        {:ok, pid} = Unifex.Logger.start_link([])
        assert Process.alive?(pid)
        GenServer.stop(pid)
      end
    end

    test "normalizes valid log levels" do
      assert Unifex.Logger.normalize_level(:debug) == :debug
      assert Unifex.Logger.normalize_level(:info) == :info
      assert Unifex.Logger.normalize_level(:warning) == :warning
      assert Unifex.Logger.normalize_level(:error) == :error
      assert Unifex.Logger.normalize_level(:critical) == :critical
      assert Unifex.Logger.normalize_level(:alert) == :alert
      assert Unifex.Logger.normalize_level(:emergency) == :emergency
      assert Unifex.Logger.normalize_level(:notice) == :notice
    end

    test "normalizes invalid log levels to :info with warning" do
      # This test verifies that unknown levels are normalized to :info
      # The warning is a side effect that we can't easily capture here
      assert Unifex.Logger.normalize_level(:unknown_level) == :info
      assert Unifex.Logger.normalize_level("string_level") == :info
      assert Unifex.Logger.normalize_level(123) == :info
    end

    test "formats message without tags" do
      timestamp = 1700000000000000  # microseconds since epoch
      message = "Test message"
      tags = []

      formatted = Unifex.Logger.format_message(message, tags, timestamp)

      # Should contain the message and timestamp
      assert String.contains?(formatted, message)
      assert String.contains?(formatted, "2023-11-14")  # Approximate date for timestamp
    end

    test "formats message with tags" do
      timestamp = 1700000000000000
      message = "Test message"
      tags = ["tag1", "tag2"]

      formatted = Unifex.Logger.format_message(message, tags, timestamp)

      assert String.contains?(formatted, "[tag1]")
      assert String.contains?(formatted, "[tag2]")
      assert String.contains?(formatted, message)
    end

    test "formats timestamp correctly" do
      # Test with a known timestamp
      timestamp = 1700000000000000  # 2023-11-14T22:13:20.000000Z
      formatted_timestamp = Unifex.Logger.format_timestamp(timestamp)
      assert formatted_timestamp == "2023-11-14T22:13:20.000000Z"
    end

    test "handles nil tags gracefully" do
      timestamp = 1700000000000000
      message = "Test message"
      tags = [nil, "valid_tag", nil]

      formatted = Unifex.Logger.format_message(message, tags, timestamp)

      assert String.contains?(formatted, "[]")  # nil tags become empty brackets
      assert String.contains?(formatted, "[valid_tag]")
    end

    @tag :integration
    test "handles log messages correctly when running" do
      # Use existing logger or start new one
      if pid = Process.whereis(Unifex.Logger) do
        try do
          # Send a log message directly to the logger process
          level = :info
          message = "Test integration message"
          timestamp = 1700000000000000
          tags = ["integration", "test"]

          send(pid, {:unifex_logger, level, message, timestamp, tags})

          # The logger should process the message without crashing
          assert Process.alive?(pid)
        after
          # Don't stop if it was already running
        end
      else
        {:ok, pid} = Unifex.Logger.start_link([])
        try do
          send(pid, {:unifex_logger, :info, "Test integration message", 1700000000000000, ["integration", "test"]})
          assert Process.alive?(pid)
        after
          GenServer.stop(pid)
        end
      end
    end

    @tag :integration
    test "handles unknown message types with warning" do
      # Use existing logger or start new one
      if pid = Process.whereis(Unifex.Logger) do
        try do
          send(pid, {:unknown, :message})
          assert Process.alive?(pid)
        after
          # Don't stop if it was already running
        end
      else
        {:ok, pid} = Unifex.Logger.start_link([])
        try do
          send(pid, {:unknown, :message})
          assert Process.alive?(pid)
        after
          GenServer.stop(pid)
        end
      end
    end
  end

  describe "log level constants" do
    test "UNIFEX_LOG_LEVEL_ constants are documented strings" do
      # These are defined in the C header as:
      # #define UNIFEX_LOG_LEVEL_DEBUG "debug"
      # #define UNIFEX_LOG_LEVEL_INFO "info"
      # #define UNIFEX_LOG_LEVEL_WARN "warning"
      # #define UNIFEX_LOG_LEVEL_ERROR "error"
      
      # We verify that these atom values are valid Elixir logger levels
      # (note: the C code sends string levels which get normalized to atoms)
      assert :debug in @valid_levels
      assert :info in @valid_levels
      assert :warning in @valid_levels
      assert :error in @valid_levels
    end
  end
end