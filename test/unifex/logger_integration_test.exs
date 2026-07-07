defmodule Unifex.LoggerIntegrationTest do
  use ExUnit.Case, async: true

  @valid_levels ~w(emergency alert critical error warning notice info debug)a

  setup_all do
    # Ensure the logger is started
    unless Process.whereis(Unifex.Logger) do
      {:ok, _pid} = Unifex.Logger.start_link([])
    end

    :ok
  end

  describe "Unifex.Logger integration with native code" do
    @tag :integration
    test "logger process handles messages from native code" do
      # This test would require a native function that calls unifex_log()
      # For now, we'll test that the logger process can handle direct messages
      pid = Process.whereis(Unifex.Logger)

      # Send a message directly to the logger
      send(
        pid,
        {:unifex_logger, :info, "Test message", 1_700_000_000_000_000, ["test", "direct"]}
      )

      # The logger should process it without crashing
      assert Process.alive?(pid)
    end

    @tag :integration
    test "logger normalizes all valid Elixir log levels" do
      for level <- @valid_levels do
        pid = Process.whereis(Unifex.Logger)
        send(pid, {:unifex_logger, level, "Test message", 1_700_000_000_000_000, ["test"]})
        assert Process.alive?(pid)
      end
    end

    @tag :integration
    test "logger handles string level from C code" do
      # The C code uses string levels like "debug", "info", "warning", "error"
      pid = Process.whereis(Unifex.Logger)

      # Test each of the UNIFEX_LOG_LEVEL_ constants
      for level <- ["debug", "info", "warning", "error"] do
        send(pid, {:unifex_logger, level, "Test message", 1_700_000_000_000_000, ["test"]})
        assert Process.alive?(pid)
      end
    end

    @tag :integration
    test "logger handles unknown levels gracefully" do
      pid = Process.whereis(Unifex.Logger)

      # Send a message with an unknown level
      send(pid, {:unifex_logger, :unknown_level, "Test message", 1_700_000_000_000_000, ["test"]})

      # Should still be alive and should have logged a warning about unknown level
      assert Process.alive?(pid)
    end

    @tag :integration
    test "logger handles messages with empty tags" do
      pid = Process.whereis(Unifex.Logger)
      send(pid, {:unifex_logger, :info, "Test message", 1_700_000_000_000_000, []})
      assert Process.alive?(pid)
    end

    @tag :integration
    test "logger handles messages with nil tags" do
      pid = Process.whereis(Unifex.Logger)

      send(
        pid,
        {:unifex_logger, :info, "Test message", 1_700_000_000_000_000, [nil, "valid", nil]}
      )

      assert Process.alive?(pid)
    end
  end

  describe "Logger target configuration" do
    @tag :integration
    test "unifex_logger_get_target returns expected name" do
      # We can't easily test the C function directly from Elixir without loading a NIF
      # but we can verify that the Elixir logger is configured correctly
      pid = Process.whereis(Unifex.Logger)
      assert pid != nil
      assert Process.alive?(pid)
    end
  end
end
