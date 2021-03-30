defmodule ExampleTest do
  use ExUnit.Case

  setup_all do
    assert {:ok, was_handle_load_called, state} = Example.init()
    assert was_handle_load_called == 1
    assert is_reference(state)
    [state: state]
  end

  test "atom" do
    assert {:ok, :unifex} = Example.test_atom(:unifex)
  end

  test "float" do
    assert {:ok, 0.0} = Example.test_float(0.0)
    assert {:ok, 0.1} = Example.test_float(0.1)
    assert {:ok, -0.1} = Example.test_float(-0.1)
    refute match?({:ok, 1}, Example.test_float(1.0))
  end

  test "int" do
    assert {:ok, 10} = Example.test_int(10)
  end

  test "list" do
    assert {:ok, [1, 2, 3]} = Example.test_list([1, 2, 3])
  end

  test "pid" do
    pid = self()
    assert {:ok, ^pid} = Example.test_pid(pid)
  end

  test "state", context do
    state = context[:state]
    assert {:ok, ^state} = Example.test_state(state)
  end

  test "example message" do
    assert {:ok} = Example.test_example_message(self())
    assert_receive {:example_msg, 10}
  end
end
