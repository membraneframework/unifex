defmodule ExampleTest do
  use ExUnit.Case

  test "init" do
    require Unifex.CNode
    assert {:ok, cnode} = Unifex.CNode.start_link(:example)

    test_init(cnode)
    test_unsigned_int(cnode)
    test_string(cnode)
    test_list(cnode)
    test_list_as_string(cnode)
    test_list_of_strings(cnode)
    test_payload(cnode)
    test_pid(cnode)
    test_example_message(cnode)

    test_undefined_function(cnode)
    test_wrong_arguments(cnode)
  end

  def test_init(cnode) do
    assert :ok = Unifex.CNode.call(cnode, :init)
  end

  def test_unsigned_int(cnode) do
    assert {:ok, 0} = Unifex.CNode.call(cnode, :test_uint, [0])
    assert {:ok, 5} = Unifex.CNode.call(cnode, :test_uint, [5])
  end

  def test_string(cnode) do
    big_test_string = 'unifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifex
    unifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifex
    unifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifex
    '
    assert {:ok, ''} = Unifex.CNode.call(cnode, :test_string, [''])
    assert {:ok, 'test_string'} = Unifex.CNode.call(cnode, :test_string, ['test_string'])
    assert {:ok, '-12345'} = Unifex.CNode.call(cnode, :test_string, ['-12345'])
    assert {:ok, '255'} = Unifex.CNode.call(cnode, :test_string, ['255'])
    assert {:ok, big_test_string} = Unifex.CNode.call(cnode, :test_string, [big_test_string])
  end

  def test_list_as_string(cnode) do
    0..253 |> Enum.each(fn x ->
      list = [x, x+1, x+2]
      assert {:ok, list} = Unifex.CNode.call(cnode, :test_list, [list])
    end)
    assert {:ok, [0, 0, 0]} = Unifex.CNode.call(cnode, :test_list, [[0, 0, 0]])
    assert {:ok, [127, 127, 127]} = Unifex.CNode.call(cnode, :test_list, [[127, 127, 127]])
    assert {:ok, [128, 128, 128]} = Unifex.CNode.call(cnode, :test_list, [[128, 128, 128]])
    assert {:ok, [255, 255, 255]} = Unifex.CNode.call(cnode, :test_list, [[255, 255, 255]])
  end

  def test_list(cnode) do
    assert {:ok, [-1, -1, -1]} = Unifex.CNode.call(cnode, :test_list, [[-1, -1, -1]])
    assert {:ok, [-10, -17, -28]} = Unifex.CNode.call(cnode, :test_list, [[-10, -17, -28]])
    assert {:ok, [355, 355, 355]} = Unifex.CNode.call(cnode, :test_list, [[355, 355, 355]])
    assert {:ok, [1254, 1636, 3643]} = Unifex.CNode.call(cnode, :test_list, [[1254, 1636, 3643]])
  end

  def test_list_of_strings(cnode) do
    assert {:ok, ['abc', 'def', 'ghi']} = Unifex.CNode.call(cnode, :test_list_of_strings, [['abc', 'def', 'ghi']])
  end

  def test_payload(cnode) do
    assert {:ok, <<2, 2, 3>>} = Unifex.CNode.call(cnode, :test_payload, [<<1, 2, 3>>])
  end

  def test_pid(cnode) do
    assert {:ok} = Unifex.CNode.call(cnode, :test_pid, [self()])
  end

  def test_example_message(cnode) do
    assert {:ok} = Unifex.CNode.call(cnode, :test_example_message)
    assert_receive {:example_msg, 23}
  end

  def test_undefined_function(cnode) do
    assert_raise RuntimeError, ~r/undefined.*function.*abc/i, fn ->
      Unifex.CNode.call(cnode, :abc)
    end
  end

  def test_wrong_arguments(cnode) do
    assert_raise RuntimeError, ~r/argument.*in_pid.*pid/i, fn ->
      Unifex.CNode.call(cnode, :test_pid, [:abc])
    end
  end
end
