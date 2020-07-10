defmodule ExampleTest do
  use ExUnit.Case

  test "init" do
    assert {:ok, was_handle_load_called, state} = Example.init()
    assert was_handle_load_called == 1
    assert is_reference(state)
  end

  test "foo" do
    {:ok, _, state} = Example.init()
    assert {:ok, [1, 2, 3], 42} = Example.foo(self(), [1, 2, 3], state)
    assert_receive {:example_msg, 42}
  end
end
