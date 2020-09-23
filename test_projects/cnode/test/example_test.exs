defmodule ExampleTest do
  use ExUnit.Case, async: true

  setup_all do
    require Unifex.CNode
    {:ok, cnode} = Unifex.CNode.start_link(:example)
    :ok = Unifex.CNode.call(cnode, :init)
    [cnode: cnode]
  end

  test "atom", context do
    assert {:ok, :unifex} = Unifex.CNode.call(context[:cnode], :test_atom, [:unifex])
  end

  test "bool", context do
    assert {:ok, true} = Unifex.CNode.call(context[:cnode], :test_bool, [true])
    assert {:ok, false} = Unifex.CNode.call(context[:cnode], :test_bool, [false])
    refute match?({:ok, false}, Unifex.CNode.call(context[:cnode], :test_bool, [true]))
  end

  test "float", context do
    assert {:ok, 0.0} = Unifex.CNode.call(context[:cnode], :test_float, [0.0])
    assert {:ok, 0.1} = Unifex.CNode.call(context[:cnode], :test_float, [0.1])
    assert {:ok, -0.1} = Unifex.CNode.call(context[:cnode], :test_float, [-0.1])
    refute match?({:ok, 1}, Unifex.CNode.call(context[:cnode], :test_float, [1.0]))
  end

  test "unsigned int", context do
    cnode = context[:cnode]
    assert {:ok, 0} = Unifex.CNode.call(cnode, :test_uint, [0])
    assert {:ok, 5} = Unifex.CNode.call(cnode, :test_uint, [5])

    assert_raise RuntimeError, ~r/argument.*in_uint.*unsigned/i, fn ->
      Unifex.CNode.call(cnode, :test_uint, [-1])
    end
  end

  test "string", context do
    cnode = context[:cnode]

    big_test_string =
      "unifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexu
      nifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexuni
      fexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifexunifex"

    assert {:ok, ""} = Unifex.CNode.call(cnode, :test_string, [""])
    assert {:ok, "test_string"} = Unifex.CNode.call(cnode, :test_string, ["test_string"])
    assert {:ok, "-12345"} = Unifex.CNode.call(cnode, :test_string, ["-12345"])
    assert {:ok, "255"} = Unifex.CNode.call(cnode, :test_string, ["255"])
    assert {:ok, big_test_string} = Unifex.CNode.call(cnode, :test_string, [big_test_string])
  end

  test "list as string", context do
    0..253
    |> Enum.each(fn x ->
      list = [x, x + 1, x + 2]
      assert {:ok, ^list} = Unifex.CNode.call(context[:cnode], :test_list, [list])
    end)
  end

  test "list", context do
    cnode = context[:cnode]
    assert {:ok, []} = Unifex.CNode.call(cnode, :test_list, [[]])
    assert {:ok, [-1, -1, -1]} = Unifex.CNode.call(cnode, :test_list, [[-1, -1, -1]])
    assert {:ok, [-10, -17, -28]} = Unifex.CNode.call(cnode, :test_list, [[-10, -17, -28]])
    assert {:ok, [355, 355, 355]} = Unifex.CNode.call(cnode, :test_list, [[355, 355, 355]])
    assert {:ok, [1254, 1636, 3643]} = Unifex.CNode.call(cnode, :test_list, [[1254, 1636, 3643]])
  end

  test "list of strings", context do
    cnode = context[:cnode]
    assert {:ok, []} = Unifex.CNode.call(cnode, :test_list_of_strings, [[]])

    assert {:ok, ["", "", ""]} = Unifex.CNode.call(cnode, :test_list_of_strings, [["", "", ""]])

    assert {:ok, ["1", "2", "3"]} =
             Unifex.CNode.call(cnode, :test_list_of_strings, [["1", "2", "3"]])

    assert {:ok, ["abc", "def", "ghi"]} =
             Unifex.CNode.call(cnode, :test_list_of_strings, [["abc", "def", "ghi"]])
  end

  test "list of unsigned ints", context do
    cnode = context[:cnode]
    assert {:ok, [0, 1, 2]} = Unifex.CNode.call(cnode, :test_list_of_uints, [[0, 1, 2]])
  end

  test "list with other arguments", context do
    cnode = context[:cnode]

    assert {:ok, [1, 2, 3], :other_arg} =
             Unifex.CNode.call(cnode, :test_list_with_other_args, [[1, 2, 3], :other_arg])

    assert {:ok, [300, 400, 500], :other_arg} =
             Unifex.CNode.call(cnode, :test_list_with_other_args, [[300, 400, 500], :other_arg])
  end

  test "payload", context do
    assert {:ok, <<2, 2, 3>>} = Unifex.CNode.call(context[:cnode], :test_payload, [<<1, 2, 3>>])
  end

  test "pid", context do
    pid = self()
    assert {:ok, ^pid} = Unifex.CNode.call(context[:cnode], :test_pid, [pid])
  end

  test "example message", context do
    assert {:ok} = Unifex.CNode.call(context[:cnode], :test_example_message)
    assert_receive {:example_msg, 23}
  end

  test "undefined function", context do
    assert_raise RuntimeError, ~r/undefined.*function.*abc/i, fn ->
      Unifex.CNode.call(context[:cnode], :abc)
    end
  end

  test "wrong arguments", context do
    assert_raise RuntimeError, ~r/argument.*in_pid.*pid/i, fn ->
      Unifex.CNode.call(context[:cnode], :test_pid, [:abc])
    end
  end
end
